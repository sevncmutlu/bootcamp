import 'package:maki_app/core/database/database.dart';

abstract class GamificationLocalDataSource {
  Future<List<DailyChallenge>> getOrSeedDailyChallenges(DateTime date);
  Future<UserGamificationState> getGamificationStatus();
  Future<void> updateGamificationStatus(UserGamificationState status);
  Future<void> updateChallenge(DailyChallenge challenge);
}

class GamificationLocalDataSourceImpl implements GamificationLocalDataSource {
  final AppDatabase _db;

  GamificationLocalDataSourceImpl(this._db);

  @override
  Future<List<DailyChallenge>> getOrSeedDailyChallenges(DateTime date) async {
    final existing = await _db.getChallengesForDate(date);
    if (existing.length >= 7) {
      return existing;
    }

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final allCandidates = [
      DailyChallenge(
        id: "cook_home_$dateStr",
        titleKey: "challengeCookHome",
        descKey: "challengeCookHomeDesc",
        xpReward: 25,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "log_three_$dateStr",
        titleKey: "challengeLogThree",
        descKey: "challengeLogThreeDesc",
        xpReward: 20,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "no_shopping_$dateStr",
        titleKey: "challengeNoShopping",
        descKey: "challengeNoShoppingDesc",
        xpReward: 30,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "income_achiever_$dateStr",
        titleKey: "challengeIncomeAchiever",
        descKey: "challengeIncomeAchieverDesc",
        xpReward: 25,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "learn_budget_$dateStr",
        titleKey: "challengeLearnBudget",
        descKey: "challengeLearnBudgetDesc",
        xpReward: 15,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "save_ten_$dateStr",
        titleKey: "challengeSaveTen",
        descKey: "challengeSaveTenDesc",
        xpReward: 35,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "review_subs_$dateStr",
        titleKey: "challengeReviewSubs",
        descKey: "challengeReviewSubsDesc",
        xpReward: 40,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "meal_prep_$dateStr",
        titleKey: "challengeMealPrep",
        descKey: "challengeMealPrepDesc",
        xpReward: 30,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "walk_instead_$dateStr",
        titleKey: "challengeWalk",
        descKey: "challengeWalkDesc",
        xpReward: 20,
        isCompleted: false,
        date: date,
      ),
    ];

    allCandidates.shuffle();
    final toInsert = allCandidates.take(7 - existing.length).toList();

    for (final challenge in toInsert) {
      await _db.insertChallenge(challenge);
    }

    return _db.getChallengesForDate(date);
  }

  @override
  Future<UserGamificationState> getGamificationStatus() async {
    var status = await _db.getGamificationState();
    if (status == null) {
      status = const UserGamificationState(
        id: 1,
        xp: 0,
        level: 1,
        badges: '',
      );
      await _db.updateGamificationState(status);
    }
    return status;
  }

  @override
  Future<void> updateGamificationStatus(UserGamificationState status) async {
    await _db.updateGamificationState(status);
  }

  @override
  Future<void> updateChallenge(DailyChallenge challenge) async {
    await _db.updateChallenge(challenge);
  }
}
