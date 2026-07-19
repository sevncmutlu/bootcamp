import '../money/money.dart';
import '../rates/annual_rate.dart';

/// Borç girdisi geçersiz.
final class DebtValidationException implements Exception {
  const DebtValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tek bir borcun değişmez ödeme koşulları.
final class DebtAccount {
  DebtAccount({
    required this.id,
    required this.balance,
    required this.annualRate,
    required this.minimumPayment,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id)) {
      throw const DebtValidationException('Borç kimliği geçersiz.');
    }
    if (balance.minorUnits <= 0) {
      throw const DebtValidationException('Borç bakiyesi pozitif olmalıdır.');
    }
    if (minimumPayment.minorUnits <= 0) {
      throw const DebtValidationException('Asgari ödeme pozitif olmalıdır.');
    }
    if (balance.currency != minimumPayment.currency) {
      throw CurrencyMismatch(balance.currency, minimumPayment.currency);
    }
    if (annualRate.basisPoints < 0) {
      throw const DebtValidationException('Yıllık faiz negatif olamaz.');
    }
  }

  final String id;
  final Money balance;
  final AnnualRate annualRate;
  final Money minimumPayment;
}
