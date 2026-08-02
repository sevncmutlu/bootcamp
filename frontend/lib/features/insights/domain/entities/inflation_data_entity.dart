import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';

class InflationDataEntity {
  final double? personalInflation;
  final double? officialInflation;
  final List<CategoryBreakdownEntity> breakdowns;
  final bool hasPriceBasket;
  final double? coveragePercent;
  final String status;
  final String? basePeriod;
  final String? currentPeriod;

  const InflationDataEntity({
    this.personalInflation,
    this.officialInflation,
    this.breakdowns = const [],
    this.hasPriceBasket = false,
    this.coveragePercent,
    this.status = 'insufficient_data',
    this.basePeriod,
    this.currentPeriod,
  });
}
