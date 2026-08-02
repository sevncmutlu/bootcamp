import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/insights/domain/entities/forecast_day_entity.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';
import 'package:maki_app/features/insights/data/services/price_basket_service.dart';
import 'package:maki_app/features/insights/data/services/personal_finance_insight_service.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/database/money_minor_converter.dart';
import 'package:maki_finance_core/maki_finance_core.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  final AppDatabase database;
  final MakiApiClient apiClient;

  InsightsRepositoryImpl({
    required this.database,
    required this.apiClient,
    PriceBasketService? priceBasketService,
    PersonalFinanceInsightService? personalFinanceInsightService,
    AppEnvironment? environment,
  }) : priceBasketService = priceBasketService ?? PriceBasketService(database),
       personalFinanceInsightService =
           personalFinanceInsightService ??
           PersonalFinanceInsightService(database),
       environment = environment ?? AppEnvironment.current;

  final PriceBasketService priceBasketService;
  final PersonalFinanceInsightService personalFinanceInsightService;
  final AppEnvironment environment;

  @override
  Future<List<ForecastDayEntity>> getForecast() async {
    final expenses = await database.getAllExpenses();
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 55));

    final totals = List<int>.filled(56, 0);
    final observedDays = <int>{};

    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final day = date.difference(start).inDays;
      if (day >= 0 && day < totals.length) {
        totals[day] += const MoneyMinorConverter().toSql(expense.amount);
        observedDays.add(day);
      }
    }

    if (observedDays.length < 3) {
      throw const MakiApiException(
        'INSUFFICIENT_DATA',
        'Not enough historical data to generate a forecast.',
      );
    }

    final firstForecastDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 1));
    final baseline = SpendingBaseline.forecast(
      history: [
        for (var day = 0; day < totals.length; day++)
          DailySpend(
            date: start.add(Duration(days: day)),
            amountMinor: totals[day],
            observed: observedDays.contains(day),
          ),
      ],
      firstForecastDay: firstForecastDay,
    );

    if (observedDays.length < 14 || environment.isWebPreview) {
      return _localForecast(baseline);
    }

    final meanMinor =
        totals.reduce((left, right) => left + right) / totals.length;
    final scaleMinor = meanMinor + 1;
    final relativeIndexes = totals
        .map((amount) => ((amount + 1) / scaleMinor) * 100)
        .toList(growable: false);
    try {
      final reply = await apiClient.forecast(relativeIndexes: relativeIndexes);
      return [
        for (var index = 0; index < reply.predictions.length; index++)
          ForecastDayEntity(
            date: firstForecastDay
                .add(Duration(days: index))
                .toIso8601String()
                .substring(0, 10),
            predictedAmount:
                (((reply.predictions[index] / 100) * scaleMinor - 1).clamp(
                  0,
                  double.infinity,
                ) /
                100),
            source: 'backend_model',
            confidence: _confidenceName(baseline.confidence),
            observedDays: baseline.observedDays,
          ),
      ];
    } on Object {
      return _localForecast(baseline, fallbackReason: 'backend_unavailable');
    }
  }

  List<ForecastDayEntity> _localForecast(
    SpendingBaselineResult baseline, {
    String? fallbackReason,
  }) => [
    for (final prediction in baseline.predictions)
      ForecastDayEntity(
        date: prediction.date.toIso8601String().substring(0, 10),
        predictedAmount: prediction.amountMinor / 100,
        source: 'local_baseline',
        confidence: _confidenceName(baseline.confidence),
        observedDays: baseline.observedDays,
        fallbackReason: fallbackReason,
      ),
  ];

  static String _confidenceName(SpendingConfidence confidence) =>
      switch (confidence) {
        SpendingConfidence.low => 'low',
        SpendingConfidence.medium => 'medium',
        SpendingConfidence.high => 'high',
      };

  @override
  Future<InflationDataEntity> getInflation() async {
    if (!environment.isWebPreview) {
      try {
        final official = await apiClient.officialInflationLatest();
        await priceBasketService.storeOfficial(official);
      } on Object {
        // Yerel fiyat sepeti çevrimdışıyken de hesaplanır. Daha önce güvenle
        // kaydedilmiş resmî snapshot varsa aşağıdaki hesap onu kullanır.
      }
    }
    return personalFinanceInsightService.calculate();
  }
}
