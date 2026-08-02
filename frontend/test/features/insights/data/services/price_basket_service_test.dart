import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/insights/data/services/price_basket_service.dart';

void main() {
  late AppDatabase database;
  late PriceBasketService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = PriceBasketService(database);
  });

  tearDown(() => database.close());

  test('veri yokken sahte kişisel enflasyon üretmez', () async {
    final result = await service.calculate();

    expect(result.hasPriceBasket, isFalse);
    expect(result.personalInflation, isNull);
    expect(result.status, 'insufficient_data');
  });

  test(
    'aynı ürünün iki doğrulanmış fiyatından gerçek oranı hesaplar',
    () async {
      await service.addManualObservation(
        productName: 'Süt 1 L',
        category: 'Market',
        observedAt: DateTime(2026, 6, 1),
        unitPriceMinor: 4000,
      );
      await service.addManualObservation(
        productName: 'Süt 1 L',
        category: 'Market',
        observedAt: DateTime(2026, 7, 1),
        unitPriceMinor: 4400,
      );

      final result = await service.calculate();

      expect(result.status, 'ready');
      expect(result.coveragePercent, 100);
      expect(result.personalInflation, 10);
      expect(result.basePeriod, '2026-06');
      expect(result.currentPeriod, '2026-07');
    },
  );

  test(
    'tek fiyatı resmi oranla doldursa bile kişisel sonuç diye sunmaz',
    () async {
      await service.addManualObservation(
        productName: 'Ekmek',
        category: 'Market',
        observedAt: DateTime(2026, 7, 1),
        unitPriceMinor: 1500,
      );
      await service.storeOfficial(
        OfficialInflationReply(
          period: '2026-07',
          previousPeriod: '2026-06',
          rateBasisPoints: 352,
          source: 'TÜİK',
          sourceUrl: 'https://data.tuik.gov.tr/',
          retrievedAt: DateTime(2026, 8, 1),
        ),
      );

      final result = await service.calculate();

      expect(result.hasPriceBasket, isTrue);
      expect(result.personalInflation, isNull);
      expect(result.officialInflation, 3.52);
      expect(result.status, 'needs_second_price');
    },
  );

  test('aynı fiş kalemini ikinci kez onaylamak çoğaltmaz', () async {
    const item = ReceiptLineScan(
      productName: 'Yoğurt',
      quantityMilli: 1000,
      unitPriceMinor: 5500,
      lineTotalMinor: 5500,
      confidence: .97,
    );
    final observedAt = DateTime(2026, 7, 20);

    for (var index = 0; index < 2; index++) {
      await service.confirmReceiptItems(
        items: const [item],
        category: 'Market',
        observedAt: observedAt,
        sourceRef: 'receipt-42',
      );
    }

    expect(await database.select(database.priceProducts).get(), hasLength(1));
    expect(
      await database.select(database.priceObservations).get(),
      hasLength(1),
    );
  });
}
