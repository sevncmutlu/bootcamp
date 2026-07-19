import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  const currency = Currency('TRY');

  test('Laspeyres endeksi baz miktarlarıyla hesaplanır', () {
    final result = LaspeyresIndex.calculate([
      BasketItem(
        id: 'food',
        categoryId: 'market',
        baseUnitPrice: const Money(minorUnits: 1000, currency: currency),
        currentUnitPrice: const Money(minorUnits: 1200, currency: currency),
        baseQuantity: 2,
        match: BasketMatch.matched,
      ),
      BasketItem(
        id: 'transport',
        categoryId: 'ulasim',
        baseUnitPrice: const Money(minorUnits: 2000, currency: currency),
        currentUnitPrice: const Money(minorUnits: 2200, currency: currency),
        baseQuantity: 1,
        match: BasketMatch.matched,
      ),
    ]);

    expect(result.status, InflationStatus.normal);
    expect(result.indexBasisPoints, 11500);
    expect(result.coverageBasisPoints, 10000);
    expect(result.matchedShareBasisPoints, 10000);
    expect(result.proxyShareBasisPoints, 0);
    expect(result.excludedShareBasisPoints, 0);
    expect(
      result.categoryContributions
          .map((contribution) => contribution.basisPoints)
          .reduce((left, right) => left + right),
      1500,
    );
  });

  test('dışlanan kalem kapsama paydasında kalır', () {
    final result = LaspeyresIndex.calculate([
      BasketItem(
        id: 'included',
        categoryId: 'market',
        baseUnitPrice: const Money(minorUnits: 6000, currency: currency),
        currentUnitPrice: const Money(minorUnits: 6600, currency: currency),
        baseQuantity: 1,
        match: BasketMatch.proxy,
      ),
      BasketItem(
        id: 'excluded',
        categoryId: 'konut',
        baseUnitPrice: const Money(minorUnits: 4000, currency: currency),
        currentUnitPrice: const Money(minorUnits: 8000, currency: currency),
        baseQuantity: 1,
        match: BasketMatch.excluded,
      ),
    ]);

    expect(result.status, InflationStatus.insufficientCoverage);
    expect(result.indexBasisPoints, 11000);
    expect(result.coverageBasisPoints, 6000);
    expect(result.proxyShareBasisPoints, 6000);
    expect(result.excludedShareBasisPoints, 4000);
  });

  test('para birimi uyuşmazlığı açıkça reddedilir', () {
    expect(
      () => BasketItem(
        id: 'food',
        categoryId: 'market',
        baseUnitPrice: const Money(minorUnits: 1000, currency: Currency('TRY')),
        currentUnitPrice: const Money(
          minorUnits: 1000,
          currency: Currency('USD'),
        ),
        baseQuantity: 1,
        match: BasketMatch.matched,
      ),
      throwsA(isA<CurrencyMismatch>()),
    );
  });
}
