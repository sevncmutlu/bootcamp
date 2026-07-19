/// Kişisel enflasyon hesabının güven durumu.
enum InflationStatus { normal, insufficientCoverage }

/// Bir kategorinin toplam endeks değişimine katkısı.
final class CategoryContribution {
  const CategoryContribution({
    required this.categoryId,
    required this.basisPoints,
  });

  final String categoryId;
  final int basisPoints;
}

/// Denetlenebilir Laspeyres endeksi sonucu.
final class InflationResult {
  InflationResult({
    required this.status,
    required this.indexBasisPoints,
    required this.coverageBasisPoints,
    required this.matchedShareBasisPoints,
    required this.proxyShareBasisPoints,
    required this.excludedShareBasisPoints,
    required List<CategoryContribution> categoryContributions,
  }) : categoryContributions = List.unmodifiable(categoryContributions);

  final InflationStatus status;
  final int indexBasisPoints;
  final int coverageBasisPoints;
  final int matchedShareBasisPoints;
  final int proxyShareBasisPoints;
  final int excludedShareBasisPoints;
  final List<CategoryContribution> categoryContributions;
}
