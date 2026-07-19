import 'dart:convert';
import 'dart:math';
import 'package:maki_app/database/database.dart';

class LintsBanditService {
  final AppDatabase _db;
  final Random _random = Random();

  LintsBanditService(this._db);

  static const List<String> arms = ['morning', 'afternoon', 'evening'];

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

  List<List<double>> _invert2x2(List<List<double>> m) {
    final double det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    if (det.abs() < 1e-9) {
      return [
        [1.0, 0.0],
        [0.0, 1.0],
      ];
    }
    final double invDet = 1.0 / det;
    return [
      [m[1][1] * invDet, -m[0][1] * invDet],
      [-m[1][0] * invDet, m[0][0] * invDet],
    ];
  }

  List<List<double>> _cholesky2x2(List<List<double>> s) {
    final double l00 = sqrt(max(1e-9, s[0][0]));
    final double l10 = s[1][0] / l00;
    final double l11 = sqrt(max(1e-9, s[1][1] - l10 * l10));
    return [
      [l00, 0.0],
      [l10, l11],
    ];
  }

  double _drawStandardNormal() {
    double u1, u2;
    do {
      u1 = _random.nextDouble();
    } while (u1 <= 0.0); // Sıfırın logaritması tanımsızdır.
    u2 = _random.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }

  List<double> getContext(DateTime date) {
    final bool isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    return [1.0, isWeekend ? 1.0 : 0.0];
  }

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

      params[arm] = BanditArmParams.fromJson(
        precisionMatrixJson: match.precisionMatrixJson,
        projectionVectorJson: match.projectionVectorJson,
      );
    }

    return params;
  }

  Future<void> _saveParams(String arm, BanditArmParams p) async {
    await _db.insertBanditState(
      NotificationBanditState(
        arm: arm,
        precisionMatrixJson: json.encode(p.A),
        projectionVectorJson: json.encode(p.b),
      ),
    );
  }

  Future<int> predictOptimalHour(DateTime date) async {
    final x = getContext(date);
    final armParams = await _loadOrInitializeParams();

    String? bestArm;
    double maxSampledValue = -double.infinity;

    const double vValue = 0.5; // Keşif gürültüsü katsayısı.

    for (final arm in arms) {
      final p = armParams[arm]!;

      final cov = _invert2x2(p.A);

      final double mu0 = cov[0][0] * p.b[0] + cov[0][1] * p.b[1];
      final double mu1 = cov[1][0] * p.b[0] + cov[1][1] * p.b[1];

      final scaledCov = [
        [cov[0][0] * vValue * vValue, cov[0][1] * vValue * vValue],
        [cov[1][0] * vValue * vValue, cov[1][1] * vValue * vValue],
      ];

      final L = _cholesky2x2(scaledCov);
      final z0 = _drawStandardNormal();
      final z1 = _drawStandardNormal();

      final double thetaSample0 = mu0 + L[0][0] * z0;
      final double thetaSample1 = mu1 + L[1][0] * z0 + L[1][1] * z1;

      final double score = x[0] * thetaSample0 + x[1] * thetaSample1;

      if (score > maxSampledValue) {
        maxSampledValue = score;
        bestArm = arm;
      }
    }

    return getArmHour(bestArm ?? 'morning');
  }

  Future<void> updateFeedback(String arm, DateTime date, double reward) async {
    if (!arms.contains(arm)) return;

    final x = getContext(date);
    final armParams = await _loadOrInitializeParams();
    final p = armParams[arm]!;

    p.A[0][0] += x[0] * x[0];
    p.A[0][1] += x[0] * x[1];
    p.A[1][0] += x[1] * x[0];
    p.A[1][1] += x[1] * x[1];

    p.b[0] += reward * x[0];
    p.b[1] += reward * x[1];

    await _saveParams(arm, p);
  }
}

class BanditArmParams {
  final List<List<double>> A;
  final List<double> b;

  BanditArmParams({required this.A, required this.b});

  factory BanditArmParams.fromJson({
    required String precisionMatrixJson,
    required String projectionVectorJson,
  }) {
    final matrix = jsonDecode(precisionMatrixJson);
    final vector = jsonDecode(projectionVectorJson);
    if (matrix is! List<Object?> ||
        matrix.length != 2 ||
        matrix[0] is! List<Object?> ||
        matrix[1] is! List<Object?> ||
        vector is! List<Object?> ||
        vector.length != 2) {
      throw const FormatException('Bandit parametre boyutları geçersiz.');
    }
    final firstRow = matrix[0]! as List<Object?>;
    final secondRow = matrix[1]! as List<Object?>;
    if (firstRow.length != 2 || secondRow.length != 2) {
      throw const FormatException('Bandit matrisi 2x2 olmalıdır.');
    }
    return BanditArmParams(
      A: [
        [_finiteNumber(firstRow[0]), _finiteNumber(firstRow[1])],
        [_finiteNumber(secondRow[0]), _finiteNumber(secondRow[1])],
      ],
      b: [_finiteNumber(vector[0]), _finiteNumber(vector[1])],
    );
  }
}

double _finiteNumber(Object? value) {
  if (value is! num || !value.isFinite) {
    throw const FormatException('Bandit parametresi sonlu sayı olmalıdır.');
  }
  return value.toDouble();
}
