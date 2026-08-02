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

  test('custom plan applies selected rules in order', () {
    final result = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'small-payment',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 5000, currency: currency),
          ),
          DebtAccount(
            id: 'large-payment',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 10000, currency: currency),
          ),
        ],
        monthlyBudget: const Money(minorUnits: 25000, currency: currency),
        plan: DebtPlan(
          primary: DebtCriterion.minimumPayment,
          primaryDirection: DebtDirection.descending,
          tieBreaker: DebtCriterion.balance,
          tieBreakerDirection: DebtDirection.ascending,
          allocation: DebtAllocation.focused,
        ),
        maxMonths: 1,
      ),
    );

    final month = result.schedule.single;
    final large = month.lines.singleWhere(
      (line) => line.debtId == 'large-payment',
    );
    final small = month.lines.singleWhere(
      (line) => line.debtId == 'small-payment',
    );
    expect(large.payment.minorUnits, 20000);
    expect(small.payment.minorUnits, 5000);
  });

  test('balanced plan splits extra money between open debts', () {
    final result = const DebtEngine().simulate(
      DebtScenario(
        debts: [
          DebtAccount(
            id: 'a',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 5000, currency: currency),
          ),
          DebtAccount(
            id: 'b',
            balance: Money(minorUnits: 100000, currency: currency),
            annualRate: AnnualRate.zero,
            minimumPayment: Money(minorUnits: 5000, currency: currency),
          ),
        ],
        monthlyBudget: const Money(minorUnits: 20000, currency: currency),
        plan: DebtPlan.balanced(),
        maxMonths: 1,
      ),
    );

    expect(
      result.schedule.single.lines.map((line) => line.payment.minorUnits),
      everyElement(10000),
    );
  });
}
