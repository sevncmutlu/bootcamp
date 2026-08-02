import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

WeeklyCashflow week(double net, {int transactions = 5, bool income = true}) =>
    WeeklyCashflow(
      adjustedNet: net,
      transactionCount: transactions,
      hasIncome: income,
    );

void main() {
  test('requires enough weeks, income weeks and transactions', () {
    final result = ContributionAdvisor.recommend([
      week(1000),
      week(900),
      week(800),
    ]);

    expect(result.hasAmount, isFalse);
    expect(result.confidence, ContributionConfidence.insufficient);
  });

  test('returns a range and reduces upper edge for volatile cashflow', () {
    final result = ContributionAdvisor.recommend([
      week(100),
      week(2000),
      week(200),
      week(1800),
      week(300),
      week(1700),
      week(400),
      week(1600),
    ]);

    expect(result.confidence, ContributionConfidence.high);
    expect(result.minimum, isNotNull);
    expect(result.maximum, isNotNull);
    expect(result.volatilityCoefficient, greaterThan(0.35));
    expect(result.maximum! / result.minimum!, lessThanOrEqualTo(1.5));
  });

  test('negative cautious capacity never promises a contribution', () {
    final result = ContributionAdvisor.recommend([
      week(-100),
      week(-50),
      week(40),
      week(60),
    ]);

    expect(result.hasAmount, isFalse);
    expect(result.confidence, ContributionConfidence.medium);
  });
}
