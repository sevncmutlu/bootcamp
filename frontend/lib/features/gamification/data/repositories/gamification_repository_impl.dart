import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/gamification/data/datasources/gamification_local_data_source.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/leaderboard_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/gamification_status_entity.dart';
import 'package:maki_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:maki_app/core/network/maki_api_client.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationLocalDataSource gamificationDataSource;
  final AppDatabase database;
  final MakiApiClient apiClient;

  GamificationRepositoryImpl({
    required this.gamificationDataSource,
    required this.database,
    required this.apiClient,
  });

  @override
  Future<GamificationStatusEntity> getGamificationStatus() async {
    final state = await database.getGamificationState();
    return GamificationStatusEntity(
      xp: state?.xp ?? 0,
      level: state?.level ?? 1,
    );
  }

  @override
  Future<List<DailyChallengeEntity>> getDailyChallenges(DateTime date) async {
    final challenges = await gamificationDataSource.getOrSeedDailyChallenges(date);
    return challenges.map((c) => DailyChallengeEntity(
      id: c.id,
      titleKey: c.titleKey,
      descKey: c.descKey,
      xpReward: c.xpReward,
      isCompleted: c.isCompleted,
      date: c.date,
    )).toList();
  }

  @override
  Future<void> evaluateDailyChallenges(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final allExpenses = await database.getAllExpenses();
    final allIncomes = await database.getAllIncomes();

    final todayExpenses = allExpenses
        .where((e) => !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay))
        .toList();
    final todayIncomes = allIncomes
        .where((i) => !i.date.isBefore(startOfDay) && !i.date.isAfter(endOfDay))
        .toList();

    final challenges = await gamificationDataSource.getOrSeedDailyChallenges(date);

    for (final challenge in challenges) {
      if (challenge.isCompleted) continue;

      bool conditionMet = false;

      if (challenge.id.startsWith("cook_home_")) {
        final hasRestaurant = todayExpenses.any(
          (e) =>
              e.category.toLowerCase().contains("restaurant") ||
              e.category.toLowerCase().contains("dining") ||
              e.category.toLowerCase().contains("restoran") ||
              e.category.toLowerCase().contains("yemek"),
        );
        conditionMet = !hasRestaurant;
      } else if (challenge.id.startsWith("log_three_")) {
        conditionMet = (todayExpenses.length + todayIncomes.length) >= 3;
      } else if (challenge.id.startsWith("no_shopping_")) {
        final hasShopping = todayExpenses.any(
          (e) =>
              e.category.toLowerCase().contains("shopping") ||
              e.category.toLowerCase().contains("market") ||
              e.category.toLowerCase().contains("alışveriş"),
        );
        conditionMet = !hasShopping;
      } else if (challenge.id.startsWith("income_achiever_")) {
        conditionMet = todayIncomes.isNotEmpty;
      } else if (challenge.id.startsWith("coffee_saver_")) {
        final hasCoffee = todayExpenses.any(
          (e) =>
              e.category.toLowerCase().contains("coffee") ||
              e.category.toLowerCase().contains("kahve") ||
              e.category.toLowerCase().contains("kafe"),
        );
        conditionMet = !hasCoffee;
      } else if (challenge.id.startsWith("super_saver_")) {
        final sevenDaysAgo = date.subtract(const Duration(days: 7));
        final weekExpenses = allExpenses
            .where((e) => e.date.isAfter(sevenDaysAgo))
            .fold(0.0, (sum, e) => sum + e.amount);
        final weekIncomes = allIncomes
            .where((i) => i.date.isAfter(sevenDaysAgo))
            .fold(0.0, (sum, i) => sum + i.amount);
        conditionMet = weekIncomes > 0 && ((weekIncomes - weekExpenses) / weekIncomes) >= 0.20;
      } else if (challenge.id.startsWith("commute_smart_")) {
        final transportTotal = todayExpenses
            .where((e) =>
                e.category.toLowerCase().contains("transport") ||
                e.category.toLowerCase().contains("ulaşım"))
            .fold(0.0, (double s, e) => s + e.amount);
        conditionMet = transportTotal <= 50;
      } else if (challenge.id.startsWith("entertainment_control_")) {
        final hasEntertainment = todayExpenses.any(
          (e) =>
              e.category.toLowerCase().contains("entertainment") ||
              e.category.toLowerCase().contains("eğlence") ||
              e.category.toLowerCase().contains("game") ||
              e.category.toLowerCase().contains("oyun"),
        );
        conditionMet = !hasEntertainment;
      } else if (challenge.id.startsWith("subscription_audit_")) {
        final subTotal = todayExpenses
            .where((e) =>
                e.category.toLowerCase().contains("subscription") ||
                e.category.toLowerCase().contains("abonelik") ||
                e.category.toLowerCase().contains("fatura"))
            .fold(0.0, (double s, e) => s + e.amount);
        conditionMet = subTotal <= 100;
      } else if (challenge.id.startsWith("budget_guardian_")) {
        final dailyTotal = todayExpenses.fold(0.0, (double s, e) => s + e.amount);
        conditionMet = dailyTotal <= 500;
      } else if (challenge.id.startsWith("micro_saver_")) {
        conditionMet = todayExpenses.any((e) => e.amount < 50) || todayIncomes.any((i) => i.amount < 50);
      } else if (challenge.id.startsWith("weekly_reviewer_") || challenge.id.startsWith("learn_budget_")) {
        final distinctCategories = {
          ...todayExpenses.map((e) => e.category),
          ...todayIncomes.map((i) => i.source),
        };
        conditionMet = distinctCategories.length >= 3;
      } else if (challenge.id.startsWith("review_subs_")) {
        final subTotal = todayExpenses
            .where((e) =>
                e.category.toLowerCase().contains("subscription") ||
                e.category.toLowerCase().contains("abonelik") ||
                e.category.toLowerCase().contains("fatura"))
            .fold(0.0, (double s, e) => s + e.amount);
        conditionMet = subTotal <= 100;
      } else if (challenge.id.startsWith("meal_prep_")) {
        final hasRestaurant = todayExpenses.any(
          (e) =>
              e.category.toLowerCase().contains("restaurant") ||
              e.category.toLowerCase().contains("dining") ||
              e.category.toLowerCase().contains("restoran") ||
              e.category.toLowerCase().contains("yemek"),
        );
        conditionMet = !hasRestaurant;
      } else if (challenge.id.startsWith("walk_instead_")) {
        final transportTotal = todayExpenses
            .where((e) =>
                e.category.toLowerCase().contains("transport") ||
                e.category.toLowerCase().contains("ulaşım"))
            .fold(0.0, (double s, e) => s + e.amount);
        conditionMet = transportTotal <= 50;
      }

      if (conditionMet) {
        final completedChallenge = DailyChallenge(
          id: challenge.id,
          titleKey: challenge.titleKey,
          descKey: challenge.descKey,
          xpReward: challenge.xpReward,
          isCompleted: true,
          date: challenge.date,
        );
        await gamificationDataSource.updateChallenge(completedChallenge);
      }
    }
  }

  @override
  Future<GamificationStatusEntity> claimXP(DailyChallengeEntity challengeEntity) async {
    final challenge = DailyChallenge(
      id: challengeEntity.id,
      titleKey: challengeEntity.titleKey,
      descKey: challengeEntity.descKey,
      xpReward: 0,
      isCompleted: true,
      date: challengeEntity.date,
    );
    
    await gamificationDataSource.updateChallenge(challenge);

    final currentStatus = await gamificationDataSource.getGamificationStatus();
    final newTotalXp = currentStatus.xp + challengeEntity.xpReward;
    final newLevel = (newTotalXp / 100).floor() + 1;
    
    final updatedStatus = UserGamificationState(
      id: currentStatus.id,
      xp: newTotalXp,
      level: newLevel,
      badges: currentStatus.badges,
    );

    await gamificationDataSource.updateGamificationStatus(updatedStatus);

    return GamificationStatusEntity(
      xp: updatedStatus.xp,
      level: updatedStatus.level,
    );
  }

  @override
  Future<LeaderboardEntity> getLeaderboard({
    required String ageBand,
    required String householdBand,
    required int scoreBasisPoints,
  }) async {
    try {
      final standing = await MakiApi.instance.leaderboard(
        ageBand: ageBand,
        householdBand: householdBand,
        scoreBasisPoints: scoreBasisPoints,
      );
      
      if (!standing.available) {
        return LeaderboardEntity(
          available: false,
          percentile: _estimatePercentile(scoreBasisPoints),
          cohortSize: standing.cohortSize,
        );
      }
      
      return LeaderboardEntity(
        available: standing.available,
        percentile: standing.percentile,
        cohortSize: standing.cohortSize,
      );
    } catch (e) {
      return LeaderboardEntity(
        available: false,
        percentile: _estimatePercentile(scoreBasisPoints),
        cohortSize: '50-99',
      );
    }
  }

  int _estimatePercentile(int scoreBasisPoints) {
    if (scoreBasisPoints <= 0) return 25;
    final savingsPercent = (scoreBasisPoints / 100).round();
    final raw = (100 - savingsPercent * 0.85).clamp(5, 95).round();
    return (raw / 5).round() * 5;
  }

  @override
  Future<int> getSavingsScoreBasisPoints() async {
    final now = DateTime.now();
    final expenses = await database.getAllExpenses();
    final incomes = await database.getAllIncomes();

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
    
    return scoreBasisPoints;
  }

  @override
  Future<bool> hasWeeklyIncome() async {
    final now = DateTime.now();
    final incomes = await database.getAllIncomes();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final double weekIncomes = incomes
        .where((i) => i.date.isAfter(sevenDaysAgo))
        .fold(0.0, (sum, item) => sum + item.amount);
        
    return weekIncomes > 0;
  }
}
