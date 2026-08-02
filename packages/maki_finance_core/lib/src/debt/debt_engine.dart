import '../money/money.dart';
import 'debt_account.dart';
import 'debt_result.dart';
import 'debt_scenario.dart';

/// Deterministik borç ödeme simülatörü.
final class DebtEngine {
  const DebtEngine();

  DebtSimulation simulate(DebtScenario scenario) {
    final balances = <String, int>{
      for (final debt in scenario.debts) debt.id: debt.balance.minorUnits,
    };
    final schedule = <DebtMonth>[];
    var totalInterest = 0;
    var totalPaid = 0;

    for (var month = 1; month <= scenario.maxMonths; month++) {
      final calculation = _calculateMonth(
        scenario: scenario,
        balances: balances,
        month: month,
      );
      if (calculation.failure != null) {
        return _result(
          scenario: scenario,
          balances: balances,
          schedule: schedule,
          status: calculation.failure!,
          monthsElapsed: null,
          totalInterest: totalInterest,
          totalPaid: totalPaid,
        );
      }

      schedule.add(calculation.month!);
      totalInterest += calculation.interest;
      totalPaid += calculation.payment;
      balances
        ..clear()
        ..addAll(calculation.endingBalances);
      if (balances.values.every((balance) => balance == 0)) {
        return _result(
          scenario: scenario,
          balances: balances,
          schedule: schedule,
          status: DebtSimulationStatus.paidOff,
          monthsElapsed: month,
          totalInterest: totalInterest,
          totalPaid: totalPaid,
        );
      }
    }

    return _result(
      scenario: scenario,
      balances: balances,
      schedule: schedule,
      status: DebtSimulationStatus.horizonExceeded,
      monthsElapsed: scenario.maxMonths,
      totalInterest: totalInterest,
      totalPaid: totalPaid,
    );
  }

  _MonthCalculation _calculateMonth({
    required DebtScenario scenario,
    required Map<String, int> balances,
    required int month,
  }) {
    final currency = scenario.monthlyBudget.currency;
    final interests = <String, int>{};
    final afterInterest = <String, int>{};
    final minimums = <String, int>{};

    for (final debt in scenario.debts) {
      final starting = balances[debt.id]!;
      final interest = starting == 0
          ? 0
          : debt.annualRate
                .monthlyInterest(
                  Money(minorUnits: starting, currency: currency),
                )
                .minorUnits;
      final balanceWithInterest = starting + interest;
      interests[debt.id] = interest;
      afterInterest[debt.id] = balanceWithInterest;
      minimums[debt.id] = debt.minimumPayment.minorUnits < balanceWithInterest
          ? debt.minimumPayment.minorUnits
          : balanceWithInterest;
    }

    final totalMinimum = minimums.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (totalMinimum > scenario.monthlyBudget.minorUnits) {
      return const _MonthCalculation.failure(
        DebtSimulationStatus.insufficientMinimumBudget,
      );
    }
    final negative = scenario.debts.any(
      (debt) =>
          afterInterest[debt.id]! > 0 &&
          minimums[debt.id]! < interests[debt.id]!,
    );
    if (negative) {
      return const _MonthCalculation.failure(
        DebtSimulationStatus.negativeAmortization,
      );
    }

    final payments = Map<String, int>.from(minimums);
    var extra = scenario.monthlyBudget.minorUnits - totalMinimum;
    final ordered = _orderedDebts(scenario, afterInterest);
    if (scenario.plan.allocation == DebtAllocation.equal) {
      extra = _allocateEqually(
        debts: ordered,
        afterInterest: afterInterest,
        payments: payments,
        extra: extra,
      );
    } else {
      for (final debt in ordered) {
        if (extra == 0) {
          break;
        }
        final capacity = afterInterest[debt.id]! - payments[debt.id]!;
        final allocation = extra < capacity ? extra : capacity;
        payments[debt.id] = payments[debt.id]! + allocation;
        extra -= allocation;
      }
    }

    final ending = <String, int>{};
    final lines = <DebtMonthLine>[];
    for (final debt in scenario.debts) {
      final start = balances[debt.id]!;
      final interest = interests[debt.id]!;
      final payment = payments[debt.id]!;
      final end = afterInterest[debt.id]! - payment;
      ending[debt.id] = end;
      lines.add(
        DebtMonthLine(
          debtId: debt.id,
          startingBalance: Money(minorUnits: start, currency: currency),
          interest: Money(minorUnits: interest, currency: currency),
          payment: Money(minorUnits: payment, currency: currency),
          principalPaid: Money(
            minorUnits: payment - interest,
            currency: currency,
          ),
          endingBalance: Money(minorUnits: end, currency: currency),
        ),
      );
    }
    final totalPayment = payments.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return _MonthCalculation.success(
      month: DebtMonth(
        monthNumber: month,
        lines: lines,
        totalPayment: Money(minorUnits: totalPayment, currency: currency),
      ),
      endingBalances: ending,
      interest: interests.values.fold<int>(0, (sum, value) => sum + value),
      payment: totalPayment,
    );
  }

