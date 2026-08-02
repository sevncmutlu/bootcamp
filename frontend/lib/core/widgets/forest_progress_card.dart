import 'package:flutter/material.dart';
import 'package:maki_app/core/personalization/goal_experience.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/l10n/app_localizations.dart';

class ForestProgressCard extends StatelessWidget {
  const ForestProgressCard({
    super.key,
    required this.level,
    required this.xp,
    required this.maxXp,
    required this.savingsScoreBasisPoints,
    required this.hasWeeklyIncome,
    this.primaryGoal = 'track_spending',
    this.completedTasks = 0,
    this.totalTasks = 0,
  });

  final int level;
  final int xp;
  final int maxXp;
  final int savingsScoreBasisPoints;
  final bool hasWeeklyIncome;
  final String primaryGoal;
  final int completedTasks;
  final int totalTasks;

  int get _stage => level.clamp(1, 5);

  String _stageTitle(AppLocalizations l10n, int stage) {
    return switch (stage) {
      1 => l10n.levelTitleSeed,
      2 => l10n.levelTitleSprout,
      3 => l10n.levelTitleSapling,
      4 => l10n.levelTitleTree,
      _ => l10n.levelTitleForest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.makiPalette;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final profile = GoalExperience.forKey(primaryGoal);
    final health = (savingsScoreBasisPoints / 10000).clamp(0.0, 1.0);
    final healthPercent = (health * 100).round();
    final growth = maxXp <= 0 ? 0.0 : (xp / maxXp).clamp(0.0, 1.0);
    final isTurkish = locale.languageCode == 'tr';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: l10n.forestSceneSemantics(_stageTitle(l10n, _stage)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                return SizedBox(
                  height: compact ? 350 : 390,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: (5 - _stage) * 0.035),
                          BlendMode.darken,
                        ),
                        child: Image.asset(
                          'assets/images/maki_living_grove_v1.webp',
                          fit: BoxFit.cover,
                          alignment: compact
                              ? const Alignment(0.48, 0)
                              : Alignment.center,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              palette.heroStart.withValues(alpha: 0.90),
                              palette.heroStart.withValues(alpha: 0.61),
                              palette.heroStart.withValues(alpha: 0.10),
                            ],
                            stops: [0, 0.43, 0.82],
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x24000000),
                              Colors.transparent,
                              Color(0xB8071A14),
                            ],
                            stops: [0, 0.52, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        top: AppSpacing.lg,
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _HeroPill(
                              icon: Icons.park_rounded,
                              label: l10n.forestStage(_stage),
                              emphasized: true,
                            ),
                            _HeroPill(
                              icon: profile.icon,
                              label: profile.route(locale),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: compact
                            ? AppSpacing.lg
                            : constraints.maxWidth * 0.43,
                        bottom: AppSpacing.xl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isTurkish
                                  ? 'SENİN YAŞAYAN KORULUĞUN'
                                  : 'YOUR LIVING GROVE',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.15,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              profile.species(locale),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontFamily: 'MakiDisplay',
                                fontWeight: FontWeight.w800,
                                height: 1.02,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xA6000000),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              isTurkish
                                  ? 'Her küçük finans adımı bu korulukta görünür bir iz bırakır.'
                                  : 'Every small financial step leaves a visible mark in this grove.',
                              maxLines: compact ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: growth,
                                      minHeight: 8,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  '$xp / $maxXp DP',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isTurkish ? 'Büyüme yolu' : 'Growth path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _GrowthPath(
                  currentStage: _stage,
                  stageLabel: (stage) => _stageTitle(l10n, stage),
                ),
                const SizedBox(height: AppSpacing.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth < 580
                        ? (constraints.maxWidth - AppSpacing.sm) / 2
                        : (constraints.maxWidth - AppSpacing.md * 2) / 3;
                    return Wrap(
                      spacing: constraints.maxWidth < 580
                          ? AppSpacing.sm
                          : AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _ForestMetric(
                          width: itemWidth,
                          icon: Icons.eco_rounded,
                          title: l10n.forestHealth,
                          value: hasWeeklyIncome ? '%$healthPercent' : '—',
                          progress: hasWeeklyIncome ? health : 0,
                        ),
                        _ForestMetric(
                          width: itemWidth,
                          icon: Icons.auto_graph_rounded,
                          title: l10n.forestGrowthProgress,
                          value: '${(growth * 100).round()}%',
                          progress: growth,
                        ),
                        _ForestMetric(
                          width: itemWidth,
                          icon: Icons.task_alt_rounded,
                          title: isTurkish
                              ? 'Tamamlanan görev'
                              : 'Completed tasks',
                          value: totalTasks == 0
                              ? '0'
                              : '$completedTasks / $totalTasks',
                          progress: totalTasks == 0
                              ? 0
                              : completedTasks / totalTasks,
                        ),
                      ],
                    );
                  },
                ),
                if (!hasWeeklyIncome) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.forestHealthNoIncome,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.42,
                    ),
                    borderRadius: AppRadius.card,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isTurkish
                                  ? 'Bu hafta koruluğu ne büyütür?'
                                  : 'What grows the grove this week?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        profile.mission(locale),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: profile
                            .tasks(locale)
                            .map(
                              (task) => Chip(
                                avatar: Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                label: Text(task),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.94)
            : theme.makiPalette.heroStart.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: emphasized
                ? theme.colorScheme.onPrimaryContainer
                : Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: emphasized
                    ? theme.colorScheme.onPrimaryContainer
                    : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthPath extends StatelessWidget {
  const _GrowthPath({required this.currentStage, required this.stageLabel});

  final int currentStage;
  final String Function(int stage) stageLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final theme = Theme.of(context);
    final safeStage = currentStage.clamp(1, 5);
    return Column(
      children: [
        SizedBox(
          height: 34,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final nodeSlot = constraints.maxWidth / 5;
              final lineWidth = constraints.maxWidth - nodeSlot;
              final completedWidth =
                  lineWidth * ((safeStage - 1) / 4).clamp(0.0, 1.0);
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: nodeSlot / 2,
                    right: nodeSlot / 2,
                    top: 16,
                    child: Container(
                      key: const ValueKey('forest-stage-track'),
                      height: 2,
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  Positioned(
                    left: nodeSlot / 2,
                    top: 16,
                    width: completedWidth,
                    child: AnimatedContainer(
                      key: const ValueKey('forest-stage-completed-track'),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      height: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      final stage = index + 1;
                      final active = stage <= safeStage;
                      final current = stage == safeStage;
                      return Expanded(
                        child: Center(
                          child: AnimatedContainer(
                            key: ValueKey('forest-stage-$stage'),
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            width: current ? 34 : 28,
                            height: current ? 34 : 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: current
                                  ? theme.colorScheme.tertiary
                                  : active
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withValues(
                                      alpha: 0.09,
                                    ),
                              border: Border.all(
                                color: current
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.primary.withValues(
                                        alpha: active ? 1 : 0.18,
                                      ),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                active
                                    ? Icons.eco_rounded
                                    : Icons.circle_outlined,
                                size: current ? 18 : 14,
                                color: active
                                    ? (current
                                          ? theme.colorScheme.onTertiary
                                          : theme.colorScheme.onPrimary)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (index) {
            final stage = index + 1;
            final active = stage <= safeStage;
            final current = stage == safeStage;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  stageLabel(stage),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: active
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ForestMetric extends StatelessWidget {
  const _ForestMetric({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.52,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.48),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'MakiDisplay',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
