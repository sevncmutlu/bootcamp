import 'dart:io';

import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  test('kararlı finans tipleri tek giriş noktasından kullanılabilir', () {
    const currency = Currency('TRY');
    const money = Money(minorUnits: 10000, currency: currency);
    final debt = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'card',
            balance: money,
            annualRate: AnnualRate.zero,
            minimumPayment: money,
          ),
        ],
        monthlyBudget: money,
        strategy: DebtStrategy.avalanche,
        maxMonths: 1,
      ),
    );
    final inflation = LaspeyresIndex.calculate([
      BasketItem(
        id: 'market',
        categoryId: 'market',
        baseUnitPrice: money,
        currentUnitPrice: money,
        baseQuantity: 1,
        match: BasketMatch.matched,
      ),
    ]);
    final policy = LinTsPolicy(
      state: LinTsState.initial(
        policyId: 'public-api',
        dimension: 1,
        arms: const [LinTsArmSeed(armId: 'arm', messageKey: 'mesaj')],
      ),
      gaussianSource: const _ZeroGaussian(),
      clock: const _FixedClock(),
    );
    final modelLoader = VerifiedLightGbmModel.load;

    expect(debt.status, DebtSimulationStatus.paidOff);
    expect(inflation.indexBasisPoints, 10000);
    expect(policy.decide(const [1]).armId, 'arm');
    expect(modelLoader, isNotNull);
  });

  test('sürüm ve entegrasyon belgeleri paketle birlikte bulunur', () {
    expect(File('CHANGELOG.md').existsSync(), isTrue);
    expect(File('../../docs/integration/finance-core.md').existsSync(), isTrue);
  });

  test('iç ayrıştırıcı ve matris yardımcısı dışa açılmaz', () {
    final library = File('lib/maki_finance_core.dart').readAsStringSync();

    expect(library, isNot(contains('lightgbm_parser.dart')));
    expect(library, isNot(contains('cholesky.dart')));
    expect(library, isNot(contains('vector.dart')));
  });
}

final class _ZeroGaussian implements GaussianSource {
  const _ZeroGaussian();

  @override
  double next() => 0;
}

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026);
}
