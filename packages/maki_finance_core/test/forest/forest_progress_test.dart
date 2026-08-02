import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

void main() {
  test('level thresholds are exact and monotonic', () {
    expect(ForestProgressRules.levelForXp(0), 1);
    expect(ForestProgressRules.levelForXp(99), 1);
    expect(ForestProgressRules.levelForXp(100), 2);
    expect(ForestProgressRules.levelForXp(3200), 10);
    expect(ForestProgressRules.levelForXp(15700), 20);
    expect(ForestProgressRules.levelForXp(999999), 20);
  });

  test('growth formula combines finance behavior deterministically', () {
    final progress = ForestProgressRules.calculate(
      totalXp: 1600,
      streakDays: 15,
      completedDaysLast7: 7,
      mainGoalMilestoneRatio: 0.5,
    );

    expect(progress.growthPercent, closeTo(60, 0.001));
    expect(progress.stage, ForestStage.sapling);
  });

  test('high-water mark prevents visual regression and bonus is capped', () {
    final progress = ForestProgressRules.calculate(
      totalXp: 0,
      streakDays: 0,
      completedDaysLast7: 0,
      mainGoalMilestoneRatio: 0,
      itemBonus: 99,
      previousHighWater: 72,
    );

    expect(progress.growthPercent, 72);
    expect(progress.stage, ForestStage.matureTree);
  });
}
