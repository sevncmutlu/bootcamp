import 'cholesky.dart';
import 'decision.dart';
import 'lints_state.dart';
import 'vector.dart';

/// Standart normal örnek kaynağı.
abstract interface class GaussianSource {
  double next();
}

/// Karar zamanını sağlayan saat.
abstract interface class Clock {
  DateTime now();
}

/// Bağlamsal doğrusal Thompson örnekleme politikası.
final class LinTsPolicy {
  LinTsPolicy({
    required LinTsState state,
    required this.gaussianSource,
    required this.clock,
    this.exploration = 1,
  }) : _state = state {
    if (!exploration.isFinite || exploration < 0) {
      throw const LinTsContractException(
        'Keşif katsayısı negatif veya sonlu olmayan değer olamaz.',
      );
    }
  }

  final GaussianSource gaussianSource;
  final Clock clock;
  final double exploration;
  LinTsState _state;

  LinTsState get state => _state;

  LinTsDecision decide(List<num> context) {
    final values = finiteVector(
      context,
      dimension: _state.dimension,
      field: 'Karar bağlamı',
    );
    LinTsArmState? selected;
    var selectedScore = double.negativeInfinity;
    for (final arm in _state.arms) {
      final decomposition = Cholesky.decompose(
        arm.precisionMatrix,
        regularization: 1e-9,
      );
      final mean = decomposition.solve(arm.rewardVector);
      final standardNormal = List<double>.generate(_state.dimension, (_) {
        final value = gaussianSource.next();
        if (!value.isFinite) {
          throw const LinTsContractException(
            'Gaussian kaynak sonlu değer üretmelidir.',
          );
        }
        return value;
      });
      final uncertainty = decomposition.transformStandardNormal(standardNormal);
      final sample = List<double>.generate(
        _state.dimension,
        (index) => mean[index] + exploration * uncertainty[index],
      );
      final score = dot(sample, values);
      if (selected == null ||
          score > selectedScore ||
          (score == selectedScore && arm.armId.compareTo(selected.armId) < 0)) {
        selected = arm;
        selectedScore = score;
      }
    }

    final decisionId =
        '${_state.policyId}-${(_state.sequence + 1).toString().padLeft(12, '0')}';
    final scheduledAt = clock.now().toUtc();
    final chosen = selected!;
    final record = LinTsDecisionRecord.pending(
      decisionId: decisionId,
      armId: chosen.armId,
      context: values,
    );
    _state = _state.addDecision(record);
    return LinTsDecision(
      decisionId: decisionId,
      armId: chosen.armId,
      messageKey: chosen.messageKey,
      scheduledAt: scheduledAt,
      context: values,
    );
  }

  bool reward({
    required String decisionId,
    required List<num> context,
    required double reward,
  }) {
    if (!reward.isFinite || reward < 0 || reward > 1) {
      throw const LinTsContractException('Ödül 0 ile 1 arasında olmalıdır.');
    }
    final values = finiteVector(
      context,
      dimension: _state.dimension,
      field: 'Ödül bağlamı',
    );
    final previous = _state;
    _state = _state.applyReward(
      decisionId: decisionId,
      context: values,
      reward: reward,
    );
    return !identical(previous, _state);
  }
}
