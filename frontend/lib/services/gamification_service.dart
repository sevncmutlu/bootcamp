import 'dart:math';
import 'package:maki_app/database/database.dart';

class GamificationService {
  final AppDatabase _db;

  GamificationService(this._db);

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
        id: "coffee_saver_$dateStr",
        titleKey: "challengeCoffeeSaver",
        descKey: "challengeCoffeeSaverDesc",
        xpReward: 20,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "super_saver_$dateStr",
        titleKey: "challengeSuperSaver",
        descKey: "challengeSuperSaverDesc",
        xpReward: 50,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "commute_smart_$dateStr",
        titleKey: "challengeCommuteSmart",
        descKey: "challengeCommuteSmartDesc",
        xpReward: 25,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "entertainment_control_$dateStr",
        titleKey: "challengeEntertainmentControl",
        descKey: "challengeEntertainmentControlDesc",
        xpReward: 30,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "subscription_audit_$dateStr",
        titleKey: "challengeSubscriptionAudit",
        descKey: "challengeSubscriptionAuditDesc",
        xpReward: 35,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "budget_guardian_$dateStr",
        titleKey: "challengeBudgetGuardian",
        descKey: "challengeBudgetGuardianDesc",
        xpReward: 40,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "micro_saver_$dateStr",
        titleKey: "challengeMicroSaver",
        descKey: "challengeMicroSaverDesc",
        xpReward: 15,
        isCompleted: false,
        date: date,
      ),
      DailyChallenge(
        id: "weekly_reviewer_$dateStr",
        titleKey: "challengeWeeklyReviewer",
        descKey: "challengeWeeklyReviewerDesc",
        xpReward: 20,
        isCompleted: false,
        date: date,
      ),
    ];

    final existingIds = existing.map((e) => e.id).toSet();
    final missingCandidates =
        allCandidates.where((c) => !existingIds.contains(c.id)).toList();

    final rng = Random(date.year * 10000 + date.month * 100 + date.day);
    missingCandidates.shuffle(rng);

    final neededCount = 7 - existing.length;
    final toAdd = missingCandidates.take(neededCount).toList();

    for (final c in toAdd) {
      await _db.insertChallenge(c);
    }

    return await _db.getChallengesForDate(date);
  }

  Future<void> evaluateDailyChallenges(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final allExpenses = await _db.getAllExpenses();
    final allIncomes = await _db.getAllIncomes();

    final todayExpenses = allExpenses
        .where((e) => !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay))
        .toList();

    final todayIncomes = allIncomes
        .where((i) => !i.date.isBefore(startOfDay) && !i.date.isAfter(endOfDay))
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
            .fold(0.0, (s, e) => s + e.amount);
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
            .fold(0.0, (s, e) => s + e.amount);
        conditionMet = subTotal <= 100;
      } else if (challenge.id.startsWith("budget_guardian_")) {
        final dailyTotal = todayExpenses.fold(0.0, (s, e) => s + e.amount);
        conditionMet = dailyTotal <= 500;
      } else if (challenge.id.startsWith("micro_saver_")) {
        conditionMet = todayExpenses.any((e) => e.amount < 50) || todayIncomes.any((i) => i.amount < 50);
      } else if (challenge.id.startsWith("weekly_reviewer_")) {
        final distinctCategories = {
          ...todayExpenses.map((e) => e.category),
          ...todayIncomes.map((i) => i.source),
        };
        conditionMet = distinctCategories.length >= 3;
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

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final allExpenses = await _db.getAllExpenses();
    final allIncomes = await _db.getAllIncomes();
    final activeDays = {
      ...allExpenses
          .where((e) => e.date.isAfter(sevenDaysAgo))
          .map((e) => "${e.date.year}-${e.date.month}-${e.date.day}"),
      ...allIncomes
          .where((i) => i.date.isAfter(sevenDaysAgo))
          .map((i) => "${i.date.year}-${i.date.month}-${i.date.day}"),
    };

    final streakBonus = activeDays.length >= 7 ? 50 : 0;
    int newXp = state.xp + challenge.xpReward + streakBonus;
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
