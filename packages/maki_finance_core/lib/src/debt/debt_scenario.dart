import '../money/money.dart';
import 'debt_account.dart';

/// Ek ödeme önceliği.
enum DebtStrategy { avalanche, snowball }

/// Kullanıcının ek ödemeyi hangi ölçüte göre yönlendireceği.
enum DebtCriterion {
  interestRate,
  balance,
  minimumPayment,
  payoffMonths,
  manualOrder,
}

/// Ölçütte düşük veya yüksek değerin önce gelmesi.
enum DebtDirection { ascending, descending }

/// Asgari ödemelerden sonra kalan paranın dağıtılma biçimi.
enum DebtAllocation { focused, equal }

/// Hazır veya kullanıcı tanımlı, deterministik borç kapatma yolu.
final class DebtPlan {
  DebtPlan({
    required this.primary,
    required this.primaryDirection,
    required this.tieBreaker,
    required this.tieBreakerDirection,
    required this.allocation,
    List<String> manualDebtOrder = const [],
  }) : manualDebtOrder = List.unmodifiable(manualDebtOrder) {
    if (primary == tieBreaker && primary != DebtCriterion.manualOrder) {
      throw const DebtValidationException(
        'İlk kural ve eşitlik kuralı farklı olmalıdır.',
      );
    }
  }

  factory DebtPlan.forStrategy(DebtStrategy strategy) => switch (strategy) {
    DebtStrategy.avalanche => DebtPlan(
      primary: DebtCriterion.interestRate,
      primaryDirection: DebtDirection.descending,
      tieBreaker: DebtCriterion.balance,
      tieBreakerDirection: DebtDirection.ascending,
      allocation: DebtAllocation.focused,
    ),
    DebtStrategy.snowball => DebtPlan(
      primary: DebtCriterion.balance,
      primaryDirection: DebtDirection.ascending,
      tieBreaker: DebtCriterion.interestRate,
      tieBreakerDirection: DebtDirection.descending,
      allocation: DebtAllocation.focused,
    ),
  };

  factory DebtPlan.lowerMonthlyLoad() => DebtPlan(
    primary: DebtCriterion.payoffMonths,
    primaryDirection: DebtDirection.ascending,
    tieBreaker: DebtCriterion.minimumPayment,
    tieBreakerDirection: DebtDirection.descending,
    allocation: DebtAllocation.focused,
  );

  factory DebtPlan.balanced() => DebtPlan(
    primary: DebtCriterion.interestRate,
    primaryDirection: DebtDirection.descending,
    tieBreaker: DebtCriterion.balance,
    tieBreakerDirection: DebtDirection.ascending,
    allocation: DebtAllocation.equal,
  );

  factory DebtPlan.manual(List<String> debtOrder) => DebtPlan(
    primary: DebtCriterion.manualOrder,
    primaryDirection: DebtDirection.ascending,
    tieBreaker: DebtCriterion.interestRate,
    tieBreakerDirection: DebtDirection.descending,
    allocation: DebtAllocation.focused,
    manualDebtOrder: debtOrder,
  );

  final DebtCriterion primary;
  final DebtDirection primaryDirection;
  final DebtCriterion tieBreaker;
  final DebtDirection tieBreakerDirection;
  final DebtAllocation allocation;
  final List<String> manualDebtOrder;
}

/// Borç motorunun doğrulanmış girdisi.
final class DebtScenario {
  DebtScenario({
    required List<DebtAccount> debts,
    required this.monthlyBudget,
    DebtStrategy? strategy,
    DebtPlan? plan,
    required this.maxMonths,
  }) : debts = List.unmodifiable(debts),
       strategy = strategy ?? DebtStrategy.avalanche,
       plan = plan ?? DebtPlan.forStrategy(strategy ?? DebtStrategy.avalanche) {
    if (debts.isEmpty) {
      throw const DebtValidationException('En az bir borç gereklidir.');
    }
    if (maxMonths < 1 || maxMonths > 1200) {
      throw const DebtValidationException(
        'Ay ufku 1 ile 1200 arasında olmalıdır.',
      );
    }
    if (monthlyBudget.minorUnits <= 0) {
      throw const DebtValidationException('Aylık bütçe pozitif olmalıdır.');
    }
    final ids = <String>{};
    for (final debt in debts) {
      if (!ids.add(debt.id)) {
        throw const DebtValidationException(
          'Borç kimlikleri benzersiz olmalıdır.',
        );
      }
      if (debt.balance.currency != monthlyBudget.currency) {
        throw CurrencyMismatch(debt.balance.currency, monthlyBudget.currency);
      }
    }
  }

  final List<DebtAccount> debts;
  final Money monthlyBudget;
  final DebtStrategy strategy;
  final DebtPlan plan;
  final int maxMonths;
}
