part of 'personalized_finance_overview.dart';

class _GoalDashboardCard extends StatelessWidget {
  const _GoalDashboardCard({
    required this.profile,
    required this.locale,
    required this.summary,
    required this.progress,
  });

  final GoalExperience profile;
  final Locale locale;
  final FinanceDaySummary summary;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.makiPalette;
    final isTurkish = locale.languageCode == 'tr';
    final tasks = profile.tasks(locale);
    return Container(
      key: const ValueKey('goal-dashboard-card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft(theme.brightness, theme.colorScheme.primary),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(profile.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.route(locale).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.68),
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        profile.title(locale),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontFamily: 'MakiDisplay',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Mascot(
                  pose: MascotPose.thinking,
                  size: 58,
                  withBadge: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MoneyMetric(
                    label: isTurkish ? 'Gelir' : 'Income',
                    value: formatTL(
                      summary.income,
                      decimals: 0,
                      context: context,
                    ),
                    color: Color.lerp(palette.income, Colors.white, 0.44)!,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoneyMetric(
                    label: isTurkish ? 'Gider' : 'Expense',
                    value: formatTL(
                      summary.expense,
                      decimals: 0,
                      context: context,
                    ),
                    color: Color.lerp(palette.expense, Colors.white, 0.36)!,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoneyMetric(
                    label: isTurkish ? 'Net' : 'Net',
                    value: formatTL(summary.net, decimals: 0, context: context),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              profile.mission(locale),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              key: const ValueKey('goal-task-route'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final task in tasks) ...[
                    _GoalChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: task,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  _GoalChip(
                    icon: Icons.query_stats_rounded,
                    label: profile.analysis(locale),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Maki: ${profile.coach(locale)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.82)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
