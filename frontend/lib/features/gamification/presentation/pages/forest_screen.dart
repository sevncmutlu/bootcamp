import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/personalization/goal_experience.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/core/widgets/forest_progress_card.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_catalog.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/features/gamification/data/services/living_forest_service.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_app/features/gamification/presentation/widgets/living_forest_hub.dart';
import 'package:maki_app/features/transactions/presentation/pages/finance_calendar_screen.dart';
import 'package:maki_app/features/gamification/presentation/pages/goal_world_map_screen.dart';
part 'forest_goal_forms.dart';
part 'forest_store_actions.dart';
part 'forest_localization.dart';
part '../widgets/forest_store_shortcut.dart';
part '../widgets/forest_flora_catalog.dart';
part '../widgets/forest_path_button.dart';
part '../widgets/forest_district.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key, this.primaryGoal = 'track_spending'});

  final String primaryGoal;

  @override
  State<ForestScreen> createState() => ForestScreenState();
}

class ForestScreenState extends State<ForestScreen> {
  LivingForestSnapshot _livingForest = LivingForestService.initialSnapshot();

  void refresh() {
    context.read<GamificationBloc>().add(LoadGamificationDataEvent());
    unawaited(_loadLivingForest());
  }

  void _updateForestView(VoidCallback callback) => setState(callback);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationBloc>().add(LoadGamificationDataEvent());
      unawaited(_loadLivingForest());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('forest-back-button'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              MainNavigationScreen.openDrawer();
            }
          },
        ),
        title: MakiAppBarTitle(title: l10n.forestTitle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: _ForestStoreShortcut(
              balance: _livingForest.seedBalance,
              onTap: _showForestStore,
            ),
          ),
        ],
      ),
      body: MakiBackground(
        maxContentWidth: 1180,
        child: BlocConsumer<GamificationBloc, GamificationState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
            }
            if (state.newlyClaimedXP != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.xpClaimed(state.newlyClaimedXP!)),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.status == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final level = state.status?.level ?? 1;
            final xp = state.status?.xp ?? 0;
            final maxXp = level * 100;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<GamificationBloc>().add(
                  LoadGamificationDataEvent(),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ForestProgressCard(
                        level: level,
                        xp: xp,
                        maxXp: maxXp,
                        savingsScoreBasisPoints: state.savingsScoreBasisPoints,
                        hasWeeklyIncome: state.hasWeeklyIncome,
                        primaryGoal: widget.primaryGoal,
                        completedTasks: state.challenges
                            .where(
                              (challenge) =>
                                  challenge.isCompleted ||
                                  challenge.xpReward == 0,
                            )
                            .length,
                        totalTasks: state.challenges.length,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      LivingForestHub(
                        snapshot: _livingForest,
                        onCreateGoal: _showCreateGoal,
                        onContribute: _showContribution,
                        onOpenGoalMap: _openGoalMap,
                        onOpenCalendar: _openCalendar,
                      ),
                      const SizedBox(height: 24),
                      _FloraCatalog(primaryGoal: widget.primaryGoal),
                      const SizedBox(height: 24),

                      Text(
                        l10n.challengesHeader,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.challengeRotationSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          key: const ValueKey('challenge-route-badge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${_routeName(context)} · 3 rota görevi + 1 sürpriz',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.challenges.map((challenge) {
                        final isClaimed = challenge.xpReward == 0;
                        final isCompleted = challenge.isCompleted;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isClaimed
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        )
                                      : isCompleted
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        )
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.05,
                                        ),
                                  child: Icon(
                                    isClaimed
                                        ? Icons.check_circle_outline
                                        : isCompleted
                                        ? Icons.stars_outlined
                                        : _challengeIcon(challenge),
                                    color: isClaimed
                                        ? theme.colorScheme.primary
                                        : isCompleted
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getLocalizedTitle(
                                          context,
                                          challenge.titleKey,
                                        ),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isClaimed
                                                  ? theme.colorScheme.onSurface
                                                        .withValues(alpha: 0.4)
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getLocalizedDesc(
                                          context,
                                          challenge.descKey,
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: isClaimed
                                                  ? theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: 0.5)
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCompleted && !isClaimed)
                                  ElevatedButton(
                                    onPressed: () => _claimXP(challenge),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 10.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.claimXp(challenge.xpReward),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isClaimed
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.1)
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      isClaimed
                                          ? l10n.claimedStatus
                                          : l10n.pendingStatus,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: isClaimed
                                                ? theme.colorScheme.primary
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
