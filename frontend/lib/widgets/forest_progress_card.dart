import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/widgets/mascot.dart';

class ForestProgressCard extends StatelessWidget {
  const ForestProgressCard({
    super.key,
    required this.level,
    required this.xp,
    required this.maxXp,
    required this.savingsScoreBasisPoints,
    required this.hasWeeklyIncome,
  });

  final int level;
  final int xp;
  final int maxXp;
  final int savingsScoreBasisPoints;
  final bool hasWeeklyIncome;

  int get _stage => level.clamp(1, 5);

  String _stageTitle(AppLocalizations l10n) {
    return switch (_stage) {
      1 => l10n.levelTitleSeed,
      2 => l10n.levelTitleSprout,
      3 => l10n.levelTitleSapling,
      4 => l10n.levelTitleTree,
      _ => l10n.levelTitleForest,
    };
  }

  MascotPose get _mascotPose {
    if (_stage == 1) return MascotPose.sleeping;
    if (_stage >= 4) return MascotPose.celebrate;
    return MascotPose.happy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final health = (savingsScoreBasisPoints / 10000).clamp(0.0, 1.0);
    final healthPercent = (health * 100).round();
    final growth = maxXp <= 0 ? 0.0 : (xp / maxXp).clamp(0.0, 1.0);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: l10n.forestSceneSemantics(_stageTitle(l10n)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: (5 - _stage) * 0.055),
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      'assets/images/maki_forest_v2.webp',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x24000000),
                          Color(0x10000000),
                          Color(0xC9001F16),
                        ],
                        stops: [0, 0.48, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD9FFF9EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.forestStage(_stage),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF153F2E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 0,
                    child: Mascot(
                      pose: _mascotPose,
                      size: 96,
                      withBadge: false,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 98,
                    bottom: 16,
                    child: Text(
                      _stageTitle(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        shadows: const [
                          Shadow(color: Color(0x99000000), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.forestHealth,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      hasWeeklyIncome
                          ? l10n.forestHealthValue(healthPercent)
                          : '—',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: hasWeeklyIncome ? health : 0,
                    minHeight: 8,
                    backgroundColor: scheme.primary.withValues(alpha: 0.10),
                  ),
                ),
                if (!hasWeeklyIncome) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.forestHealthNoIncome,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.forestGrowthProgress,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      '$xp / $maxXp DP',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: growth,
                    minHeight: 8,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                    color: scheme.tertiary,
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
