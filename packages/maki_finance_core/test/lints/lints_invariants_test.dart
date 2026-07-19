import 'dart:convert';
import 'dart:math' as math;

import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:maki_finance_core/src/lints/cholesky.dart';
import 'package:test/test.dart';

void main() {
  test('durum JSON dönüşünde veri kaybetmez', () {
    final state = LinTsState.initial(
      policyId: 'policy-json',
      dimension: 3,
      arms: const [
        LinTsArmSeed(armId: 'arm-a', messageKey: 'mesaj_a'),
        LinTsArmSeed(armId: 'arm-b', messageKey: 'mesaj_b'),
      ],
    );

    final restored = LinTsState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
    );

    expect(restored.toJson(), state.toJson());
  });

  test('1000 güncellemede matrisler pozitif tanımlı kalır', () {
    final gaussian = _SeededGaussian(0x71A5);
    final policy = LinTsPolicy(
      state: LinTsState.initial(
        policyId: 'policy-stability',
        dimension: 4,
        arms: const [
          LinTsArmSeed(armId: 'arm-a', messageKey: 'mesaj_a'),
          LinTsArmSeed(armId: 'arm-b', messageKey: 'mesaj_b'),
          LinTsArmSeed(armId: 'arm-c', messageKey: 'mesaj_c'),
        ],
      ),
      gaussianSource: gaussian,
      clock: const _StepClock(),
      exploration: 0.75,
    );

    for (var index = 0; index < 1000; index++) {
      final context = List<double>.generate(
        4,
        (_) => gaussian.next().clamp(-3, 3),
      );
      final decision = policy.decide(context);
      policy.reward(
        decisionId: decision.decisionId,
        context: context,
        reward: (index % 11) / 10,
      );
    }

    for (final arm in policy.state.arms) {
      expect(() => Cholesky.decompose(arm.precisionMatrix), returnsNormally);
    }
    expect(policy.state.sequence, 1000);
  });

  test('NaN, sonsuz ve asimetrik durum reddedilir', () {
    final valid = LinTsState.initial(
      policyId: 'policy-invalid-state',
      dimension: 2,
      arms: const [LinTsArmSeed(armId: 'arm-a', messageKey: 'mesaj_a')],
    ).toJson();
    final arms = valid['arms']! as List<Object?>;
    final arm = arms.single as Map<String, Object?>;
    arm['precisionMatrix'] = [
      [1.0, 0.5],
      [0.0, 1.0],
    ];

    expect(
      () => LinTsState.fromJson(valid),
      throwsA(isA<LinTsContractException>()),
    );
  });
}

final class _SeededGaussian implements GaussianSource {
  _SeededGaussian(this._state);

  int _state;
  double? _spare;

  double _uniform() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return (_state + 1) / 0x80000000;
  }

  @override
  double next() {
    final spare = _spare;
    if (spare != null) {
      _spare = null;
      return spare;
    }
    final radius = math.sqrt(-2 * math.log(_uniform()));
    final angle = 2 * math.pi * _uniform();
    _spare = radius * math.sin(angle);
    return radius * math.cos(angle);
  }
}

final class _StepClock implements Clock {
  const _StepClock();

  @override
  DateTime now() => DateTime.utc(2026);
}
