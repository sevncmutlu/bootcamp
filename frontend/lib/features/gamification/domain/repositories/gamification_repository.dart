import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/gamification_status_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/leaderboard_entity.dart';

abstract class GamificationRepository {
  Future<GamificationStatusEntity> getGamificationStatus();
  Future<List<DailyChallengeEntity>> getDailyChallenges(DateTime date);
  Future<void> evaluateDailyChallenges(DateTime date);
  Future<GamificationStatusEntity> claimXP(DailyChallengeEntity challenge);
  Future<int> getSavingsScoreBasisPoints();
  Future<bool> hasWeeklyIncome();
  Future<LeaderboardEntity> getLeaderboard({
    required String ageBand,
    required String householdBand,
    required int scoreBasisPoints,
  });
}