  List<DebtAccount> _orderedDebts(
    DebtScenario scenario,
    Map<String, int> afterInterest,
  ) {
    final active = scenario.debts
        .where((debt) => afterInterest[debt.id]! > 0)
        .toList();
    active.sort((left, right) {
      final primary = _compareCriterion(
        scenario.plan.primary,
        scenario.plan.primaryDirection,
        left,
        right,
        afterInterest,
        scenario.plan.manualDebtOrder,
      );
      if (primary != 0) {
        return primary;
      }
      final secondary = _compareCriterion(
        scenario.plan.tieBreaker,
        scenario.plan.tieBreakerDirection,
        left,
        right,
        afterInterest,
        scenario.plan.manualDebtOrder,
      );
      return secondary != 0 ? secondary : left.id.compareTo(right.id);
    });
    return active;
  }

  int _allocateEqually({
    required List<DebtAccount> debts,
    required Map<String, int> afterInterest,
    required Map<String, int> payments,
    required int extra,
  }) {
    var remaining = extra;
    var active = debts
        .where((debt) => afterInterest[debt.id]! > payments[debt.id]!)
        .toList();
    while (remaining > 0 && active.isNotEmpty) {
      final share = (remaining ~/ active.length).clamp(1, remaining);
      var allocated = 0;
      for (final debt in active) {
        if (remaining == 0) break;
        final capacity = afterInterest[debt.id]! - payments[debt.id]!;
        final amount = share < capacity ? share : capacity;
        payments[debt.id] = payments[debt.id]! + amount;
        remaining -= amount;
        allocated += amount;
      }
      if (allocated == 0) break;
      active = active
          .where((debt) => afterInterest[debt.id]! > payments[debt.id]!)
          .toList();
    }
    return remaining;
  }

  int _compareCriterion(
    DebtCriterion criterion,
    DebtDirection direction,
    DebtAccount left,
    DebtAccount right,
    Map<String, int> balances,
    List<String> manualOrder,
  ) {
    final comparison = switch (criterion) {
      DebtCriterion.interestRate => left.annualRate.compareTo(right.annualRate),
      DebtCriterion.balance => balances[left.id]!.compareTo(
        balances[right.id]!,
      ),
      DebtCriterion.minimumPayment => left.minimumPayment.compareTo(
        right.minimumPayment,
      ),
      DebtCriterion.payoffMonths => _comparePayoffMonths(left, right, balances),
      DebtCriterion.manualOrder => _manualRank(
        left.id,
        manualOrder,
      ).compareTo(_manualRank(right.id, manualOrder)),
    };
    return direction == DebtDirection.ascending ? comparison : -comparison;
  }

  int _comparePayoffMonths(
    DebtAccount left,
    DebtAccount right,
    Map<String, int> balances,
  ) => (balances[left.id]! * right.minimumPayment.minorUnits).compareTo(
    balances[right.id]! * left.minimumPayment.minorUnits,
  );

  int _manualRank(String id, List<String> order) {
    final index = order.indexOf(id);
    return index < 0 ? order.length : index;
  }

  DebtSimulation _result({
    required DebtScenario scenario,
    required Map<String, int> balances,
    required List<DebtMonth> schedule,
    required DebtSimulationStatus status,
    required int? monthsElapsed,
    required int totalInterest,
    required int totalPaid,
  }) {
    final currency = scenario.monthlyBudget.currency;
    return DebtSimulation(
      status: status,
      monthsElapsed: monthsElapsed,
      totalInterest: Money(minorUnits: totalInterest, currency: currency),
      totalPaid: Money(minorUnits: totalPaid, currency: currency),
      remainingBalance: Money(
        minorUnits: balances.values.fold<int>(0, (sum, value) => sum + value),
        currency: currency,
      ),
      schedule: schedule,
    );
  }
}

final class _MonthCalculation {
  const _MonthCalculation.failure(this.failure)
    : month = null,
      endingBalances = const {},
      interest = 0,
      payment = 0;

  const _MonthCalculation.success({
    required this.month,
    required this.endingBalances,
    required this.interest,
    required this.payment,
  }) : failure = null;

  final DebtSimulationStatus? failure;
  final DebtMonth? month;
  final Map<String, int> endingBalances;
  final int interest;
  final int payment;
}
