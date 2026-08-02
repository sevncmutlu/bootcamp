import 'dart:math';

import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/database/money_minor_converter.dart';
import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';

/// Produces a privacy-safe monthly spending comparison from local records.
///
/// The personal percentage is spending change, not an official price index.
/// Debt payments are deliberately excluded from consumption change and shown
/// separately in the financial-pressure score.
class PersonalFinanceInsightService {
  PersonalFinanceInsightService(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;
  static const _money = MoneyMinorConverter();

  Future<InflationDataEntity> calculate() async {
    final expenses = await _database.getAllExpenses();
    final incomes = await _database.getAllIncomes();
    final official =
        await (_database.select(_database.officialInflationSnapshots)
              ..orderBy([(row) => OrderingTerm.desc(row.period)])
              ..limit(1))
            .getSingleOrNull();

    final now = _clock();
    final currentEnd = DateTime(now.year, now.month, now.day + 1);
    final currentStart = currentEnd.subtract(const Duration(days: 30));
    final previousStart = currentStart.subtract(const Duration(days: 30));

    final currentExpenses = expenses
        .where((item) => _inRange(item.date, currentStart, currentEnd))
        .toList(growable: false);
    final previousExpenses = expenses
        .where((item) => _inRange(item.date, previousStart, currentStart))
        .toList(growable: false);
    final currentIncomes = incomes.where(
      (item) => _inRange(item.date, currentStart, currentEnd),
    );

    final currentDebt = currentExpenses.where(_isDebtPayment).toList();
    final currentConsumption = currentExpenses
        .where((item) => !_isDebtPayment(item))
        .toList(growable: false);
    final previousConsumption = previousExpenses
        .where((item) => !_isDebtPayment(item))
        .toList(growable: false);

    final currentConsumptionMinor = _expenseTotal(currentConsumption);
    final previousConsumptionMinor = _expenseTotal(previousConsumption);
    final currentExpenseMinor = _expenseTotal(currentExpenses);
    final debtMinor = _expenseTotal(currentDebt);
    final incomeMinor = currentIncomes.fold<int>(
      0,
      (sum, item) => sum + _money.toSql(item.amount),
    );

    final hasComparison =
        currentConsumption.length >= 3 &&
        previousConsumption.length >= 3 &&
        previousConsumptionMinor > 0;
    final spendingChange = hasComparison
        ? ((currentConsumptionMinor / previousConsumptionMinor) - 1) * 100
        : null;
    final pressure = incomeMinor > 0
        ? _financialPressure(
            expenses: currentExpenseMinor,
            income: incomeMinor,
            debt: debtMinor,
            spendingChange: spendingChange,
          )
        : null;

    return InflationDataEntity(
      personalInflation: spendingChange,
      officialInflation: official == null
          ? null
          : official.rateBasisPoints / 100,
      breakdowns: _breakdowns(
        current: currentConsumption,
        previous: previousConsumption,
      ),
      hasComparisonData: hasComparison,
      coveragePercent: min(
        100,
        min(currentConsumption.length, previousConsumption.length) / 3 * 100,
      ).toDouble(),
      currentIncome: incomeMinor / 100,
      currentExpenses: currentExpenseMinor / 100,
      debtPayments: debtMinor / 100,
      netCashFlow: (incomeMinor - currentExpenseMinor) / 100,
      financialPressure: pressure,
      currentTransactionCount: currentConsumption.length,
      previousTransactionCount: previousConsumption.length,
      status: incomeMinor <= 0
          ? 'missing_income'
          : hasComparison
          ? 'ready'
          : 'insufficient_history',
      basePeriod: _dateLabel(previousStart),
      currentPeriod: _dateLabel(currentEnd.subtract(const Duration(days: 1))),
    );
  }

  static bool _inRange(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);

  static int _expenseTotal(Iterable<Expense> values) =>
      values.fold<int>(0, (sum, item) => sum + _money.toSql(item.amount));

  static double _financialPressure({
    required int expenses,
    required int income,
    required int debt,
    required double? spendingChange,
  }) {
    final expenseLoad = (expenses / income / 1.2).clamp(0.0, 1.0) * 60;
    final debtLoad = (debt / income / 0.4).clamp(0.0, 1.0) * 25;
    final trendLoad = spendingChange == null
        ? 0.0
        : (spendingChange / 25).clamp(0.0, 1.0) * 15;
    return (expenseLoad + debtLoad + trendLoad).clamp(0.0, 100.0);
  }

  static bool _isDebtPayment(Expense expense) {
    final searchable = _normalize(
      '${expense.title} ${expense.category} ${expense.notes ?? ''}',
    );
    return const [
      'borc',
      'kredi',
      'kredi karti',
      'taksit',
      'loan',
      'debt',
    ].any(searchable.contains);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');

  static List<CategoryBreakdownEntity> _breakdowns({
    required List<Expense> current,
    required List<Expense> previous,
  }) {
    final currentByCategory = <String, int>{};
    final previousByCategory = <String, int>{};
    for (final item in current) {
      currentByCategory.update(
        item.category,
        (value) => value + _money.toSql(item.amount),
        ifAbsent: () => _money.toSql(item.amount),
      );
    }
    for (final item in previous) {
      previousByCategory.update(
        item.category,
        (value) => value + _money.toSql(item.amount),
        ifAbsent: () => _money.toSql(item.amount),
      );
    }
    final currentTotal = currentByCategory.values.fold<int>(0, (a, b) => a + b);
    final previousTotal = previousByCategory.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    if (currentTotal <= 0) return const [];

    final result = currentByCategory.entries.map((entry) {
      final previousValue = previousByCategory[entry.key] ?? 0;
      return CategoryBreakdownEntity(
        category: entry.key,
        personalWeight: entry.value / currentTotal * 100,
        officialWeight: previousTotal <= 0
            ? 0
            : previousValue / previousTotal * 100,
        inflationRate: previousValue <= 0
            ? 0
            : (entry.value / previousValue - 1) * 100,
        hasComparison: previousValue > 0,
      );
    }).toList();
    result.sort(
      (left, right) => right.personalWeight.compareTo(left.personalWeight),
    );
    return result;
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
