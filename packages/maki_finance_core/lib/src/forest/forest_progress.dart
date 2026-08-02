enum ForestActivityType {
  firstMeaningfulAction,
  secondDistinctAction,
  dailyReview,
  trustedReceipt,
  verifiedGoalContribution,
  verifiedDebtPayment,
  weeklyReview,
  streak7,
  streak30,
  streak100,
  goal10,
  goal25,
  goal50,
  goal75,
  goal100,
}

enum ForestStage { seed, sprout, sapling, matureTree, grove }

final class ForestProgress {
  const ForestProgress({
    required this.level,
    required this.growthPercent,
    required this.stage,
  });

  final int level;
  final double growthPercent;
  final ForestStage stage;
}

abstract final class ForestProgressRules {
  static const List<int> levelThresholds = <int>[
    0,
    100,
    250,
    450,
    700,
    1000,
    1400,
    1900,
    2500,
    3200,
    4000,
    4900,
    5900,
    7000,
    8200,
    9500,
    10900,
    12400,
    14000,
    15700,
  ];

  static const Map<ForestActivityType, int> xpRewards = {
    ForestActivityType.firstMeaningfulAction: 20,
    ForestActivityType.secondDistinctAction: 10,
    ForestActivityType.dailyReview: 10,
    ForestActivityType.trustedReceipt: 5,
    ForestActivityType.verifiedGoalContribution: 15,
    ForestActivityType.verifiedDebtPayment: 15,
    ForestActivityType.weeklyReview: 30,
    ForestActivityType.streak7: 40,
    ForestActivityType.streak30: 120,
    ForestActivityType.streak100: 300,
    ForestActivityType.goal10: 25,
    ForestActivityType.goal25: 50,
    ForestActivityType.goal50: 100,
    ForestActivityType.goal75: 150,
    ForestActivityType.goal100: 250,
  };

  static const Map<ForestActivityType, int> seedRewards = {
    ForestActivityType.firstMeaningfulAction: 8,
    ForestActivityType.secondDistinctAction: 4,
    ForestActivityType.dailyReview: 4,
    ForestActivityType.trustedReceipt: 3,
    ForestActivityType.verifiedGoalContribution: 5,
    ForestActivityType.weeklyReview: 18,
    ForestActivityType.streak7: 20,
    ForestActivityType.streak30: 60,
    ForestActivityType.streak100: 160,
    ForestActivityType.goal10: 15,
    ForestActivityType.goal25: 25,
    ForestActivityType.goal50: 40,
    ForestActivityType.goal75: 60,
    ForestActivityType.goal100: 100,
  };

  static int levelForXp(int xp) {
    final safeXp = xp < 0 ? 0 : xp;
    for (var index = levelThresholds.length - 1; index >= 0; index--) {
      if (safeXp >= levelThresholds[index]) return index + 1;
    }
    return 1;
  }

  static ForestProgress calculate({
    required int totalXp,
    required int streakDays,
    required int completedDaysLast7,
    required double mainGoalMilestoneRatio,
    double itemBonus = 0,
    double previousHighWater = 0,
  }) {
    final xpRatio = (totalXp / 3200).clamp(0, 1).toDouble();
    final streakRatio = (streakDays / 30).clamp(0, 1).toDouble();
    final weeklyRatio = (completedDaysLast7 / 7).clamp(0, 1).toDouble();
    final goalRatio = mainGoalMilestoneRatio.clamp(0, 1).toDouble();
    final safeBonus = itemBonus.clamp(0, 10).toDouble();
    final raw =
        100 *
            (0.40 * xpRatio +
                0.25 * streakRatio +
                0.20 * weeklyRatio +
                0.15 * goalRatio) +
        safeBonus;
    final growth = raw.clamp(previousHighWater, 100).toDouble();
    return ForestProgress(
      level: levelForXp(totalXp),
      growthPercent: growth,
      stage: stageForGrowth(growth),
    );
  }

  static ForestStage stageForGrowth(double growthPercent) {
    if (growthPercent < 20) return ForestStage.seed;
    if (growthPercent < 40) return ForestStage.sprout;
    if (growthPercent < 65) return ForestStage.sapling;
    if (growthPercent < 85) return ForestStage.matureTree;
    return ForestStage.grove;
  }
}
