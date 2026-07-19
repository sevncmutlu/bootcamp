import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  test('sabit kaynaklarla karar bütünüyle tekrarlanabilir', () {
    final policy = LinTsPolicy(
      state: LinTsState.initial(
        policyId: 'policy-1',
        dimension: 2,
        arms: const [
          LinTsArmSeed(
            armId: 'arm-a',
            messageKey: 'mesaj_a',
            rewardVector: [1, 0],
          ),
          LinTsArmSeed(
            armId: 'arm-b',
            messageKey: 'mesaj_b',
            rewardVector: [0, 1],
          ),
        ],
      ),
      gaussianSource: _SequenceGaussian(List.filled(4, 0)),
      clock: _FixedClock(DateTime.utc(2026, 7, 19, 9, 30)),
      exploration: 0.5,
    );

    final decision = policy.decide(const [1, 0.2]);

    expect(decision.armId, 'arm-a');
    expect(decision.messageKey, 'mesaj_a');
    expect(decision.decisionId, 'policy-1-000000000001');
    expect(decision.scheduledAt, DateTime.utc(2026, 7, 19, 9, 30));
    expect(decision.context, const [1, 0.2]);
  });

  test('eşit skor arm kimliğine göre çözülür', () {
    final policy = LinTsPolicy(
      state: LinTsState.initial(
        policyId: 'policy-tie',
        dimension: 2,
        arms: const [
          LinTsArmSeed(armId: 'z-arm', messageKey: 'z'),
          LinTsArmSeed(armId: 'a-arm', messageKey: 'a'),
        ],
      ),
      gaussianSource: _SequenceGaussian(List.filled(4, 0)),
      clock: _FixedClock(DateTime.utc(2026)),
    );

    expect(policy.decide(const [0, 0]).armId, 'a-arm');
  });

  test('ödül aynı karar için yalnızca bir kez uygulanır', () {
    final policy = LinTsPolicy(
      state: LinTsState.initial(
        policyId: 'policy-reward',
        dimension: 2,
        arms: const [LinTsArmSeed(armId: 'arm-a', messageKey: 'mesaj_a')],
      ),
      gaussianSource: _SequenceGaussian(const [0, 0]),
      clock: _FixedClock(DateTime.utc(2026)),
    );
    final decision = policy.decide(const [1, 2]);

    expect(
      policy.reward(
        decisionId: decision.decisionId,
        context: const [1, 2],
        reward: 0.5,
      ),
      isTrue,
    );
    final once = policy.state.toJson();
    expect(
      policy.reward(
        decisionId: decision.decisionId,
        context: const [1, 2],
        reward: 0.5,
      ),
      isFalse,
    );
    expect(policy.state.toJson(), once);
    expect(policy.state.arms.single.precisionMatrix, const [
      [2.0, 2.0],
      [2.0, 5.0],
    ]);
    expect(policy.state.arms.single.rewardVector, const [0.5, 1.0]);
  });

  test('ödüldeki farklı bağlam ve sınır dışı değer reddedilir', () {
    final policy = LinTsPolicy(
      state: LinTsState.initial(
        policyId: 'policy-invalid',
        dimension: 2,
        arms: const [LinTsArmSeed(armId: 'arm-a', messageKey: 'mesaj_a')],
      ),
      gaussianSource: _SequenceGaussian(const [0, 0]),
      clock: _FixedClock(DateTime.utc(2026)),
    );
    final decision = policy.decide(const [1, 2]);

    expect(
      () => policy.reward(
        decisionId: decision.decisionId,
        context: const [2, 1],
        reward: 0.5,
      ),
      throwsA(isA<LinTsContractException>()),
    );
    expect(
      () => policy.reward(
        decisionId: decision.decisionId,
        context: const [1, 2],
        reward: 1.1,
      ),
      throwsA(isA<LinTsContractException>()),
    );
  });
}

final class _SequenceGaussian implements GaussianSource {
  _SequenceGaussian(this.values);

  final List<double> values;
  var _index = 0;

  @override
  double next() => values[_index++];
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
