import 'package:maki_finance_core/maki_finance_core.dart' as finance;
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/domain/entities/payoff_month_entity.dart';
import 'package:maki_app/features/simulator/domain/entities/simulation_result_entity.dart';
import 'package:maki_app/features/simulator/domain/repositories/simulator_repository.dart';

class SimulatorRepositoryImpl implements SimulatorRepository {
  SimulatorRepositoryImpl();

  @override
  Future<SimulationResultEntity> simulatePayoff({
    required List<DebtEntity> debts,
    required double extraBudget,
    required String strategy,
  }) async {
    const currency = finance.Currency('TRY');
    
    final accounts = debts.map((debt) {
      return finance.DebtAccount(
        id: debt.id,
        balance: finance.Money(
          minorUnits: (debt.balance * 100).round(),
          currency: currency,
        ),
        annualRate: finance.AnnualRate(
          basisPoints: (debt.interestRate * 100).round(),
        ),
        minimumPayment: finance.Money(
          minorUnits: (debt.minPayment * 100).round(),
          currency: currency,
        ),
      );
    }).toList();

    final minimumPayments = accounts.fold<int>(
      0,
      (sum, account) => sum + account.minimumPayment.minorUnits,
    );

    final debtStrategy = strategy == 'snowball'
        ? finance.DebtStrategy.snowball
        : finance.DebtStrategy.avalanche;

    final result = const finance.DebtEngine().simulate(
      finance.DebtScenario(
        debts: accounts,
        monthlyBudget: finance.Money(
          minorUnits: minimumPayments + (extraBudget * 100).round(),
          currency: currency,
        ),
        strategy: debtStrategy,
        maxMonths: 1200,
      ),
    );

    if (result.status != finance.DebtSimulationStatus.paidOff) {
      throw const finance.DebtValidationException(
        'Bu ödeme planı borçları güvenli biçimde kapatmıyor.',
      );
    }

    final schedule = result.schedule.map((month) {
      final remainingBalance = month.lines.fold<int>(
            0,
            (sum, line) => sum + line.endingBalance.minorUnits,
          ) /
          100;
      
      return PayoffMonthEntity(
        month: month.monthNumber,
        remainingBalance: remainingBalance,
      );
    }).toList();

    return SimulationResultEntity(
      monthsToFree: result.monthsElapsed ?? 0,
      totalInterestPaid: result.totalInterest.minorUnits / 100,
      schedule: schedule,
    );
  }
}
