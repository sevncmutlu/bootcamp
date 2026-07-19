import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  const currency = Currency('TRY');

  test('sıfır faizli borç nakit korunarak kapanır', () {
    final result = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'card-a',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 10000, currency: currency),
          ),
        ],
        monthlyBudget: const Money(minorUnits: 25000, currency: currency),
        strategy: DebtStrategy.avalanche,
        maxMonths: 360,
      ),
    );

    expect(result.status, DebtSimulationStatus.paidOff);
    expect(result.monthsElapsed, 4);
    expect(result.totalInterest.minorUnits, 0);
    expect(result.remainingBalance.minorUnits, 0);
    expect(result.totalPaid.minorUnits, 100000);
  });

  test('asgari ödeme faizi karşılamıyorsa negatif amortisman döner', () {
    final result = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'card-a',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate(basisPoints: 12000),
            minimumPayment: Money(minorUnits: 5000, currency: currency),
          ),
        ],
        monthlyBudget: const Money(minorUnits: 5000, currency: currency),
        strategy: DebtStrategy.avalanche,
        maxMonths: 360,
      ),
    );

    expect(result.status, DebtSimulationStatus.negativeAmortization);
    expect(result.monthsElapsed, isNull);
    expect(result.schedule, isEmpty);
  });

  test('toplam asgari ödeme bütçeyi aşıyorsa açık durum döner', () {
    final result = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'a',
            balance: Money(minorUnits: 50000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 10000, currency: currency),
          ),
          DebtAccount(
            id: 'b',
            balance: Money(minorUnits: 50000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 10000, currency: currency),
          ),
        ],
        monthlyBudget: const Money(minorUnits: 15000, currency: currency),
        strategy: DebtStrategy.snowball,
        maxMonths: 360,
      ),
    );

    expect(result.status, DebtSimulationStatus.insufficientMinimumBudget);
    expect(result.monthsElapsed, isNull);
  });

  test('avalanche ek bütçeyi önce yüksek faizli borca verir', () {
    final result = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'low',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate(basisPoints: 1200),
            minimumPayment: Money(minorUnits: 10000, currency: currency),
          ),
          DebtAccount(
            id: 'high',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate(basisPoints: 2400),
            minimumPayment: Money(minorUnits: 10000, currency: currency),
          ),
        ],
        monthlyBudget: const Money(minorUnits: 30000, currency: currency),
        strategy: DebtStrategy.avalanche,
        maxMonths: 1,
      ),
    );

    final firstMonth = result.schedule.single;
    final high = firstMonth.lines.singleWhere((line) => line.debtId == 'high');
    final low = firstMonth.lines.singleWhere((line) => line.debtId == 'low');
    expect(high.payment.minorUnits, greaterThan(low.payment.minorUnits));
    expect(result.status, DebtSimulationStatus.horizonExceeded);
  });
}
