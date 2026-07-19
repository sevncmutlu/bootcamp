import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  const tryCurrency = Currency('TRY');

  test('aynı para birimi toplanır', () {
    expect(
      const Money(minorUnits: 125, currency: tryCurrency) +
          const Money(minorUnits: 75, currency: tryCurrency),
      const Money(minorUnits: 200, currency: tryCurrency),
    );
  });

  test('farklı para birimi reddedilir', () {
    expect(
      () =>
          const Money(minorUnits: 1, currency: Currency('TRY')) +
          const Money(minorUnits: 1, currency: Currency('USD')),
      throwsA(isA<CurrencyMismatch>()),
    );
  });

  test('para birimi dış girdide doğrulanır', () {
    expect(() => Currency.parse('try'), throwsA(isA<FormatException>()));
    expect(Currency.parse('TRY'), tryCurrency);
  });

  test('aylık faiz baz puan ile tamsayı hesaplanır', () {
    const rate = AnnualRate(basisPoints: 1200);
    const balance = Money(minorUnits: 100000, currency: tryCurrency);

    expect(
      rate.monthlyInterest(balance),
      const Money(minorUnits: 1000, currency: tryCurrency),
    );
  });
}
