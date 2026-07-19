/// Tamsayı bölme yuvarlama politikası.
enum RoundingMode { halfEven, halfUp, floor, ceiling }

/// Sıfıra bölme denendi.
final class DivisionByZero implements Exception {
  const DivisionByZero();

  @override
  String toString() => 'Payda sıfır olamaz.';
}

/// Bölme sonucunu seçilen açık politikayla tamsayıya yuvarlar.
int divideAndRound(int numerator, int denominator, RoundingMode mode) {
  if (denominator == 0) {
    throw const DivisionByZero();
  }

  final numeratorBig = BigInt.from(numerator);
  final denominatorBig = BigInt.from(denominator);
  final negative = numeratorBig.isNegative != denominatorBig.isNegative;
  final absoluteNumerator = numeratorBig.abs();
  final absoluteDenominator = denominatorBig.abs();
  final quotient = absoluteNumerator ~/ absoluteDenominator;
  final remainder = absoluteNumerator.remainder(absoluteDenominator);
  final increment = _mustIncrement(
    quotient: quotient,
    remainder: remainder,
    denominator: absoluteDenominator,
    negative: negative,
    mode: mode,
  );
  final roundedMagnitude = increment ? quotient + BigInt.one : quotient;
  return (negative ? -roundedMagnitude : roundedMagnitude).toInt();
}

bool _mustIncrement({
  required BigInt quotient,
  required BigInt remainder,
  required BigInt denominator,
  required bool negative,
  required RoundingMode mode,
}) {
  if (remainder == BigInt.zero) {
    return false;
  }
  return switch (mode) {
    RoundingMode.floor => negative,
    RoundingMode.ceiling => !negative,
    RoundingMode.halfUp => remainder * BigInt.two >= denominator,
    RoundingMode.halfEven =>
      remainder * BigInt.two > denominator ||
          (remainder * BigInt.two == denominator && quotient.isOdd),
  };
}
