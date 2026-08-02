import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/core/widgets/money_text.dart';
import 'package:maki_app/features/gamification/data/services/living_forest_service.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/presentation/widgets/personalized_finance_overview.dart';

class FinanceCalendarScreen extends StatefulWidget {
  const FinanceCalendarScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<FinanceCalendarScreen> createState() => _FinanceCalendarScreenState();
}

class _FinanceCalendarScreenState extends State<FinanceCalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  LivingForestSnapshot? _forest;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _visibleMonth = DateTime(initial.year, initial.month);
    _selectedDay = DateTime(initial.year, initial.month, initial.day);
    _loadForest();
  }

  Future<void> _loadForest() async {
    final snapshot = await di.sl<LivingForestService>().load();
    if (mounted) setState(() => _forest = snapshot);
  }

  Future<void> _completeReview() async {
    await di.sl<LivingForestService>().completeDailyReview(_selectedDay);
    await _loadForest();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bugünün finans kontrolü ormana işlendi.'),
        ),
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const MakiAppBarTitle(title: 'Finans Takvimi'),
        actions: [
          IconButton(
            tooltip: 'Bugüne dön',
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _visibleMonth = DateTime(today.year, today.month);
                _selectedDay = DateTime(today.year, today.month, today.day);
              });
            },
            icon: const Icon(Icons.today_rounded),
          ),
        ],
      ),
      body: MakiBackground(
        maxContentWidth: 980,
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            final summary = PersonalizedFinanceOverview.summarizeDay(
              _selectedDay,
              state.expenses,
              state.incomes,
            );
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Önceki ay',
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Expanded(
                              child: Text(
                                _monthTitle(_visibleMonth),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'MakiDisplay',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sonraki ay',
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Row(
                          children: [
                            _Weekday('Pzt'),
                            _Weekday('Sal'),
                            _Weekday('Çar'),
                            _Weekday('Per'),
                            _Weekday('Cum'),
                            _Weekday('Cmt'),
                            _Weekday('Paz'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _MonthGrid(
                          month: _visibleMonth,
                          selectedDay: _selectedDay,
                          completedDays: _forest?.completedDays ?? const {},
                          expenses: state.expenses,
                          incomes: state.incomes,
                          onSelected: (day) =>
                              setState(() => _selectedDay = day),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DayJournalCard(
                  date: _selectedDay,
                  summary: summary,
                  completed:
                      _forest?.completedDays.any(
                        (day) => PersonalizedFinanceOverview.sameDay(
                          day,
                          _selectedDay,
                        ),
                      ) ??
                      false,
                  onReview: _completeReview,
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_forest?.currentStreak ?? 0} günlük bakım serisi',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'En iyi seri ${_forest?.bestStreak ?? 0} gün · Bu hafta ${_forest?.completedDaysLast7 ?? 0}/7 gün',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _monthTitle(DateTime date) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.completedDays,
    required this.expenses,
    required this.incomes,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Set<DateTime> completedDays;
  final List<ExpenseEntity> expenses;
  final List<IncomeEntity> incomes;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cellCount = ((leading + days + 6) ~/ 7) * 7;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.88,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > days) return const SizedBox.shrink();
        final day = DateTime(month.year, month.month, dayNumber);
        final selected = PersonalizedFinanceOverview.sameDay(day, selectedDay);
        final summary = PersonalizedFinanceOverview.summarizeDay(
          day,
          expenses,
          incomes,
        );
        final completed = completedDays.any(
          (entry) => PersonalizedFinanceOverview.sameDay(entry, day),
        );
        final theme = Theme.of(context);
        return Semantics(
          button: true,
          selected: selected,
          label: '$dayNumber, ${summary.transactionCount} işlem',
          child: InkWell(
            onTap: () => onSelected(day),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : completed
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? theme.colorScheme.onPrimary : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(
                        summary.income > 0,
                        selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 3),
                      _dot(
                        summary.expense > 0,
                        selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dot(bool visible, Color color) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: visible ? color : Colors.transparent,
    ),
  );
}

class _DayJournalCard extends StatelessWidget {
  const _DayJournalCard({
    required this.date,
    required this.summary,
    required this.completed,
    required this.onReview,
  });

  final DateTime date;
  final FinanceDaySummary summary;
  final bool completed;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${date.day}.${date.month}.${date.year} günlüğü',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (completed)
                  const Chip(
                    avatar: Icon(Icons.eco_rounded, size: 16),
                    label: Text('Bakım tamam'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MoneyMetric(
                    'Gelir',
                    summary.income,
                    MoneyKind.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoneyMetric(
                    'Gider',
                    summary.expense,
                    MoneyKind.expense,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoneyMetric('Net', summary.net, MoneyKind.neutral),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: completed ? null : onReview,
              icon: const Icon(Icons.task_alt_rounded),
              label: Text(
                completed ? 'Gün tamamlandı' : 'Günlük kontrolü tamamla',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric(this.label, this.value, this.kind);

  final String label;
  final double value;
  final MoneyKind kind;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 2),
      MoneyText(
        value,
        kind: kind,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ],
  );
}
