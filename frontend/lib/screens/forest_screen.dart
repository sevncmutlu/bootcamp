import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/gamification_service.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  final _db = AppDatabase.instance;
  late final GamificationService _gamificationService;

  UserGamificationState? _gameState;
  List<DailyChallenge> _challenges = [];
  bool _isLoading = true;
  int _saverPercentile = 45;

  @override
  void initState() {
    super.initState();
    _gamificationService = GamificationService(_db);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    
    // Evaluate challenges based on current transactions
    await _gamificationService.evaluateDailyChallenges(now);

    // Fetch updated challenges and game state
    final state = await _db.getGamificationState();
    final challengesList = await _db.getChallengesForDate(now);
    
    // Calculate local savings percentile for anonymous leaderboard
    final expenses = await _db.getAllExpenses();
    final incomes = await _db.getAllIncomes();
    
    // Filter for current week (last 7 days)
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final double weekExpenses = expenses
        .where((e) => e.date.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, item) => sum + item.amount);
    final double weekIncomes = incomes
        .where((i) => i.date.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, item) => sum + item.amount);

    int percentile = 20; // Default rank
    if (weekIncomes > 0) {
      final savingsRate = (weekIncomes - weekExpenses) / weekIncomes;
      if (savingsRate >= 0.50) {
        percentile = 92;
      } else if (savingsRate >= 0.30) {
        percentile = 78;
      } else if (savingsRate >= 0.15) {
        percentile = 64;
      } else if (savingsRate > 0) {
        percentile = 48;
      }
    }

    setState(() {
      _gameState = state;
      _challenges = challengesList;
      _saverPercentile = percentile;
      _isLoading = false;
    });
  }

  Future<void> _claimXP(DailyChallenge challenge) async {
    if (!challenge.isCompleted || challenge.xpReward == 0) return;
    
    final updatedState = await _gamificationService.claimXP(challenge);
    setState(() {
      _gameState = updatedState;
    });
    
    // Reload challenges to update claimed rewards
    final now = DateTime.now();
    final challengesList = await _db.getChallengesForDate(now);
    setState(() {
      _challenges = challengesList;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 +${challenge.xpReward} XP claimed!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  String _getTreeAssetPath(int level) {
    if (level <= 1) return 'assets/images/seed.png';
    if (level == 2) return 'assets/images/sprout.png';
    if (level == 3) return 'assets/images/sapling.png';
    return 'assets/images/tree.png';
  }

  String _getLevelTitle(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context)!;
    if (level <= 1) return l10n.levelTitleSeed;
    if (level == 2) return l10n.levelTitleSprout;
    if (level == 3) return l10n.levelTitleSapling;
    if (level == 4) return l10n.levelTitleTree;
    return l10n.levelTitleForest;
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final level = _gameState?.level ?? 1;
    final xp = _gameState?.xp ?? 0;
    final maxXp = level * 100;
    final progress = xp / maxXp;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.forestTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tree Growth Visualizer Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Progressive Tree Graphic
                      Container(
                        height: 180,
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          _getTreeAssetPath(level),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback icon outline in case asset is not fully loaded in simulator
                            return Icon(
                              Icons.spa_outlined,
                              size: 100,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Level Indicators
                      Text(
                        l10n.currentLevel(level),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLevelTitle(context, level),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Level Progression Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.xpNeeded(xp, maxXp, level + 1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Active Daily Challenges List
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
                      color: theme.colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isClaimed
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : isCompleted
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          child: Icon(
                            isClaimed
                                ? Icons.check_circle_outline
                                : isCompleted
                                    ? Icons.stars_outlined
                                    : Icons.lock_open_outlined,
                            color: isClaimed
                                ? theme.colorScheme.primary
                                : isCompleted
                                    ? Colors.green
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLocalizedTitle(context, challenge.titleKey),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isClaimed ? TextDecoration.lineThrough : null,
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
                              backgroundColor: Colors.green,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isClaimed
                                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
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

              // 3. Weekly Saver Leaderboard Card (US-24)
              Card(
                elevation: 0,
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
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
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                              l10n.leaderboardRankText(_saverPercentile),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.leaderboardSubtitle,
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
