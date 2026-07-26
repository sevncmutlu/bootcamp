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
  Future<GamificationStatusEntity> claimXP(DailyChallengeEntity challengeEntity) async {
    final challenge = DailyChallenge(
      id: challengeEntity.id,
      titleKey: challengeEntity.titleKey,
      descKey: challengeEntity.descKey,
      xpReward: challengeEntity.xpReward,
      isCompleted: true,
      date: challengeEntity.date,
    );
    
    await gamificationDataSource.updateChallenge(challenge);

    final currentStatus = await gamificationDataSource.getGamificationStatus();
    final newTotalXp = currentStatus.xp + challenge.xpReward;
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
    final standing = await MakiApi.instance.leaderboard(
      ageBand: ageBand,
      householdBand: householdBand,
      scoreBasisPoints: scoreBasisPoints,
    );
    return LeaderboardEntity(
      available: standing.available,
      percentile: standing.percentile,
      cohortSize: standing.cohortSize,
    );
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
