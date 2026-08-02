import 'dart:math' as math;

enum ContributionConfidence { insufficient, low, medium, high }

final class WeeklyCashflow {
  const WeeklyCashflow({
    required this.adjustedNet,
    required this.transactionCount,
    required this.hasIncome,
  });

  /// Olağandışı kullanıcı-onaylı hareketler ayrıldıktan ve aylık zorunlu giderler
  /// haftalığa dağıtıldıktan sonraki net nakit akışı.
  final double adjustedNet;
  final int transactionCount;
  final bool hasIncome;
}

final class ContributionRecommendation {
  const ContributionRecommendation({
    required this.minimum,
    required this.maximum,
    required this.confidence,
    required this.usedWeeks,
    required this.volatilityCoefficient,
  });

  final double? minimum;
  final double? maximum;
  final ContributionConfidence confidence;
  final int usedWeeks;
  final double? volatilityCoefficient;

  bool get hasAmount => minimum != null && maximum != null;
}

abstract final class ContributionAdvisor {
  static ContributionRecommendation recommend(List<WeeklyCashflow> weeks) {
    final used = weeks.length > 8 ? weeks.sublist(weeks.length - 8) : weeks;
    final incomeWeeks = used.where((week) => week.hasIncome).length;
    final transactionCount = used.fold<int>(
      0,
      (sum, week) => sum + week.transactionCount,
    );
    if (used.length < 4 || incomeWeeks < 3 || transactionCount < 12) {
      return ContributionRecommendation(
        minimum: null,
        maximum: null,
        confidence: ContributionConfidence.insufficient,
        usedWeeks: used.length,
        volatilityCoefficient: null,
      );
    }

    final weighted = <({double value, double weight})>[];
    for (var index = 0; index < used.length; index++) {
      final recent = index >= used.length - 4;
      weighted.add((value: used[index].adjustedNet, weight: recent ? 2 : 1));
    }
    final capacity = _weightedQuantile(weighted, 0.25);
    final volatility = _coefficientOfVariation(
      used.map((week) => week.adjustedNet).toList(growable: false),
    );
    final confidence = _confidence(used, incomeWeeks, transactionCount);
    if (capacity <= 0) {
      return ContributionRecommendation(
        minimum: null,
        maximum: null,
        confidence: confidence,
        usedWeeks: used.length,
        volatilityCoefficient: volatility,
      );
    }
    final upperRate = volatility != null && volatility > 0.35 ? 0.20 : 0.30;
    return ContributionRecommendation(
      minimum: _roundDownMeaningfully(capacity * 0.15),
      maximum: _roundDownMeaningfully(capacity * upperRate),
      confidence: confidence,
      usedWeeks: used.length,
      volatilityCoefficient: volatility,
    );
  }

  static ContributionConfidence _confidence(
    List<WeeklyCashflow> weeks,
    int incomeWeeks,
    int transactionCount,
  ) {
    if (weeks.length >= 8 &&
        incomeWeeks / weeks.length >= 0.75 &&
        transactionCount >= 30) {
      return ContributionConfidence.high;
    }
    if (weeks.length >= 4) return ContributionConfidence.medium;
    return ContributionConfidence.low;
  }

  static double _weightedQuantile(
    List<({double value, double weight})> values,
    double quantile,
  ) {
    final sorted = [...values]..sort((a, b) => a.value.compareTo(b.value));
    final totalWeight = sorted.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final threshold = totalWeight * quantile;
    var cumulative = 0.0;
    for (final item in sorted) {
      cumulative += item.weight;
      if (cumulative >= threshold) return item.value;
    }
    return sorted.last.value;
  }

  static double? _coefficientOfVariation(List<double> values) {
    if (values.isEmpty) return null;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= 0) return null;
    final variance =
        values.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2),
        ) /
        values.length;
    return math.sqrt(variance) / mean;
  }

  static double _roundDownMeaningfully(double value) {
    if (value < 10) return value.floorToDouble();
    if (value < 100) return (value / 5).floor() * 5;
    if (value < 1000) return (value / 10).floor() * 10;
    return (value / 50).floor() * 50;
  }
}
