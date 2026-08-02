import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';

class LivingForestHub extends StatelessWidget {
  const LivingForestHub({
    super.key,
    required this.snapshot,
    required this.onCreateGoal,
    required this.onContribute,
    required this.onOpenGoalMap,
    required this.onOpenCalendar,
  });

  final LivingForestSnapshot snapshot;
  final VoidCallback onCreateGoal;
  final ValueChanged<SavingsGoalView> onContribute;
  final ValueChanged<SavingsGoalView> onOpenGoalMap;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ForestPulse(snapshot: snapshot, onOpenCalendar: onOpenCalendar),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEDEF PATİKALARI',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Maki ile rotanı büyüt',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'MakiDisplay',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: snapshot.goals.length >= 4 ? null : onCreateGoal,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Hedef ekle'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.goals.isEmpty)
          _NoGoalCard(onCreateGoal: onCreateGoal)
        else
          ...snapshot.goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _GoalRouteCard(
                goal: goal,
                onContribute: () => onContribute(goal),
                onOpenMap: () => onOpenGoalMap(goal),
              ),
            ),
          ),
      ],
    );
  }
}

class ForestStorePanel extends StatelessWidget {
  const ForestStorePanel({
    super.key,
    required this.snapshot,
    required this.onBuyItem,
  });

  final LivingForestSnapshot snapshot;
  final ValueChanged<ForestStoreItemView> onBuyItem;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - AppSpacing.md * 2) / 3
            : constraints.maxWidth >= 480
            ? (constraints.maxWidth - AppSpacing.md) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: snapshot.store
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _StoreItemCard(
                    item: item,
                    balance: snapshot.seedBalance,
                    onBuy: () => onBuyItem(item),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ForestPulse extends StatelessWidget {
  const _ForestPulse({required this.snapshot, required this.onOpenCalendar});

  final LivingForestSnapshot snapshot;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final stats = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _PulsePill(
                  icon: Icons.local_fire_department_rounded,
                  label: '${snapshot.currentStreak} gün seri',
                ),
                _PulsePill(
                  icon: Icons.eco_rounded,
                  label: '%${snapshot.progress.growthPercent.round()} büyüme',
                ),
                _PulsePill(
                  icon: Icons.stars_rounded,
                  label: 'Seviye ${snapshot.level}',
                ),
              ],
            );
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugünün orman nabzı',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'MakiDisplay',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  snapshot.completedDaysLast7 == 0
                      ? 'İlk gerçek finans adımın, bu patikadaki ilk filizi açacak.'
                      : 'Son yedi günde ${snapshot.completedDaysLast7} bakım günü. Küçük ama gerçek adımlar koruluğunu canlı tutuyor.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                stats,
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: onOpenCalendar,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Finans takvimini aç'),
                ),
              ],
            );
            if (compact) return copy;
            return Row(
              children: [
                const Mascot.avatar(size: 84),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: copy),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PulsePill extends StatelessWidget {
  const _PulsePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _NoGoalCard extends StatelessWidget {
  const _NoGoalCard({required this.onCreateGoal});

  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.explore_rounded, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            'İlk hedefinin haritasını aç',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '“Bunu almak için birikiyorum” de; Maki güvenli katkı aralığını ve patika duraklarını göstersin.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onCreateGoal,
            child: const Text('Rotayı oluştur'),
          ),
        ],
      ),
    ),
  );
}

class _GoalRouteCard extends StatelessWidget {
  const _GoalRouteCard({
    required this.goal,
    required this.onContribute,
    required this.onOpenMap,
  });

  final SavingsGoalView goal;
  final VoidCallback onContribute;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const stops = [0.0, 0.10, 0.25, 0.50, 0.75, 1.0];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: '${goal.title} tam ekran hedef haritasını aç',
              child: InkWell(
                onTap: onOpenMap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AspectRatio(
                    aspectRatio: 16 / 6.5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/maki_goal_route_v2.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xA8132F25)],
                              stops: [0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xD91B493A),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: const Color(0x40FFFFFF),
                              ),
                            ),
                            child: Text(
                              'Rotanın %${(goal.progress * 100).round()} kadarı canlandı',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xD9FFFFFF),
                            ),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.flag_rounded),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          Text(
                            goal.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (goal.isPrimary)
                            const Chip(
                              label: Text('Ana rota'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      Text(
                        '${formatTL(goal.totalSaved, context: context)} birikti · ${formatTL(goal.remaining, context: context)} kaldı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Katkı ekle',
                  onPressed: onContribute,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 58,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 17,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                      ),
                      ...stops.map((stop) {
                        final x = 8 + (constraints.maxWidth - 16) * stop;
                        final passed = goal.progress >= stop;
                        return Positioned(
                          left: (x - 13).clamp(0, constraints.maxWidth - 26),
                          top: 8,
                          child: Column(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: passed
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surface,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  passed ? Icons.eco_rounded : Icons.circle,
                                  size: 13,
                                  color: passed
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primaryContainer,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                stop == 0
                                    ? 'Başla'
                                    : '%${(stop * 100).round()}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.balance,
    required this.onBuy,
  });

  final ForestStoreItemView item;
  final int balance;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownedPermanent = item.permanent && item.quantity > 0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_florist_rounded,
                  color: theme.colorScheme.primary,
                ),
                const Spacer(),
                if (item.quantity > 0) Text('×${item.quantity}'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: ownedPermanent || balance < item.price
                    ? null
                    : onBuy,
                child: Text(ownedPermanent ? 'Açıldı' : '${item.price} tohum'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
