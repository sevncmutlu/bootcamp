import '../money/rounding.dart';

enum SpendingConfidence { low, medium, high }

final class DailySpend {
  const DailySpend({
    required this.date,
    required this.amountMinor,
    required this.observed,
  });

  final DateTime date;
  final int amountMinor;
  final bool observed;
}

final class SpendingPrediction {
  const SpendingPrediction({
    required this.date,
    required this.amountMinor,
    required this.method,
  });

  final DateTime date;
  final int amountMinor;
  final String method;
}

final class SpendingBaselineResult {
  const SpendingBaselineResult({
    required this.predictions,
    required this.observedDays,
    required this.confidence,
    required this.medianAbsoluteDeviationMinor,
  });

  final List<SpendingPrediction> predictions;
  final int observedDays;
  final SpendingConfidence confidence;
  final int medianAbsoluteDeviationMinor;
}

/// Deterministic, device-local spending baseline.
///
/// It uses a weekday median when at least two matching weekdays exist and
/// otherwise falls back to the median of all observed days. No network or
/// randomness is involved.
abstract final class SpendingBaseline {
  static SpendingBaselineResult forecast({
    required List<DailySpend> history,
    required DateTime firstForecastDay,
    int horizon = 7,
  }) {
    if (horizon <= 0) {
      throw ArgumentError.value(horizon, 'horizon', 'Sıfırdan büyük olmalı.');
    }
    final observed = history.where((day) => day.observed).toList();
    if (observed.length < 3) {
      throw ArgumentError.value(
        observed.length,
        'history',
        'En az üç gözlem günü gerekir.',
      );
    }
    final allValues = observed.map((day) => day.amountMinor).toList();
    final globalMedian = _median(allValues);
    final mad = _median(
      allValues.map((value) => (value - globalMedian).abs()).toList(),
    );
    final predictions = <SpendingPrediction>[];
    for (var offset = 0; offset < horizon; offset++) {
      final date = _dateOnly(firstForecastDay.add(Duration(days: offset)));
      final weekdayValues = observed
          .where((day) => day.date.weekday == date.weekday)
          .map((day) => day.amountMinor)
          .toList();
      final useWeekday = weekdayValues.length >= 2;
      predictions.add(
        SpendingPrediction(
          date: date,
          amountMinor: useWeekday ? _median(weekdayValues) : globalMedian,
          method: useWeekday ? 'weekday_median' : 'overall_median',
        ),
      );
    }
    return SpendingBaselineResult(
      predictions: List.unmodifiable(predictions),
      observedDays: observed.length,
      confidence: _confidence(
        observedDays: observed.length,
        median: globalMedian,
        mad: mad,
      ),
      medianAbsoluteDeviationMinor: mad,
    );
  }

  static SpendingConfidence _confidence({
    required int observedDays,
    required int median,
    required int mad,
  }) {
    if (observedDays < 14) return SpendingConfidence.low;
    if (median <= 0) return SpendingConfidence.low;
    final ratioBasisPoints = divideAndRound(
      mad * 10000,
      median,
      RoundingMode.halfEven,
    );
    if (ratioBasisPoints <= 2500 && observedDays >= 28) {
      return SpendingConfidence.high;
    }
    if (ratioBasisPoints <= 6000) return SpendingConfidence.medium;
    return SpendingConfidence.low;
  }

  static int _median(List<int> source) {
    if (source.isEmpty) throw ArgumentError.value(source, 'source');
    final values = [...source]..sort();
    final middle = values.length ~/ 2;
    if (values.length.isOdd) return values[middle];
    return divideAndRound(
      values[middle - 1] + values[middle],
      2,
      RoundingMode.halfEven,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
