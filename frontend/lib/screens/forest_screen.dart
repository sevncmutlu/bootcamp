import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/gamification_service.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/screens/leaderboard_screen.dart';
import 'package:maki_app/screens/settings_screen.dart';
import 'package:maki_app/widgets/forest_progress_card.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => ForestScreenState();
}

class ForestScreenState extends State<ForestScreen> {
  void refresh() {
    _loadData();
  }

  final _db = AppDatabase.instance;
  late final GamificationService _gamificationService;

  UserGamificationState? _gameState;
  List<DailyChallenge> _challenges = [];
  bool _isLoading = true;
  int _savingsScoreBasisPoints = 0;
  bool _hasWeeklyIncome = false;

  @override
  void initState() {
    super.initState();
    _gamificationService = GamificationService(_db);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
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
        title: Text(
          l10n.forestTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  )
                  .then((_) => _loadData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
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
                                    decoration: isClaimed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getLocalizedDesc(context, challenge.descKey),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
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

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => LeaderboardScreen(
                          scoreBasisPoints: _savingsScoreBasisPoints,
                          userLevel: level,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.leaderboard_outlined,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.leaderboardHeader,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.leaderboardSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _hasWeeklyIncome
                                      ? '${l10n.forestHealth}: ${l10n.forestHealthValue((_savingsScoreBasisPoints / 100).round())}'
                                      : l10n.forestHealthNoIncome,
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
