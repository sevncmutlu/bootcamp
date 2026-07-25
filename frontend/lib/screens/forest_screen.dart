import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/gamification_service.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/screens/leaderboard_screen.dart';
import 'package:maki_app/widgets/forest_progress_card.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => ForestScreenState();
}

class ForestScreenState extends State<ForestScreen>
    with SingleTickerProviderStateMixin {
  void refresh() {
    _loadData();
  }

  final _db = AppDatabase.instance;
  late final GamificationService _gamificationService;
  late final TabController _tabController;

  UserGamificationState? _gameState;
  List<DailyChallenge> _challenges = [];
  bool _isLoading = true;
  int _savingsScoreBasisPoints = 0;
  bool _hasWeeklyIncome = false;

  @override
  void initState() {
    super.initState();
    _gamificationService = GamificationService(_db);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData(showLoading: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    final now = DateTime.now();

    await _gamificationService.evaluateDailyChallenges(now);

    final state = await _db.getGamificationState();
    final challengesList = await _db.getChallengesForDate(now);

    final expenses = await _db.getAllExpenses();
    final incomes = await _db.getAllIncomes();

    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final double weekExpenses = expenses
        .where((e) => e.date.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, item) => sum + item.amount);
    final double weekIncomes = incomes
        .where((i) => i.date.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, item) => sum + item.amount);

    var scoreBasisPoints = 0;
    if (weekIncomes > 0) {
      final savingsRate = (weekIncomes - weekExpenses) / weekIncomes;
      scoreBasisPoints = (savingsRate.clamp(0, 1) * 10000).round();
    }

    if (!mounted) return;
    setState(() {
      _gameState = state;
      _challenges = challengesList;
      _savingsScoreBasisPoints = scoreBasisPoints;
      _hasWeeklyIncome = weekIncomes > 0;
      _isLoading = false;
    });
  }

  Future<void> _claimXP(DailyChallenge challenge) async {
    if (!challenge.isCompleted || challenge.xpReward == 0) return;

    final updatedState = await _gamificationService.claimXP(challenge);
    setState(() {
      _gameState = updatedState;
    });

    final now = DateTime.now();
    final challengesList = await _db.getChallengesForDate(now);
    setState(() {
      _challenges = challengesList;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.xpClaimed(challenge.xpReward),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
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
        return l10n.challengeWeeklyReviewer;
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
        return l10n.challengeWeeklyReviewerDesc;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final level = _gameState?.level ?? 1;
    final xp = _gameState?.xp ?? 0;
    final maxXp = level * 100;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: Text(
          _tabController.index == 0
              ? l10n.forestTitle
              : l10n.leaderboardTitle,
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
      body: TabBarView(
        controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _loadData,
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
                        savingsScoreBasisPoints: _savingsScoreBasisPoints,
                        hasWeeklyIncome: _hasWeeklyIncome,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        l10n.challengesHeader,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._challenges.map((challenge) {
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
                                      ? ForestColors.emerald.withValues(alpha: 0.1)
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.05,
                                        ),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getLocalizedTitle(
                                          context,
                                          challenge.titleKey,
                                        ),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isClaimed
                                              ? theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getLocalizedDesc(context, challenge.descKey),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isClaimed
                                              ? theme.colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.5)
                                              : theme.colorScheme.onSurfaceVariant,
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
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: Text(l10n.claimXp(challenge.xpReward)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isClaimed
                                          ? theme.colorScheme.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : theme.colorScheme.onSurface.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      isClaimed
                                          ? l10n.claimedStatus
                                          : l10n.pendingStatus,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isClaimed
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
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
            LeaderboardView(
              scoreBasisPoints: _savingsScoreBasisPoints,
              userLevel: level,
            ),
          ],
        ),
      );
  }
}
