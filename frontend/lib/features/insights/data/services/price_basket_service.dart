import 'dart:math';

import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';
import 'package:maki_finance_core/maki_finance_core.dart' as finance;

class PriceBasketService {
  PriceBasketService(this._database);

  final AppDatabase _database;

  Future<void> confirmReceiptItems({
    required List<ReceiptLineScan> items,
    required String category,
    required DateTime observedAt,
    required String sourceRef,
  }) async {
    await _database.transaction(() async {
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        if (item.unitPriceMinor <= 0 || item.quantityMilli <= 0) continue;
        final product = await _upsertProduct(
          displayName: item.productName,
          category: category,
          baseQuantityMilli: item.quantityMilli,
          now: observedAt,
        );
        await _database
            .into(_database.priceObservations)
            .insert(
              PriceObservationsCompanion.insert(
                id: 'receipt:$sourceRef:$index',
                productId: product.id,
                observedAt: observedAt,
                unitPriceMinor: item.unitPriceMinor,
                quantityMilli: Value(item.quantityMilli),
                sourceType: 'receipt',
                sourceRef: Value(sourceRef),
                confidence: Value(item.confidence.clamp(0, 1)),
                confirmed: const Value(true),
                createdAt: DateTime.now(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<void> addManualObservation({
    required String productName,
    required String category,
    required DateTime observedAt,
    required int unitPriceMinor,
    int quantityMilli = 1000,
  }) async {
    if (unitPriceMinor <= 0 || quantityMilli <= 0) {
      throw const FormatException('Fiyat ve miktar sıfırdan büyük olmalıdır.');
    }
    await _database.transaction(() async {
      final product = await _upsertProduct(
        displayName: productName,
        category: category,
        baseQuantityMilli: quantityMilli,
        now: observedAt,
      );
      final id = 'manual:${product.id}:${observedAt.microsecondsSinceEpoch}';
      await _database
          .into(_database.priceObservations)
          .insert(
            PriceObservationsCompanion.insert(
              id: id,
              productId: product.id,
              observedAt: observedAt,
              unitPriceMinor: unitPriceMinor,
              quantityMilli: Value(quantityMilli),
              sourceType: 'manual',
              confidence: const Value(1),
              confirmed: const Value(true),
              createdAt: DateTime.now(),
            ),
          );
    });
  }

  Future<void> storeOfficial(OfficialInflationReply reply) async {
    await _database
        .into(_database.officialInflationSnapshots)
        .insertOnConflictUpdate(
          OfficialInflationSnapshotsCompanion.insert(
            id: reply.period,
            period: reply.period,
            rateBasisPoints: reply.rateBasisPoints,
            source: reply.source,
            sourceUrl: reply.sourceUrl,
            retrievedAt: reply.retrievedAt,
          ),
        );
  }

  Future<InflationDataEntity> calculate() async {
    final products = await (_database.select(
      _database.priceProducts,
    )..where((row) => row.active.equals(true))).get();
    final observations =
        await (_database.select(_database.priceObservations)
              ..where((row) => row.confirmed.equals(true))
              ..orderBy([(row) => OrderingTerm.asc(row.observedAt)]))
            .get();
    final official =
        await (_database.select(_database.officialInflationSnapshots)
              ..orderBy([(row) => OrderingTerm.desc(row.period)])
              ..limit(1))
            .getSingleOrNull();

    final byProduct = <String, List<PriceObservation>>{};
    for (final observation in observations) {
      byProduct.putIfAbsent(observation.productId, () => []).add(observation);
    }
    if (products.isEmpty || byProduct.isEmpty) {
      return InflationDataEntity(
        hasPriceBasket: false,
        officialInflation: official?.rateBasisPoints == null
            ? null
            : official!.rateBasisPoints / 100,
        status: 'insufficient_data',
      );
    }

    const currency = finance.Currency('TRY');
    final basket = <finance.BasketItem>[];
    final included = <_IncludedItem>[];
    DateTime? baseDate;
    DateTime? currentDate;
    for (final product in products) {
      final values = byProduct[product.id];
      if (values == null || values.isEmpty) continue;
      final base = values.first;
      final hasCurrent =
          values.length >= 2 && values.last.observedAt.isAfter(base.observedAt);
      final latest = values.last;
      final match = hasCurrent
          ? finance.BasketMatch.matched
          : official != null
          ? finance.BasketMatch.proxy
          : finance.BasketMatch.excluded;
      final currentMinor = hasCurrent
          ? latest.unitPriceMinor
          : official != null
          ? max(
              1,
              ((base.unitPriceMinor * (10000 + official.rateBasisPoints)) /
                      10000)
                  .round(),
            )
          : base.unitPriceMinor;
      final item = finance.BasketItem(
        id: product.id,
        categoryId: product.category,
        baseUnitPrice: finance.Money(
          minorUnits: base.unitPriceMinor,
          currency: currency,
        ),
        currentUnitPrice: finance.Money(
          minorUnits: currentMinor,
          currency: currency,
        ),
        baseQuantity: product.baseQuantityMilli,
        match: match,
      );
      basket.add(item);
      included.add(
        _IncludedItem(
          category: product.category,
          baseSpend: base.unitPriceMinor * product.baseQuantityMilli,
          currentSpend: currentMinor * product.baseQuantityMilli,
          excluded: match == finance.BasketMatch.excluded,
        ),
      );
      baseDate = baseDate == null || base.observedAt.isBefore(baseDate)
          ? base.observedAt
          : baseDate;
      final candidate = hasCurrent ? latest.observedAt : base.observedAt;
      currentDate = currentDate == null || candidate.isAfter(currentDate)
          ? candidate
          : currentDate;
    }
    if (basket.isEmpty) {
      return InflationDataEntity(
        hasPriceBasket: false,
        officialInflation: official?.rateBasisPoints == null
            ? null
            : official!.rateBasisPoints / 100,
        status: 'insufficient_data',
      );
    }

    final result = finance.LaspeyresIndex.calculate(basket);
    final sufficient =
        result.status == finance.InflationStatus.normal &&
        basket.any((item) => item.match == finance.BasketMatch.matched);
    return InflationDataEntity(
      hasPriceBasket: true,
      personalInflation: sufficient
          ? (result.indexBasisPoints - 10000) / 100
          : null,
      officialInflation: official == null
          ? null
          : official.rateBasisPoints / 100,
      coveragePercent: result.coverageBasisPoints / 100,
      status: sufficient
          ? 'ready'
          : result.status == finance.InflationStatus.insufficientCoverage
          ? 'insufficient_coverage'
          : 'needs_second_price',
      basePeriod: baseDate == null ? null : _period(baseDate),
      currentPeriod: currentDate == null
          ? official?.period
          : _period(currentDate),
      breakdowns: _breakdowns(included),
    );
  }

  Future<PriceProduct> _upsertProduct({
    required String displayName,
    required String category,
    required int baseQuantityMilli,
    required DateTime now,
  }) async {
    final normalized = normalizeProductName(displayName);
    if (normalized.isEmpty) {
      throw const FormatException('Ürün adı boş olamaz.');
    }
    final existing = await (_database.select(
      _database.priceProducts,
    )..where((row) => row.normalizedName.equals(normalized))).getSingleOrNull();
    if (existing != null) return existing;
    final id = 'product-${_stableHash(normalized)}';
    final product = PriceProduct(
      id: id,
      normalizedName: normalized,
      displayName: displayName.trim(),
      category: category,
      baseQuantityMilli: baseQuantityMilli,
      active: true,
      createdAt: now,
    );
    await _database.into(_database.priceProducts).insert(product);
    return product;
  }

  static String normalizeProductName(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9ÇĞİÖŞÜ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _period(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static List<CategoryBreakdownEntity> _breakdowns(List<_IncludedItem> items) {
    final usable = items.where((item) => !item.excluded).toList();
    final totalBase = usable.fold<int>(0, (sum, item) => sum + item.baseSpend);
    if (totalBase == 0) return const [];
    final groups = <String, (int, int)>{};
    for (final item in usable) {
      final previous = groups[item.category] ?? (0, 0);
      groups[item.category] = (
        previous.$1 + item.baseSpend,
        previous.$2 + item.currentSpend,
      );
    }
    return groups.entries
        .map((entry) {
          final base = entry.value.$1;
          final current = entry.value.$2;
          return CategoryBreakdownEntity(
            category: entry.key,
            personalWeight: base / totalBase * 100,
            officialWeight: 0,
            inflationRate: (current / base - 1) * 100,
          );
        })
        .toList(growable: false);
  }
}

class _IncludedItem {
  const _IncludedItem({
    required this.category,
    required this.baseSpend,
    required this.currentSpend,
    required this.excluded,
  });

  final String category;
  final int baseSpend;
  final int currentSpend;
  final bool excluded;
}
