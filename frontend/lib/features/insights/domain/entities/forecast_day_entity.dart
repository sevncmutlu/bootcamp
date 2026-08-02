class ForecastDayEntity {
  final String date;
  final double predictedAmount;
  final String source;
  final String confidence;
  final int observedDays;
  final String? fallbackReason;

  const ForecastDayEntity({
    required this.date,
    required this.predictedAmount,
    this.source = 'local_baseline',
    this.confidence = 'low',
    this.observedDays = 0,
    this.fallbackReason,
  });
}
