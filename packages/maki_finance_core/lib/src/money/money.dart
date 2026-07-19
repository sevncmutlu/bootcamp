import 'currency.dart';

/// Farklı para birimleriyle işlem denendi.
final class CurrencyMismatch implements Exception {
  const CurrencyMismatch(this.left, this.right);

  final Currency left;
  final Currency right;

  @override
  String toString() => 'Para birimleri eşleşmiyor: $left ve $right.';
}

/// Alt para birimi cinsinden değişmez para değeri.
final class Money implements Comparable<Money> {
  const Money({required this.minorUnits, required this.currency});

  final int minorUnits;
  final Currency currency;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits: minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits: minorUnits - other.minorUnits, currency: currency);
  }

  Money operator -() => Money(minorUnits: -minorUnits, currency: currency);

  bool get isNegative => minorUnits.isNegative;

  bool get isZero => minorUnits == 0;

  Money min(Money other) {
    _requireSameCurrency(other);
    return minorUnits <= other.minorUnits ? this : other;
  }

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatch(currency, other.currency);
    }
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '$minorUnits ${currency.code} alt birim';
}
