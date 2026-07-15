import 'package:maki_app/database/database.dart';

class GamificationService {
  final AppDatabase _db;

  GamificationService(this._db);

  /// Seeds daily challenges if they don't already exist for [date].
  Future<List<DailyChallenge>> getOrSeedDailyChallenges(DateTime date) async {
    final existing = await _db.getChallengesForDate(date);
    if (existing.isNotEmpty) {
      return existing;
    }

    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

  /// Automatically evaluates the active challenges against today's database records.
  Future<void> evaluateDailyChallenges(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Fetch today's transactions
    final allExpenses = await _db.getAllExpenses();
    final todayExpenses = allExpenses.where((e) => !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay)).toList();

    // Fetch active challenges
    final challenges = await getOrSeedDailyChallenges(date);

    for (final challenge in challenges) {
      // Skip if already completed
      if (challenge.isCompleted) continue;

      bool conditionMet = false;

      if (challenge.id.startsWith("cook_home_")) {
        // No restaurant/dining expenses today
        final hasRestaurant = todayExpenses.any(
          (e) => e.category.toLowerCase().contains("restaurant") || e.category.toLowerCase().contains("dining")
        );
        conditionMet = !hasRestaurant;
      } else if (challenge.id.startsWith("log_three_")) {
        // Logged at least 3 transactions
        conditionMet = todayExpenses.length >= 3;
      } else if (challenge.id.startsWith("no_shopping_")) {
        // No shopping or market category expenses
        final hasShopping = todayExpenses.any(
          (e) => e.category.toLowerCase().contains("shopping") || e.category.toLowerCase().contains("market")
        );
        conditionMet = !hasShopping;
      }

      if (conditionMet) {
        await _db.updateChallenge(
          challenge.copyWith(isCompleted: true),
        );
      }
    }
  }

  /// Claims XP reward for a completed challenge and updates level progress.
  /// Returns the updated UserGamificationState.
  Future<UserGamificationState> claimXP(DailyChallenge challenge) async {
    final state = await _db.getGamificationState();
    if (state == null) throw Exception("Gamification state not initialized");

    // Add XP reward
    int newXp = state.xp + challenge.xpReward;
    int newLevel = state.level;

    // Level up math: each level requires level * 100 XP
    while (newXp >= (newLevel * 100)) {
      newXp -= (newLevel * 100);
      newLevel += 1;
    }

    // Process badges based on level milestones
    final List<String> currentBadges = state.badges.isNotEmpty ? state.badges.split(",") : [];
    
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

    // Set reward to 0 to prevent re-claims
    await _db.updateChallenge(challenge.copyWith(xpReward: 0));

    return updatedState;
  }
}
