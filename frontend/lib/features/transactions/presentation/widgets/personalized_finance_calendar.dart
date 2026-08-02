part of 'personalized_finance_overview.dart';

class _FinanceWeekCalendar extends StatelessWidget {
  const _FinanceWeekCalendar({
    required this.dates,
    required this.summaries,
    required this.selectedDate,
    required this.today,
    required this.onDateSelected,
    required this.streakDays,
    this.onOpenCalendar,
  });

  final List<DateTime> dates;
  final List<FinanceDaySummary> summaries;
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onOpenCalendar;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    final weekdays = isTurkish
        ? const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      key: const ValueKey('finance-week-calendar'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isTurkish ? 'Bu haftanın akışı' : 'This week\'s flow',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onOpenCalendar != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: const ValueKey('calendar-streak-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 15,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$streakDays',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Tooltip(
                        message: isTurkish
                            ? 'Tam takvimi aç'
                            : 'Open full calendar',
                        child: Semantics(
                          button: true,
                          label: isTurkish
                              ? 'Tam takvimi aç'
                              : 'Open full calendar',
                          child: InkResponse(
                            key: const ValueKey('open-full-calendar'),
                            onTap: onOpenCalendar,
                            radius: 18,
                            child: const Padding(
                              padding: EdgeInsets.all(1),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    isTurkish ? 'Gelir · gider' : 'Income · expense',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: List.generate(dates.length, (index) {
                final date = dates[index];
                final summary = summaries[index];
                final selected = PersonalizedFinanceOverview.sameDay(
                  date,
                  selectedDate,
                );
                final isToday = PersonalizedFinanceOverview.sameDay(
                  date,
                  today,
                );
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label:
                          '${weekdays[index]} ${date.day}, ${summary.transactionCount} işlem',
                      child: InkWell(
                        key: ValueKey('finance-day-${date.day}'),
                        onTap: () => onDateSelected(date),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AnimatedContainer(
                          duration:
                              MediaQuery.maybeOf(context)?.disableAnimations ==
                                  true
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary
                                : isToday
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.65,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            children: [
                              Text(
                                weekdays[index],
                                maxLines: 1,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _FlowDot(
                                    visible: summary.income > 0,
                                    color: selected
                                        ? theme.colorScheme.onPrimary
                                        : ForestColors.income,
                                  ),
                                  const SizedBox(width: 3),
                                  _FlowDot(
                                    visible: summary.expense > 0,
                                    color: selected
                                        ? theme.colorScheme.onPrimary
                                              .withValues(alpha: 0.7)
                                        : ForestColors.expense,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowDot extends StatelessWidget {
  const _FlowDot({required this.visible, required this.color});

  final bool visible;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: visible ? color : color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
    );
  }
}
