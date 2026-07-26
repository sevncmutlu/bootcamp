class CoachSourceEntity {
  final String institution;
  final String seriesId;
  final String period;
  final String value;
  final String unit;
  final Uri sourceUrl;

  const CoachSourceEntity({
    required this.institution,
    required this.seriesId,
    required this.period,
    required this.value,
    required this.unit,
    required this.sourceUrl,
  });
}
