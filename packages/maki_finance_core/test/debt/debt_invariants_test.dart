import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  const currency = Currency('TRY');

  test('sabit tohumlu senaryolarda muhasebe değişmezleri korunur', () {
    var seed = 0xD3B7;
    for (var caseIndex = 0; caseIndex < 2000; caseIndex++) {
      seed = _next(seed);
      final balance = 10000 + seed % 500000;
      seed = _next(seed);
      final basisPoints = seed % 3000;
      seed = _next(seed);
      final minimum = 1000 + seed % 10000;
      seed = _next(seed);
      final extra = seed % 20000;
      final budget = minimum + extra;
      final scenario = DebtScenario(
        debts: [
          DebtAccount(
            id: 'debt-$caseIndex',
            balance: Money(minorUnits: balance, currency: currency),
            annualRate: AnnualRate(basisPoints: basisPoints),
            minimumPayment: Money(minorUnits: minimum, currency: currency),
          ),
        ],
        monthlyBudget: Money(minorUnits: budget, currency: currency),
        strategy: DebtStrategy.avalanche,
        maxMonths: 120,
      );

      final result = const DebtEngine().simulate(scenario);
      for (final month in result.schedule) {
        expect(month.totalPayment.minorUnits, lessThanOrEqualTo(budget));
        for (final line in month.lines) {
          expect(
            line.startingBalance.minorUnits +
                line.interest.minorUnits -
                line.payment.minorUnits,
            line.endingBalance.minorUnits,
          );
          expect(line.endingBalance.minorUnits, isNonNegative);
        }
      }
    }
  });

  test('daha yüksek bütçe kapanma süresini uzatmaz', () {
    for (var index = 1; index <= 200; index++) {
      final debt = DebtAccount(
        id: 'card',
        balance: const Money(minorUnits: 500000, currency: currency),
        annualRate: AnnualRate(basisPoints: index * 10),
        minimumPayment: const Money(minorUnits: 20000, currency: currency),
      );
      final lower = const DebtEngine().simulate(
        DebtScenario(
          debts: [debt],
          monthlyBudget: const Money(minorUnits: 30000, currency: currency),
          strategy: DebtStrategy.avalanche,
          maxMonths: 360,
        ),
      );
      final higher = const DebtEngine().simulate(
        DebtScenario(
          debts: [debt],
          monthlyBudget: const Money(minorUnits: 50000, currency: currency),
          strategy: DebtStrategy.avalanche,
          maxMonths: 360,
        ),
      );

      if (lower.status == DebtSimulationStatus.paidOff &&
          higher.status == DebtSimulationStatus.paidOff) {
        expect(higher.monthsElapsed!, lessThanOrEqualTo(lower.monthsElapsed!));
      }
    }
  });
}

int _next(int value) => (1664525 * value + 1013904223) & 0x7fffffff;
