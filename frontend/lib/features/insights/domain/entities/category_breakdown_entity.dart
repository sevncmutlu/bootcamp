class CategoryBreakdownEntity {
  final String category;
  final double personalWeight;
  final double officialWeight;
  final double inflationRate;
  final bool hasComparison;

  const CategoryBreakdownEntity({
    required this.category,
    required this.personalWeight,
    required this.officialWeight,
    required this.inflationRate,
    this.hasComparison = true,
  });
}
