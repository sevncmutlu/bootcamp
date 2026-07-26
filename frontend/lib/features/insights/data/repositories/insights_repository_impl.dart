import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/insights/domain/entities/forecast_day_entity.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  final AppDatabase database;
  final MakiApiClient apiClient;

  InsightsRepositoryImpl({
    required this.database,
    required this.apiClient,
  });

  @override
  Future<List<ForecastDayEntity>> getForecast() async {
    final expenses = await database.getAllExpenses();
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 55));
    
    final totals = List<double>.filled(56, 0);
    final observedDays = <int>{};
    
    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final day = date.difference(start).inDays;
      if (day >= 0 && day < totals.length) {
        totals[day] += expense.amount;
        observedDays.add(day);
      }
    }
    
    if (observedDays.length < 3) {
      throw const MakiApiException(
        'INSUFFICIENT_DATA',
        'Not enough historical data to generate a forecast.',
      );
    }

    final mean = totals.reduce((left, right) => left + right) / totals.length;
    final scale = mean + 1;
    final relativeIndexes = totals
        .map((amount) => ((amount + 1) / scale) * 100)
        .toList(growable: false);
        
    final reply = await apiClient.forecast(
      relativeIndexes: relativeIndexes,
    );

    return [
      for (var index = 0; index < reply.predictions.length; index++)
        ForecastDayEntity(
          date: DateTime(today.year, today.month, today.day)
              .add(Duration(days: index + 1))
              .toIso8601String()
              .substring(0, 10),
          predictedAmount: ((reply.predictions[index] / 100) * scale - 1)
              .clamp(0, double.infinity),
        ),
    ];
  }

  @override
  Future<InflationDataEntity> getInflation() async {
    // Currently, the logic in inflation_screen just fetches expenses
    // and returns empty data. We will preserve this behavior.
    await database.getAllExpenses();
    return const InflationDataEntity(
      hasPriceBasket: false,
      personalInflation: null,
      officialInflation: null,
      breakdowns: [],
    );
  }
}
