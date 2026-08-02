import 'package:maki_finance_core/maki_finance_core.dart';

enum GoalContributionSource {
  manualUnverified('manual_unverified'),
  linkedTransaction('linked_transaction'),
  confirmedTransfer('confirmed_transfer'),
  balanceAdjustment('balance_adjustment');

  const GoalContributionSource(this.storageKey);

  final String storageKey;
}

final class SavingsGoalView {
  const SavingsGoalView({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.startingAmount,
    required this.contributedAmount,
    required this.isPrimary,
    required this.iconKey,
    required this.targetDate,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double startingAmount;
  final double contributedAmount;
  final bool isPrimary;
  final String iconKey;
  final DateTime? targetDate;

  double get totalSaved =>
      (startingAmount + contributedAmount).clamp(0, targetAmount).toDouble();
  double get progress => targetAmount <= 0
      ? 0
      : (totalSaved / targetAmount).clamp(0, 1).toDouble();
  double get rewardProgress => targetAmount <= 0
      ? 0
      : (contributedAmount / targetAmount).clamp(0, 1).toDouble();
  double get remaining => (targetAmount - totalSaved).clamp(0, targetAmount);
}

final class ForestStoreItemView {
  const ForestStoreItemView({
    required this.key,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.permanent,
  });

  final String key;
  final String title;
  final String description;
  final int price;
  final int quantity;
  final bool permanent;
}

final class LivingForestSnapshot {
  const LivingForestSnapshot({
    required this.xp,
    required this.level,
    required this.seedBalance,
    required this.currentStreak,
    required this.bestStreak,
    required this.completedDaysLast7,
    required this.progress,
    required this.goals,
    required this.store,
    required this.completedDays,
  });

  final int xp;
  final int level;
  final int seedBalance;
  final int currentStreak;
  final int bestStreak;
  final int completedDaysLast7;
  final ForestProgress progress;
  final List<SavingsGoalView> goals;
  final List<ForestStoreItemView> store;
  final Set<DateTime> completedDays;

  SavingsGoalView? get primaryGoal {
    for (final goal in goals) {
      if (goal.isPrimary) return goal;
    }
    return goals.isEmpty ? null : goals.first;
  }
}
