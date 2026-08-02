import 'package:flutter/material.dart';
import 'package:maki_app/core/personalization/goal_experience.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
part 'personalized_finance_calendar.dart';
part 'personalized_finance_hero.dart';
part 'personalized_finance_savings.dart';
part 'personalized_finance_goal.dart';

class FinanceDaySummary {
  const FinanceDaySummary({
    required this.date,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  final DateTime date;
  final double income;
  final double expense;
  final int transactionCount;

  double get net => income - expense;
}

class PersonalizedFinanceOverview extends StatelessWidget {
  const PersonalizedFinanceOverview({
    super.key,
    required this.primaryGoal,
    required this.expenses,
    required this.incomes,
    required this.selectedDate,
    required this.onDateSelected,
    this.onOpenCalendar,
    this.today,
    this.streakDays = 0,
    this.savingsGoal,
    this.onOpenSavingsGoal,
  });

  final String primaryGoal;
  final List<ExpenseEntity> expenses;
  final List<IncomeEntity> incomes;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onOpenCalendar;
  final DateTime? today;
  final int streakDays;
  final SavingsGoalView? savingsGoal;
  final VoidCallback? onOpenSavingsGoal;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static FinanceDaySummary summarizeDay(
    DateTime date,
    List<ExpenseEntity> expenses,
    List<IncomeEntity> incomes,
  ) {
    final dayExpenses = expenses.where((item) => sameDay(item.date, date));
    final dayIncomes = incomes.where((item) => sameDay(item.date, date));
    return FinanceDaySummary(
      date: dateOnly(date),
      income: dayIncomes.fold(0, (sum, item) => sum + item.amount),
      expense: dayExpenses.fold(0, (sum, item) => sum + item.amount),
      transactionCount: dayExpenses.length + dayIncomes.length,
    );
  }

  List<DateTime> _weekDates() {
    final anchor = dateOnly(today ?? DateTime.now());
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final profile = GoalExperience.forKey(primaryGoal);
    final week = _weekDates();
    final summaries = week
        .map((date) => summarizeDay(date, expenses, incomes))
        .toList();
    final selected = summarizeDay(selectedDate, expenses, incomes);
    final weeklyIncome = summaries.fold<double>(
      0,
      (sum, item) => sum + item.income,
    );
    final weeklyExpense = summaries.fold<double>(
      0,
      (sum, item) => sum + item.expense,
    );
    final progress = switch (profile.key) {
      'track_spending' =>
        summaries.where((item) => item.transactionCount > 0).length / 3,
      'save_goal' =>
        weeklyIncome <= 0
            ? 0.0
            : ((weeklyIncome - weeklyExpense) / weeklyIncome).clamp(0.0, 1.0),
      'pay_debt' => expenses.isEmpty ? 0.0 : 0.35,
      'learn_invest' => incomes.isEmpty && expenses.isEmpty ? 0.0 : 0.25,
      _ => 0.0,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 720;
        final calendar = _FinanceWeekCalendar(
          dates: week,
          summaries: summaries,
          selectedDate: selectedDate,
          today: dateOnly(today ?? DateTime.now()),
          onDateSelected: onDateSelected,
          onOpenCalendar: onOpenCalendar,
          streakDays: streakDays,
        );
        final dashboard = _FinanceHeroPager(
          financeCard: _GoalDashboardCard(
            profile: profile,
            locale: locale,
            summary: selected,
            progress: progress.clamp(0.0, 1.0),
          ),
          savingsGoal: savingsGoal,
          onOpenSavingsGoal: onOpenSavingsGoal,
        );

        if (useColumns) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 11, child: dashboard),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 9, child: calendar),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            calendar,
            const SizedBox(height: AppSpacing.md),
            dashboard,
          ],
        );
      },
    );
  }
}
