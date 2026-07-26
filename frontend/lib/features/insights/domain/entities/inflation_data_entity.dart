import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';

class InflationDataEntity {
  final double? personalInflation;
  final double? officialInflation;
  final List<CategoryBreakdownEntity> breakdowns;
  final bool hasPriceBasket;

  const InflationDataEntity({
    this.personalInflation,
    this.officialInflation,
    this.breakdowns = const [],
    this.hasPriceBasket = false,
  });
}
