import '../money/money.dart';
import '../money/rounding.dart';

/// Yıllık oranı baz puan olarak tutar.
final class AnnualRate implements Comparable<AnnualRate> {
  const AnnualRate({
    required this.basisPoints,
    this.roundingMode = RoundingMode.halfEven,
  }) : assert(basisPoints >= 0);

  static const zero = AnnualRate(basisPoints: 0);

  final int basisPoints;
  final RoundingMode roundingMode;

  /// Bir aylık basit faizi tamsayı alt para birimi olarak hesaplar.
  Money monthlyInterest(Money balance) => Money(
    minorUnits: divideAndRound(
      balance.minorUnits * basisPoints,
      120000,
      roundingMode,
    ),
    currency: balance.currency,
  );

  @override
  int compareTo(AnnualRate other) => basisPoints.compareTo(other.basisPoints);

  @override
  bool operator ==(Object other) =>
      other is AnnualRate &&
      other.basisPoints == basisPoints &&
      other.roundingMode == roundingMode;

  @override
  int get hashCode => Object.hash(basisPoints, roundingMode);
}
