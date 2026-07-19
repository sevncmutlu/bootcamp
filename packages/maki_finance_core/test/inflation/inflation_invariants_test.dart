import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  const currency = Currency('TRY');

  test('aynı fiyatlar baz endeksi üretir', () {
    final result = LaspeyresIndex.calculate(
      _basket(currentMultiplierBasisPoints: 10000),
    );

    expect(result.indexBasisPoints, 10000);
  });

  test('iki kat fiyat iki kat endeks üretir', () {
    final result = LaspeyresIndex.calculate(
      _basket(currentMultiplierBasisPoints: 20000),
    );

    expect(result.indexBasisPoints, 20000);
  });

  test('tek fiyat artışı toplam endeksi azaltmaz', () {
    final base = _basket(currentMultiplierBasisPoints: 11000);
    final increased = [...base];
    final item = increased[3];
    increased[3] = BasketItem(
      id: item.id,
      categoryId: item.categoryId,
      baseUnitPrice: item.baseUnitPrice,
      currentUnitPrice: Money(
        minorUnits: item.currentUnitPrice.minorUnits + 1,
        currency: currency,
      ),
      baseQuantity: item.baseQuantity,
      match: item.match,
    );

    expect(
      LaspeyresIndex.calculate(increased).indexBasisPoints,
      greaterThanOrEqualTo(LaspeyresIndex.calculate(base).indexBasisPoints),
    );
  });

  test('kategori katkıları toplam endeks değişimine kapanır', () {
    var seed = 0x1A51;
    for (var scenario = 0; scenario < 1000; scenario++) {
      final items = <BasketItem>[];
      final itemCount = 2 + (seed % 11);
      for (var index = 0; index < itemCount; index++) {
        seed = (1664525 * seed + 1013904223) & 0x7fffffff;
        final basePrice = 1 + (seed % 100000);
        seed = (1664525 * seed + 1013904223) & 0x7fffffff;
        final change = (seed % 10001) - 5000;
        final currentPrice = (basePrice * (10000 + change) ~/ 10000).clamp(
          1,
          1 << 62,
        );
        items.add(
          BasketItem(
            id: 'item-$index',
            categoryId: 'category-${index % 5}',
            baseUnitPrice: Money(minorUnits: basePrice, currency: currency),
            currentUnitPrice: Money(
              minorUnits: currentPrice,
              currency: currency,
            ),
            baseQuantity: 1 + (seed % 20),
            match: index % 7 == 0 ? BasketMatch.proxy : BasketMatch.matched,
          ),
        );
      }

      final result = LaspeyresIndex.calculate(items);
      final contributionTotal = result.categoryContributions.fold<int>(
        0,
        (total, contribution) => total + contribution.basisPoints,
      );

      expect(
        (contributionTotal - (result.indexBasisPoints - 10000)).abs(),
        lessThanOrEqualTo(1),
      );
    }
  });
}

List<BasketItem> _basket({required int currentMultiplierBasisPoints}) {
  const currency = Currency('TRY');
  return List.generate(8, (index) {
    final basePrice = 1000 + (index * 137);
    return BasketItem(
      id: 'item-$index',
      categoryId: 'category-${index % 3}',
      baseUnitPrice: Money(minorUnits: basePrice, currency: currency),
      currentUnitPrice: Money(
        minorUnits: basePrice * currentMultiplierBasisPoints ~/ 10000,
        currency: currency,
      ),
      baseQuantity: index + 1,
      match: index == 2 ? BasketMatch.proxy : BasketMatch.matched,
    );
  });
}
