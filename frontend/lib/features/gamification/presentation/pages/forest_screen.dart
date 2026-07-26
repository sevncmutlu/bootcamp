import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/features/gamification/presentation/pages/leaderboard_screen.dart';
import 'package:maki_app/core/widgets/forest_progress_card.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => ForestScreenState();
}

class ForestScreenState extends State<ForestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  void refresh() {
    context.read<GamificationBloc>().add(LoadGamificationDataEvent());
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationBloc>().add(LoadGamificationDataEvent());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _claimXP(DailyChallengeEntity challenge) {
    if (!challenge.isCompleted || challenge.xpReward == 0) return;
    context.read<GamificationBloc>().add(ClaimXPEvent(challenge));
  }

  String _getLocalizedTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'challengeCookHome':
        return l10n.challengeCookHome;
      case 'challengeLogThree':
        return l10n.challengeLogThree;
      case 'challengeNoShopping':
        return l10n.challengeNoShopping;
      case 'challengeSaveTen':
        return l10n.challengeSaveTen;
      case 'challengeIncomeAchiever':
        return l10n.challengeIncomeAchiever;
      case 'challengeCoffeeSaver':
        return l10n.challengeCoffeeSaver;
      case 'challengeReceiptMaster':
        return l10n.challengeReceiptMaster;
      case 'challengeSuperSaver':
        return l10n.challengeSuperSaver;
      case 'challengeCommuteSmart':
        return l10n.challengeCommuteSmart;
      case 'challengeEntertainmentControl':
        return l10n.challengeEntertainmentControl;
      case 'challengeSubscriptionAudit':
        return l10n.challengeSubscriptionAudit;
      case 'challengeBudgetGuardian':
        return l10n.challengeBudgetGuardian;
      case 'challengeMicroSaver':
        return l10n.challengeMicroSaver;
      case 'challengeWeeklyReviewer':
      case 'challengeLearnBudget':
        return l10n.challengeWeeklyReviewer;
      case 'challengeReviewSubs':
        return l10n.challengeSubscriptionAudit;
      case 'challengeMealPrep':
        return l10n.challengeCoffeeSaver;
      case 'challengeWalk':
        return l10n.challengeCommuteSmart;
      default:
        return key;
    }
  }

  String _getLocalizedDesc(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'challengeCookHomeDesc':
        return l10n.challengeCookHomeDesc;
      case 'challengeLogThreeDesc':
        return l10n.challengeLogThreeDesc;
      case 'challengeNoShoppingDesc':
        return l10n.challengeNoShoppingDesc;
      case 'challengeSaveTenDesc':
        return l10n.challengeSaveTenDesc;
      case 'challengeIncomeAchieverDesc':
        return l10n.challengeIncomeAchieverDesc;
      case 'challengeCoffeeSaverDesc':
        return l10n.challengeCoffeeSaverDesc;
      case 'challengeReceiptMasterDesc':
        return l10n.challengeReceiptMasterDesc;
      case 'challengeSuperSaverDesc':
        return l10n.challengeSuperSaverDesc;
      case 'challengeCommuteSmartDesc':
        return l10n.challengeCommuteSmartDesc;
      case 'challengeEntertainmentControlDesc':
        return l10n.challengeEntertainmentControlDesc;
      case 'challengeSubscriptionAuditDesc':
        return l10n.challengeSubscriptionAuditDesc;
      case 'challengeBudgetGuardianDesc':
        return l10n.challengeBudgetGuardianDesc;
      case 'challengeMicroSaverDesc':
        return l10n.challengeMicroSaverDesc;
      case 'challengeWeeklyReviewerDesc':
      case 'challengeLearnBudgetDesc':
        return l10n.challengeWeeklyReviewerDesc;
      case 'challengeReviewSubsDesc':
        return l10n.challengeSubscriptionAuditDesc;
      case 'challengeMealPrepDesc':
        return l10n.challengeCoffeeSaverDesc;
      case 'challengeWalkDesc':
        return l10n.challengeCommuteSmartDesc;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: Text(
          _tabController.index == 0 ? l10n.forestTitle : l10n.leaderboardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forest_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.forestTitle),
                      ],
                    ),
                  ),
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.leaderboard_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.leaderboardTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: BlocConsumer<GamificationBloc, GamificationState>(
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

          return TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
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
                          savingsScoreBasisPoints:
                              state.savingsScoreBasisPoints,
                          hasWeeklyIncome: state.hasWeeklyIncome,
                        ),
                        const SizedBox(height: 24),

                        Text(
                          l10n.challengesHeader,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
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
                                        ? ForestColors.emerald.withValues(
                                            alpha: 0.1,
                                          )
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.05),
                                    child: Icon(
                                      isClaimed
                                          ? Icons.check_circle_outline
                                          : isCompleted
                                          ? Icons.stars_outlined
                                          : Icons.lock_open_outlined,
                                      color: isClaimed
                                          ? theme.colorScheme.primary
                                          : isCompleted
                                          ? ForestColors.emerald
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
                                                    ? theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.4,
                                                          )
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
                                                          .withValues(
                                                            alpha: 0.5,
                                                          )
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
                                        backgroundColor: ForestColors.emerald,
                                        foregroundColor: Colors.white,
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
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
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
              ),
              LeaderboardView(userLevel: level),
            ],
          );
        },
      ),
    );
  }
}
