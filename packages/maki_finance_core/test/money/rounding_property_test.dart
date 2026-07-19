import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  test('yarım çift yuvarlama çift sonuca gider', () {
    expect(divideAndRound(5, 2, RoundingMode.halfEven), 2);
    expect(divideAndRound(7, 2, RoundingMode.halfEven), 4);
    expect(divideAndRound(-5, 2, RoundingMode.halfEven), -2);
    expect(divideAndRound(-7, 2, RoundingMode.halfEven), -4);
  });

  test('taban ve tavan negatif sayılarda matematiksel davranır', () {
    expect(divideAndRound(-5, 2, RoundingMode.floor), -3);
    expect(divideAndRound(-5, 2, RoundingMode.ceiling), -2);
    expect(divideAndRound(5, -2, RoundingMode.floor), -3);
    expect(divideAndRound(5, -2, RoundingMode.ceiling), -2);
  });

  test('bölme hatası yarım birimden büyük değildir', () {
    var seed = 0x5EED;
    for (var index = 0; index < 5000; index++) {
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      final numerator = seed - 0x3fffffff;
      final denominator = (seed % 997) + 1;
      final rounded = divideAndRound(
        numerator,
        denominator,
        RoundingMode.halfEven,
      );
      final doubledError = (2 * (rounded * denominator - numerator)).abs();
      expect(doubledError, lessThanOrEqualTo(denominator));
    }
  });

  test('sıfıra bölme açık hata üretir', () {
    expect(
      () => divideAndRound(1, 0, RoundingMode.halfEven),
      throwsA(isA<DivisionByZero>()),
    );
  });
}
