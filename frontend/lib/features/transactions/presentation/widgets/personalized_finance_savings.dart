part of 'personalized_finance_overview.dart';

class _SavingsGoalDashboardCard extends StatelessWidget {
  const _SavingsGoalDashboardCard({
    super.key,
    required this.goal,
    this.onOpenGoal,
  });

  final SavingsGoalView goal;
  final VoidCallback? onOpenGoal;

  IconData get _icon => switch (goal.iconKey) {
    'home' => Icons.home_work_outlined,
    'education' => Icons.school_outlined,
    'travel' => Icons.flight_takeoff_rounded,
    'vehicle' => Icons.directions_car_filled_outlined,
    'emergency' => Icons.health_and_safety_outlined,
    _ => Icons.savings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.makiPalette;
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    final remainingDays = goal.targetDate
        ?.difference(DateTime.now())
        .inDays
        .clamp(0, 99999);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(palette.heroStart, theme.colorScheme.tertiary, 0.18)!,
            Color.lerp(palette.heroEnd, theme.colorScheme.primary, 0.30)!,
          ],
        ),
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
                  child: Icon(_icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTurkish ? 'HEDEF ROTASI' : 'GOAL ROUTE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.68),
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        goal.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  pose: MascotPose.celebrate,
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
                    label: isTurkish ? 'Biriken' : 'Saved',
                    value: formatTL(
                      goal.totalSaved,
                      decimals: 0,
                      context: context,
                    ),
                    color: Color.lerp(palette.income, Colors.white, 0.45)!,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoneyMetric(
                    label: isTurkish ? 'Kalan' : 'Remaining',
                    value: formatTL(
                      goal.remaining,
                      decimals: 0,
                      context: context,
                    ),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MoneyMetric(
                    label: isTurkish ? 'Hedef' : 'Target',
                    value: formatTL(
                      goal.targetAmount,
                      decimals: 0,
                      context: context,
                    ),
                    color: Color.lerp(
                      theme.colorScheme.tertiary,
                      Colors.white,
                      0.32,
                    )!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  '%${(goal.progress * 100).round()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      key: const ValueKey('savings-goal-progress'),
                      value: goal.progress,
                      minHeight: 9,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                if (remainingDays != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isTurkish ? '$remainingDays gün' : '$remainingDays days',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [0, 25, 50, 75, 100]
                  .map(
                    (value) => Text(
                      '$value',
                      style: TextStyle(
                        color: Color(0xBFFFFFFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isTurkish
                          ? 'Gelir veya gider, yalnızca kayıt sırasında “hedefi etkilesin” seçilirse bu yolu değiştirir.'
                          : 'Income or expense changes this route only when you explicitly link it while saving.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onOpenGoal != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const ValueKey('open-savings-goal-route'),
                  onPressed: onOpenGoal,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                  icon: const Icon(Icons.route_rounded, size: 18),
                  label: Text(
                    isTurkish ? 'Hedef yolunu aç' : 'Open goal route',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
