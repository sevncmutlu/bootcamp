import 'package:maki_app/features/insights/domain/entities/forecast_day_entity.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';

abstract class InsightsRepository {
  Future<List<ForecastDayEntity>> getForecast();
  Future<InflationDataEntity> getInflation();
}
