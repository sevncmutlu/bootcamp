import 'package:maki_app/database/database.dart';

class GamificationService {
  final AppDatabase _db;

  GamificationService(this._db);

  Future<List<DailyChallenge>> getOrSeedDailyChallenges(DateTime date) async {
    final existing = await _db.getChallengesForDate(date);
    if (existing.isNotEmpty) {
      return existing;
    }

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final challenges = [
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
    ];

    for (final c in challenges) {
      await _db.insertChallenge(c);
    }

    return challenges;
  }

  Future<void> evaluateDailyChallenges(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final allExpenses = await _db.getAllExpenses();
    final todayExpenses = allExpenses
        .where((e) => !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay))
        .toList();

    final challenges = await getOrSeedDailyChallenges(date);

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
        conditionMet = todayExpenses.length >= 3;
      } else if (challenge.id.startsWith("no_shopping_")) {
        final hasShopping = todayExpenses.any(
          (e) =>
              e.category.toLowerCase().contains("shopping") ||
              e.category.toLowerCase().contains("market") ||
              e.category.toLowerCase().contains("alışveriş"),
        );
        conditionMet = !hasShopping;
      }

      if (conditionMet) {
        await _db.updateChallenge(challenge.copyWith(isCompleted: true));
      }
    }
  }

  Future<UserGamificationState> claimXP(DailyChallenge challenge) async {
    final state = await _db.getGamificationState();
    if (state == null) {
      throw StateError('Oyunlaştırma durumu başlatılmadı.');
    }

    int newXp = state.xp + challenge.xpReward;
    int newLevel = state.level;

    while (newXp >= (newLevel * 100)) {
      newXp -= (newLevel * 100);
      newLevel += 1;
    }

    final List<String> currentBadges = state.badges.isNotEmpty
        ? state.badges.split(",")
        : [];

    if (newLevel >= 1 && !currentBadges.contains("badgeSavingsSeed")) {
      currentBadges.add("badgeSavingsSeed");
    }
    if (newLevel >= 3 && !currentBadges.contains("badgeBudgetMaster")) {
      currentBadges.add("badgeBudgetMaster");
    }
    if (newLevel >= 5 && !currentBadges.contains("badgeOakGuardian")) {
      currentBadges.add("badgeOakGuardian");
    }

    final updatedState = state.copyWith(
      level: newLevel,
      xp: newXp,
      badges: currentBadges.join(","),
    );

    await _db.updateGamificationState(updatedState);

    await _db.updateChallenge(challenge.copyWith(xpReward: 0));

    return updatedState;
  }
}
