import 'dart:convert';
import 'dart:math';
import 'package:maki_app/database/database.dart';

class LintsBanditService {
  final AppDatabase _db;
  final Random _random = Random();

  LintsBanditService(this._db);

  /// 3 Arms mapping to hour periods
  static const List<String> arms = ['morning', 'afternoon', 'evening'];

  /// Maps arm ID to hour value
  static int getArmHour(String arm) {
    switch (arm) {
      case 'morning':
        return 9;
      case 'afternoon':
        return 14;
      case 'evening':
        return 20;
      default:
        return 9;
    }
  }

  /// Helper to invert a 2x2 matrix
  List<List<double>> _invert2x2(List<List<double>> m) {
    final double det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    if (det.abs() < 1e-9) {
      // Return a standard identity fallback
      return [
        [1.0, 0.0],
        [0.0, 1.0]
      ];
    }
    final double invDet = 1.0 / det;
    return [
      [m[1][1] * invDet, -m[0][1] * invDet],
      [-m[1][0] * invDet, m[0][0] * invDet]
    ];
  }

  /// Helper to compute Cholesky decomposition L of 2x2 positive definite matrix S
  /// S = L * L^T where L is lower-triangular.
  List<List<double>> _cholesky2x2(List<List<double>> s) {
    final double l00 = sqrt(max(1e-9, s[0][0]));
    final double l10 = s[1][0] / l00;
    final double l11 = sqrt(max(1e-9, s[1][1] - l10 * l10));
    return [
      [l00, 0.0],
      [l10, l11]
    ];
  }

  /// Box-Muller Transform to draw a standard Gaussian N(0, 1) variable
  double _drawStandardNormal() {
    double u1, u2;
    do {
      u1 = _random.nextDouble();
    } while (u1 <= 0.0); // log(0) is undefined
    u2 = _random.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }

  /// Gets context vector x = [1.0, isWeekend ? 1.0 : 0.0]
  List<double> getContext(DateTime date) {
    final bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    return [1.0, isWeekend ? 1.0 : 0.0];
  }

  /// Fetches or initializes parameters for all arms from database
  Future<Map<String, BanditArmParams>> _loadOrInitializeParams() async {
    final list = await _db.getBanditStates();
    final Map<String, BanditArmParams> params = {};

    for (final arm in arms) {
      final match = list.firstWhere(
        (s) => s.arm == arm,
        orElse: () => NotificationBanditState(
          arm: arm,
          precisionMatrixJson: '[[1.0, 0.0], [0.0, 1.0]]',
          projectionVectorJson: '[0.0, 0.0]',
        ),
      );

      // Parse JSON arrays
      final aList = List<dynamic>.from(json.decode(match.precisionMatrixJson));
      final bList = List<dynamic>.from(json.decode(match.projectionVectorJson));

      final List<List<double>> A = [
        <double>[aList[0][0].toDouble(), aList[0][1].toDouble()],
        <double>[aList[1][0].toDouble(), aList[1][1].toDouble()],
      ];
      final List<double> b = <double>[bList[0].toDouble(), bList[1].toDouble()];

      params[arm] = BanditArmParams(A: A, b: b);
    }

    return params;
  }

  /// Saves parameters of an arm back to Drift database
  Future<void> _saveParams(String arm, BanditArmParams p) async {
    await _db.insertBanditState(
      NotificationBanditState(
        arm: arm,
        precisionMatrixJson: json.encode(p.A),
        projectionVectorJson: json.encode(p.b),
      ),
    );
  }

  /// Runs contextual Linear Thompson Sampling.
  /// Returns the recommended optimal hour (e.g. 9, 14, 20).
  Future<int> predictOptimalHour(DateTime date) async {
    final x = getContext(date);
    final armParams = await _loadOrInitializeParams();

    String? bestArm;
    double maxSampledValue = -double.infinity;

    const double vValue = 0.5; // Exploration noise factor (prior variance scale)

    for (final arm in arms) {
      final p = armParams[arm]!;

      // 1. Compute Covariance = A^-1
      final cov = _invert2x2(p.A);

      // 2. Compute Mean = A^-1 * b
      final double mu0 = cov[0][0] * p.b[0] + cov[0][1] * p.b[1];
      final double mu1 = cov[1][0] * p.b[0] + cov[1][1] * p.b[1];

      // Scale Covariance by exploration factor v^2
      final scaledCov = [
        [cov[0][0] * vValue * vValue, cov[0][1] * vValue * vValue],
        [cov[1][0] * vValue * vValue, cov[1][1] * vValue * vValue]
      ];

      // 3. Sample theta ~ N(mean, scaledCov) using Cholesky factor L
      final L = _cholesky2x2(scaledCov);
      final z0 = _drawStandardNormal();
      final z1 = _drawStandardNormal();

      final double thetaSample0 = mu0 + L[0][0] * z0;
      final double thetaSample1 = mu1 + L[1][0] * z0 + L[1][1] * z1;

      // 4. Predict expected reward = x^T * thetaSample
      final double score = x[0] * thetaSample0 + x[1] * thetaSample1;

      if (score > maxSampledValue) {
        maxSampledValue = score;
        bestArm = arm;
      }
    }

    return getArmHour(bestArm ?? 'morning');
  }

  /// Updates the LinTS model parameters for the selected arm with observed reward.
  /// [reward] must be 1.0 (opened notification) or 0.0 (ignored).
  Future<void> updateFeedback(String arm, DateTime date, double reward) async {
    if (!arms.contains(arm)) return;

    final x = getContext(date);
    final armParams = await _loadOrInitializeParams();
    final p = armParams[arm]!;

    // 1. Update A = A + x * x^T
    p.A[0][0] += x[0] * x[0];
    p.A[0][1] += x[0] * x[1];
    p.A[1][0] += x[1] * x[0];
    p.A[1][1] += x[1] * x[1];

    // 2. Update b = b + r * x
    p.b[0] += reward * x[0];
    p.b[1] += reward * x[1];

    await _saveParams(arm, p);
  }
}

class BanditArmParams {
  final List<List<double>> A;
  final List<double> b;

  BanditArmParams({required this.A, required this.b});
}
