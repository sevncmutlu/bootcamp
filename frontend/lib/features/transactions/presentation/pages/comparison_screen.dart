import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/personalization/goal_route_banner.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/widgets/empty_state.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key, this.primaryGoal = 'track_spending'});

  final String primaryGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: MakiAppBarTitle(title: l10n.comparisonTitle),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: l10n.comparisonPrivacyTitle,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.comparisonPrivacyTitle),
                content: Text(l10n.comparisonPrivacyBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.closeButton),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.phonelink_lock_outlined),
          ),
        ],
      ),
      body: MakiBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: GoalRouteBanner(
                primaryGoal: primaryGoal,
                surface: GoalRouteSurface.comparison,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.expenses.isEmpty && state.incomes.isEmpty) {
                    return EmptyState(
                      title: l10n.comparisonEmptyTitle,
                      message: l10n.comparisonEmptyBody,
                    );
                  }
                  return _ComparisonBody(state: state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({required this.state});

  final TransactionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final currentStart = DateTime(now.year, now.month);
    final nextStart = DateTime(now.year, now.month + 1);
    final previousStart = DateTime(now.year, now.month - 1);
    final locale = Localizations.localeOf(context).toString();

    final currentIncome = state.incomes
        .where((item) => _isBetween(item.date, currentStart, nextStart))
        .fold<double>(0, (sum, item) => sum + item.amount);
    final previousIncome = state.incomes
        .where((item) => _isBetween(item.date, previousStart, currentStart))
        .fold<double>(0, (sum, item) => sum + item.amount);
    final currentExpenses = state.expenses
        .where((item) => _isBetween(item.date, currentStart, nextStart))
        .toList(growable: false);
    final previousExpenses = state.expenses
        .where((item) => _isBetween(item.date, previousStart, currentStart))
        .fold<double>(0, (sum, item) => sum + item.amount);
    final currentExpenseTotal = currentExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final currentNet = currentIncome - currentExpenseTotal;
    final previousNet = previousIncome - previousExpenses;
    final monthFormat = DateFormat.yMMMM(locale);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.comparisonPeriodLabel(
            monthFormat.format(previousStart),
            monthFormat.format(currentStart),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _NetComparisonCard(currentNet: currentNet, previousNet: previousNet),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _MetricCard(
                label: l10n.incomeLabel,
                value: currentIncome,
                previous: previousIncome,
                color: ForestColors.income,
                icon: Icons.south_west_rounded,
              ),
              _MetricCard(
                label: l10n.expenseLabel,
                value: currentExpenseTotal,
                previous: previousExpenses,
                color: ForestColors.expense,
                icon: Icons.north_east_rounded,
                inverseTrend: true,
              ),
            ];
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  cards.first,
                  const SizedBox(height: AppSpacing.md),
                  cards.last,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: cards.first),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards.last),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.comparisonCategoryTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.comparisonCategoryBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        _CategoryBreakdown(expenses: currentExpenses),
      ],
    );
  }

  bool _isBetween(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);
}

class _NetComparisonCard extends StatelessWidget {
  const _NetComparisonCard({
    required this.currentNet,
    required this.previousNet,
  });

  final double currentNet;
  final double previousNet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = theme.makiPalette;
    final positive = currentNet >= 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(palette),
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.soft(theme.brightness, theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, color: Colors.white70),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.netBalanceLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            formatTL(currentNet, context: context),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _deltaLabel(context, currentNet, previousNet),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: positive
                  ? const Color(0xFFDDF9E8)
                  : const Color(0xFFFFE0D8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.previous,
    required this.color,
    required this.icon,
    this.inverseTrend = false,
  });

  final String label;
  final double value;
  final double previous;
  final Color color;
  final IconData icon;
  final bool inverseTrend;

  @override
  Widget build(BuildContext context) {
    final isUp = value >= previous;
    final isGood = inverseTrend ? !isUp : isUp;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.md),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatTL(value, context: context),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: isGood ? ForestColors.income : ForestColors.expense,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _deltaLabel(context, value, previous),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.expenses});

  final List<ExpenseEntity> expenses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (expenses.isEmpty) {
      return Text(l10n.comparisonNoCurrentExpenses);
    }

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visibleEntries = entries.take(5).toList(growable: false);
    final maximum = visibleEntries.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (final (index, entry) in visibleEntries.indexed) ...[
              Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    formatTL(entry.value, context: context),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: maximum == 0 ? 0 : entry.value / maximum,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              if (index != visibleEntries.length - 1)
                const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

String _deltaLabel(BuildContext context, double current, double previous) {
  final l10n = AppLocalizations.of(context)!;
  if (previous == 0) {
    return current == 0 ? l10n.comparisonNoChange : l10n.comparisonFirstPeriod;
  }
  final percent = ((current - previous) / previous.abs()) * 100;
  return l10n.comparisonDelta(
    Money.formatPercent(
      percent,
      locale: Localizations.localeOf(context).toString(),
    ),
  );
}
