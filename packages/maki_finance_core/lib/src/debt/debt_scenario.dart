import '../money/money.dart';
import 'debt_account.dart';

/// Ek ödeme önceliği.
enum DebtStrategy { avalanche, snowball }

/// Borç motorunun doğrulanmış girdisi.
final class DebtScenario {
  DebtScenario({
    required List<DebtAccount> debts,
    required this.monthlyBudget,
    required this.strategy,
    required this.maxMonths,
  }) : debts = List.unmodifiable(debts) {
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
  final int maxMonths;
}
