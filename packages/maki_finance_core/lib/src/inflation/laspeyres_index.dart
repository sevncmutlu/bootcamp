import '../money/money.dart';
import '../money/rounding.dart';
import 'basket_item.dart';
import 'inflation_result.dart';

/// Sabit baz miktarlarıyla kişisel fiyat endeksi hesaplar.
abstract final class LaspeyresIndex {
  static const _fullShareBasisPoints = 10000;
  static const _minimumCoverageBasisPoints = 7000;

  static InflationResult calculate(
    List<BasketItem> items, {
    RoundingMode roundingMode = RoundingMode.halfEven,
  }) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'Sepet boş olamaz.');
    }

    _validateBasket(items);
    var totalBaseSpend = 0;
    var includedBaseSpend = 0;
    var includedCurrentSpend = 0;
    var matchedBaseSpend = 0;
    final categoryTotals = <String, _CategoryTotals>{};

    for (final item in items) {
      final baseSpend = item.baseUnitPrice.minorUnits * item.baseQuantity;
      final currentSpend = item.currentUnitPrice.minorUnits * item.baseQuantity;
      totalBaseSpend += baseSpend;
      if (item.match == BasketMatch.excluded) {
        continue;
      }

      includedBaseSpend += baseSpend;
      includedCurrentSpend += currentSpend;
      if (item.match == BasketMatch.matched) {
        matchedBaseSpend += baseSpend;
      }
      categoryTotals.update(
        item.categoryId,
        (totals) =>
            totals.add(baseSpend: baseSpend, currentSpend: currentSpend),
        ifAbsent: () =>
            _CategoryTotals(baseSpend: baseSpend, currentSpend: currentSpend),
      );
    }

    final coverage = divideAndRound(
      includedBaseSpend * _fullShareBasisPoints,
      totalBaseSpend,
      roundingMode,
    );
    final matchedShare = divideAndRound(
      matchedBaseSpend * _fullShareBasisPoints,
      totalBaseSpend,
      roundingMode,
    );
    final proxyShare = coverage - matchedShare;
    final excludedShare = _fullShareBasisPoints - coverage;
    final index = includedBaseSpend == 0
        ? _fullShareBasisPoints
        : divideAndRound(
            includedCurrentSpend * _fullShareBasisPoints,
            includedBaseSpend,
            roundingMode,
          );

    return InflationResult(
      status: coverage < _minimumCoverageBasisPoints
          ? InflationStatus.insufficientCoverage
          : InflationStatus.normal,
      indexBasisPoints: index,
      coverageBasisPoints: coverage,
      matchedShareBasisPoints: matchedShare,
      proxyShareBasisPoints: proxyShare,
      excludedShareBasisPoints: excludedShare,
      categoryContributions: _categoryContributions(
        categoryTotals: categoryTotals,
        includedBaseSpend: includedBaseSpend,
        targetBasisPoints: index - _fullShareBasisPoints,
        roundingMode: roundingMode,
      ),
    );
  }

  static void _validateBasket(List<BasketItem> items) {
    final currency = items.first.baseUnitPrice.currency;
    final ids = <String>{};
    for (final item in items) {
      if (!ids.add(item.id)) {
        throw ArgumentError.value(
          item.id,
          'items',
          'Sepet kalemi kimlikleri benzersiz olmalıdır.',
        );
      }
      if (item.baseUnitPrice.currency != currency) {
        throw CurrencyMismatch(currency, item.baseUnitPrice.currency);
      }
    }
  }

  static List<CategoryContribution> _categoryContributions({
    required Map<String, _CategoryTotals> categoryTotals,
    required int includedBaseSpend,
    required int targetBasisPoints,
    required RoundingMode roundingMode,
  }) {
    if (categoryTotals.isEmpty || includedBaseSpend == 0) {
      return const [];
    }

    final entries = categoryTotals.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final contributions = <CategoryContribution>[];
    var calculatedTotal = 0;
    for (final entry in entries) {
      final contribution = divideAndRound(
        (entry.value.currentSpend - entry.value.baseSpend) *
            _fullShareBasisPoints,
        includedBaseSpend,
        roundingMode,
      );
      calculatedTotal += contribution;
      contributions.add(
        CategoryContribution(categoryId: entry.key, basisPoints: contribution),
      );
    }

    final residual = targetBasisPoints - calculatedTotal;
    if (residual == 0) {
      return contributions;
    }

    var adjustmentIndex = 0;
    for (var index = 1; index < entries.length; index++) {
      if (entries[index].value.baseSpend >
          entries[adjustmentIndex].value.baseSpend) {
        adjustmentIndex = index;
      }
    }
    final adjusted = contributions[adjustmentIndex];
    contributions[adjustmentIndex] = CategoryContribution(
      categoryId: adjusted.categoryId,
      basisPoints: adjusted.basisPoints + residual,
    );
    return contributions;
  }
}

final class _CategoryTotals {
  const _CategoryTotals({required this.baseSpend, required this.currentSpend});

  final int baseSpend;
  final int currentSpend;

  _CategoryTotals add({required int baseSpend, required int currentSpend}) =>
      _CategoryTotals(
        baseSpend: this.baseSpend + baseSpend,
        currentSpend: this.currentSpend + currentSpend,
      );
}
