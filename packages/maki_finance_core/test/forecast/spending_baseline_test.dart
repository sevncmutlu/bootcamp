import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  test('aynı hafta gününün medyanını kullanır', () {
    final history = <DailySpend>[
      DailySpend(date: DateTime(2026, 7, 6), amountMinor: 1000, observed: true),
      DailySpend(
        date: DateTime(2026, 7, 13),
        amountMinor: 3000,
        observed: true,
      ),
      DailySpend(
        date: DateTime(2026, 7, 14),
        amountMinor: 9000,
        observed: true,
      ),
    ];

    final result = SpendingBaseline.forecast(
      history: history,
      firstForecastDay: DateTime(2026, 7, 20),
      horizon: 1,
    );

    expect(result.predictions.single.amountMinor, 2000);
    expect(result.predictions.single.method, 'weekday_median');
    expect(result.confidence, SpendingConfidence.low);
  });

  test('aynı gün örneği azsa bütün gözlemlerin medyanına düşer', () {
    final result = SpendingBaseline.forecast(
      history: [
        DailySpend(
          date: DateTime(2026, 7, 6),
          amountMinor: 1000,
          observed: true,
        ),
        DailySpend(
          date: DateTime(2026, 7, 7),
          amountMinor: 3000,
          observed: true,
        ),
        DailySpend(
          date: DateTime(2026, 7, 8),
          amountMinor: 9000,
          observed: true,
        ),
      ],
      firstForecastDay: DateTime(2026, 7, 20),
      horizon: 1,
    );

    expect(result.predictions.single.amountMinor, 3000);
    expect(result.predictions.single.method, 'overall_median');
  });

  test('üçten az gözlemle tahmin üretmez', () {
    expect(
      () => SpendingBaseline.forecast(
        history: [
          DailySpend(
            date: DateTime(2026, 7, 6),
            amountMinor: 1000,
            observed: true,
          ),
          DailySpend(
            date: DateTime(2026, 7, 7),
            amountMinor: 3000,
            observed: true,
          ),
        ],
        firstForecastDay: DateTime(2026, 7, 20),
      ),
      throwsArgumentError,
    );
  });
}
