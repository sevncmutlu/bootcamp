import 'dart:async';

import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/gamification/data/services/daily_activity_engine.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_finance_core/maki_finance_core.dart';

final class LivingForestService {
  LivingForestService(this._database, this._activityEngine);

  final AppDatabase _database;
  final DailyActivityEngine _activityEngine;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  static const _catalog =
      <
        ({
          String key,
          String title,
          String description,
          int price,
          bool permanent,
        })
      >[
        (
          key: 'owl_guide',
          title: 'Baykuş rehber',
          description: 'Bugünün uygun olmayan görevini bir kez değiştirir.',
          price: 35,
          permanent: false,
        ),
        (
          key: 'rainwater',
          title: 'Yağmur suyu',
          description:
              'Sonraki benzersiz bakımın büyüme etkisine +2 puan verir.',
          price: 55,
          permanent: false,
        ),
        (
          key: 'protection_leaf',
          title: 'Koruma yaprağı',
          description: 'Kaçırılan tek bir günün serisini korur.',
          price: 90,
          permanent: false,
        ),
        (
          key: 'compass',
          title: 'Hedef pusulası',
          description: 'Ana hedefin en güvenli sonraki adımını öne çıkarır.',
          price: 280,
          permanent: true,
        ),
        (
          key: 'greenhouse',
          title: 'Orman serası',
          description: 'Seçili parselin dinlenme günündeki görünümünü korur.',
          price: 450,
          permanent: true,
        ),
        (
          key: 'mersin_garden',
          title: 'Mersin çiçeği bahçesi',
          description: 'Ormana kalıcı bir Akdeniz çiçekliği ekler.',
          price: 700,
          permanent: true,
        ),
      ];

  static LivingForestSnapshot initialSnapshot() => LivingForestSnapshot(
    xp: 0,
    level: 1,
    seedBalance: 0,
    currentStreak: 0,
    bestStreak: 0,
    completedDaysLast7: 0,
    progress: const ForestProgress(
      level: 1,
      growthPercent: 0,
      stage: ForestStage.seed,
    ),
    goals: const [],
    store: _catalog
        .map(
          (item) => ForestStoreItemView(
            key: item.key,
            title: item.title,
            description: item.description,
            price: item.price,
            quantity: 0,
            permanent: item.permanent,
          ),
        )
        .toList(growable: false),
    completedDays: const {},
  );

  Future<LivingForestSnapshot> load({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    await _settlePendingTransfers(clock);
    final status = await _database.getGamificationState();
    final wallet = await _database.select(_database.forestWalletLedger).get();
    final streak = await (_database.select(
      _database.forestStreakStates,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    final goals = await _goalViews();
    final activities = await _database
        .select(_database.dailyForestActivities)
        .get();
    final rawKinds = <String>{
      'expense',
      'income',
      'receipt',
      'goal_contribution',
      'debt_payment',
      'daily_review',
    };
    final completedDays = activities
        .where((entry) => rawKinds.contains(entry.activityType))
        .map(
          (entry) => DateTime(entry.day.year, entry.day.month, entry.day.day),
        )
        .toSet();
    final today = DateTime(clock.year, clock.month, clock.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final completedLast7 = completedDays
        .where((day) => !day.isBefore(weekStart) && !day.isAfter(today))
        .length;
    final primary = _primaryGoal(goals);
    final itemBonus = await _availableGrowthBonus();
    final progress = ForestProgressRules.calculate(
      totalXp: status?.xp ?? 0,
      streakDays: streak?.currentStreak ?? 0,
      completedDaysLast7: completedLast7,
      mainGoalMilestoneRatio: _milestoneRatio(primary?.rewardProgress ?? 0),
      itemBonus: itemBonus,
      previousHighWater: streak?.growthHighWater ?? 0,
    );
    if (progress.growthPercent > (streak?.growthHighWater ?? 0)) {
      await _writeGrowthHighWater(progress.growthPercent, streak);
    }
    final inventory = await _database.select(_database.forestInventory).get();
    final inventoryByKey = {for (final item in inventory) item.itemKey: item};
    return LivingForestSnapshot(
      xp: status?.xp ?? 0,
      level: progress.level,
      seedBalance: wallet.fold(0, (sum, entry) => sum + entry.amount),
      currentStreak: streak?.currentStreak ?? 0,
      bestStreak: streak?.bestStreak ?? 0,
      completedDaysLast7: completedLast7,
      progress: progress,
      goals: goals,
      completedDays: completedDays,
      store: _catalog
          .map(
            (item) => ForestStoreItemView(
              key: item.key,
              title: item.title,
              description: item.description,
              price: item.price,
              quantity: inventoryByKey[item.key]?.quantity ?? 0,
              permanent: item.permanent,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<String> createGoal({
    required String title,
    required double targetAmount,
    double startingAmount = 0,
    DateTime? targetDate,
    String iconKey = 'seedling',
    bool primary = false,
  }) async {
    if (title.trim().isEmpty || targetAmount <= 0 || startingAmount < 0) {
      throw ArgumentError('Hedef adı ve tutarı geçerli olmalı.');
    }
    final id = await _database.transaction(() async {
      final active = await (_database.select(
        _database.savingsGoals,
      )..where((row) => row.status.equals('active'))).get();
      if (active.length >= 4) {
        throw StateError('Aynı anda en fazla dört aktif hedef olabilir.');
      }
      if (primary || active.isEmpty) {
        await (_database.update(_database.savingsGoals)
              ..where((row) => row.status.equals('active')))
            .write(const SavingsGoalsCompanion(priority: Value(1)));
      }
      final id = 'goal-${DateTime.now().microsecondsSinceEpoch}';
      await _database
          .into(_database.savingsGoals)
          .insert(
            SavingsGoalsCompanion.insert(
              id: id,
              title: title.trim(),
              targetAmount: targetAmount,
              startingAmount: Value(startingAmount),
              targetDate: Value(targetDate),
              iconKey: Value(iconKey),
              priority: Value(primary || active.isEmpty ? 0 : active.length),
              rewardTargetHighWater: Value(targetAmount),
              createdAt: DateTime.now(),
            ),
          );
      return id;
    });
    _notifyChanged();
    return id;
  }

  Future<void> completeDailyReview(DateTime day) =>
      _activityEngine.recordDailyReview(day);

  Future<void> addContribution({
    required String goalId,
    required double amount,
    required GoalContributionSource source,
    String? sourceRef,
    String? note,
    DateTime? date,
  }) async {
    if (amount <= 0) throw ArgumentError('Katkı tutarı sıfırdan büyük olmalı.');
    final occurredAt = date ?? DateTime.now();
    await _database.transaction(() async {
      final goal = await (_database.select(
        _database.savingsGoals,
      )..where((row) => row.id.equals(goalId))).getSingleOrNull();
      if (goal == null || goal.status != 'active') {
        throw StateError('Aktif hedef bulunamadı.');
      }
      if (source == GoalContributionSource.linkedTransaction) {
        if (sourceRef == null || !await _financeSourceExists(sourceRef)) {
          throw StateError('Bağlanacak finans hareketi bulunamadı.');
        }
      }
      final id = 'contribution-${DateTime.now().microsecondsSinceEpoch}';
      final rewardStatus = switch (source) {
        GoalContributionSource.linkedTransaction => 'awarded',
        GoalContributionSource.confirmedTransfer => 'pending',
        _ => 'none',
      };
      await _database
          .into(_database.goalContributions)
          .insert(
            GoalContributionsCompanion.insert(
              id: id,
              goalId: goalId,
              amount: amount,
              date: occurredAt,
              note: Value(note?.trim()),
              sourceType: source.storageKey,
              sourceRef: Value(sourceRef),
              rewardStatus: Value(rewardStatus),
              createdAt: DateTime.now(),
            ),
          );
      if (rewardStatus == 'awarded') {
        await _activityEngine.recordGoalContribution(
          sourceRef: id,
          occurredAt: occurredAt,
        );
        await _awardReachedMilestones(goal, id);
      }
    });
    _notifyChanged();
  }

  Future<void> applyTransactionImpact({
    required String goalId,
    required String sourceRef,
    required double amount,
    required bool isExpense,
    required DateTime occurredAt,
  }) async {
    if (amount <= 0 || !await _financeSourceExists(sourceRef)) {
      throw ArgumentError(
        'Hedef etkisi için geçerli bir finans işlemi gerekli.',
      );
    }
    if (!isExpense) {
      await addContribution(
        goalId: goalId,
        amount: amount,
        source: GoalContributionSource.linkedTransaction,
        sourceRef: sourceRef,
        date: occurredAt,
        note: 'Gelir kaydından hedefe ayrıldı.',
      );
      return;
    }

    await _database.transaction(() async {
      final duplicate = await (_database.select(
        _database.goalContributions,
      )..where((row) => row.sourceRef.equals(sourceRef))).getSingleOrNull();
      if (duplicate != null) return;
      final goal = await (_database.select(
        _database.savingsGoals,
      )..where((row) => row.id.equals(goalId))).getSingleOrNull();
      if (goal == null || goal.status != 'active') {
        throw StateError('Aktif hedef bulunamadı.');
      }
      final contributions = await (_database.select(
        _database.goalContributions,
      )..where((row) => row.goalId.equals(goalId))).get();
      final saved =
          goal.startingAmount +
          contributions.fold<double>(0, (sum, item) => sum + item.amount);
      if (amount > saved) {
        throw StateError('Hedefte bu gideri karşılayacak kadar birikim yok.');
      }
      await _database
          .into(_database.goalContributions)
          .insert(
            GoalContributionsCompanion.insert(
              id: 'goal-impact-${DateTime.now().microsecondsSinceEpoch}',
              goalId: goalId,
              amount: -amount,
              date: occurredAt,
              note: const Value('Gider hedef birikiminden karşılandı.'),
              sourceType: GoalContributionSource.balanceAdjustment.storageKey,
              sourceRef: Value(sourceRef),
              rewardStatus: const Value('none'),
              createdAt: DateTime.now(),
            ),
          );
    });
    _notifyChanged();
  }

  Future<void> removeTransactionImpact(String sourceRef) async {
    final removed = await (_database.delete(
      _database.goalContributions,
    )..where((row) => row.sourceRef.equals(sourceRef))).go();
    if (removed > 0) _notifyChanged();
  }

  Future<void> buyItem(String itemKey) async {
    final definition = _catalog
        .where((item) => item.key == itemKey)
        .firstOrNull;
    if (definition == null) throw ArgumentError('Orman ürünü bulunamadı.');
    await _database.transaction(() async {
      final wallet = await _database.select(_database.forestWalletLedger).get();
      final balance = wallet.fold(0, (sum, entry) => sum + entry.amount);
      final current = await (_database.select(
        _database.forestInventory,
      )..where((row) => row.itemKey.equals(itemKey))).getSingleOrNull();
      if (definition.permanent && (current?.quantity ?? 0) > 0) {
        throw StateError('Bu kalıcı orman parçası zaten açık.');
      }
      if (balance < definition.price) {
        throw StateError('Bu ürün için yeterli tohum yok.');
      }
      final purchaseId =
          'purchase-$itemKey-${DateTime.now().microsecondsSinceEpoch}';
      await _database
          .into(_database.forestWalletLedger)
          .insert(
            ForestWalletLedgerCompanion.insert(
              id: purchaseId,
              amount: -definition.price,
              reason: 'store:$itemKey',
              createdAt: DateTime.now(),
            ),
          );
      await _database
          .into(_database.forestInventory)
          .insertOnConflictUpdate(
            ForestInventoryCompanion(
              itemKey: Value(itemKey),
              quantity: Value((current?.quantity ?? 0) + 1),
              equipped: Value(definition.permanent),
              selectedPlot: Value(current?.selectedPlot),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (itemKey == 'protection_leaf') await _addProtectionLeaf();
    });
  }

  Future<List<SavingsGoalView>> _goalViews() async {
    final goals =
        await (_database.select(_database.savingsGoals)
              ..where((row) => row.status.equals('active'))
              ..orderBy([(row) => OrderingTerm.asc(row.priority)]))
            .get();
    final contributions = await _database
        .select(_database.goalContributions)
        .get();
    return goals
        .map((goal) {
          final contributed = contributions
              .where((entry) => entry.goalId == goal.id)
              .fold<double>(0, (sum, entry) => sum + entry.amount);
          return SavingsGoalView(
            id: goal.id,
            title: goal.title,
            targetAmount: goal.targetAmount,
            startingAmount: goal.startingAmount,
            contributedAmount: contributed,
            isPrimary: goal.priority == 0,
            iconKey: goal.iconKey,
            targetDate: goal.targetDate,
          );
        })
        .toList(growable: false);
  }

  Future<void> _settlePendingTransfers(DateTime now) async {
    final pending = await (_database.select(
      _database.goalContributions,
    )..where((row) => row.rewardStatus.equals('pending'))).get();
    for (final entry in pending) {
      if (now.difference(entry.createdAt) < const Duration(hours: 24)) continue;
      await _database.transaction(() async {
        await (_database.update(
          _database.goalContributions,
        )..where((row) => row.id.equals(entry.id))).write(
          const GoalContributionsCompanion(rewardStatus: Value('awarded')),
        );
        await _activityEngine.recordGoalContribution(
          sourceRef: entry.id,
          occurredAt: entry.date,
        );
        final goal = await (_database.select(
          _database.savingsGoals,
        )..where((row) => row.id.equals(entry.goalId))).getSingle();
        await _awardReachedMilestones(goal, entry.id);
      });
    }
  }

  Future<void> _awardReachedMilestones(
    SavingsGoal goal,
    String sourceRef,
  ) async {
    final contributions =
        await (_database.select(_database.goalContributions)
              ..where((row) => row.goalId.equals(goal.id))
              ..where((row) => row.rewardStatus.equals('awarded')))
            .get();
    final total = contributions.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final rewardTarget = goal.rewardTargetHighWater <= 0
        ? goal.targetAmount
        : goal.rewardTargetHighWater;
    final percent = rewardTarget <= 0 ? 0 : total / rewardTarget;
    const milestones = <({double ratio, int percent, ForestActivityType type})>[
      (ratio: 0.10, percent: 10, type: ForestActivityType.goal10),
      (ratio: 0.25, percent: 25, type: ForestActivityType.goal25),
      (ratio: 0.50, percent: 50, type: ForestActivityType.goal50),
      (ratio: 0.75, percent: 75, type: ForestActivityType.goal75),
      (ratio: 1.00, percent: 100, type: ForestActivityType.goal100),
    ];
    for (final milestone in milestones) {
      if (percent < milestone.ratio) continue;
      final awardId = '${goal.id}:${milestone.percent}';
      final existing = await (_database.select(
        _database.goalMilestoneAwards,
      )..where((row) => row.id.equals(awardId))).getSingleOrNull();
      if (existing != null) continue;
      await _database
          .into(_database.goalMilestoneAwards)
          .insert(
            GoalMilestoneAwardsCompanion.insert(
              id: awardId,
              goalId: goal.id,
              milestonePercent: milestone.percent,
              targetHighWater: rewardTarget,
              createdAt: DateTime.now(),
            ),
          );
      final xp = ForestProgressRules.xpRewards[milestone.type] ?? 0;
      final seeds = ForestProgressRules.seedRewards[milestone.type] ?? 0;
      await _database
          .into(_database.forestXpLedger)
          .insert(
            ForestXpLedgerCompanion.insert(
              id: 'xp:milestone:$awardId',
              amount: xp,
              reason: milestone.type.name,
              sourceRef: Value(sourceRef),
              createdAt: DateTime.now(),
            ),
          );
      await _database
          .into(_database.forestWalletLedger)
          .insert(
            ForestWalletLedgerCompanion.insert(
              id: 'seed:milestone:$awardId',
              amount: seeds,
              reason: milestone.type.name,
              sourceRef: Value(sourceRef),
              createdAt: DateTime.now(),
            ),
          );
    }
    await _syncXp();
  }

  Future<bool> _financeSourceExists(String sourceRef) async {
    if (sourceRef.startsWith('expense:')) {
      final id = int.tryParse(sourceRef.substring('expense:'.length));
      if (id == null) return false;
      return (_database.select(_database.expenses)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull()
          .then((value) => value != null);
    }
    if (sourceRef.startsWith('income:')) {
      final id = int.tryParse(sourceRef.substring('income:'.length));
      if (id == null) return false;
      return (_database.select(_database.incomes)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull()
          .then((value) => value != null);
    }
    return false;
  }

  Future<double> _availableGrowthBonus() async {
    final rainwater = await (_database.select(
      _database.forestInventory,
    )..where((row) => row.itemKey.equals('rainwater'))).getSingleOrNull();
    return (rainwater?.quantity ?? 0) > 0 ? 2 : 0;
  }

  Future<void> _writeGrowthHighWater(
    double growth,
    ForestStreakState? state,
  ) async {
    await _database
        .into(_database.forestStreakStates)
        .insertOnConflictUpdate(
          ForestStreakStatesCompanion(
            id: const Value(1),
            currentStreak: Value(state?.currentStreak ?? 0),
            bestStreak: Value(state?.bestStreak ?? 0),
            lastCompletedDay: Value(state?.lastCompletedDay),
            protectionLeaves: Value(state?.protectionLeaves ?? 0),
            growthHighWater: Value(growth),
          ),
        );
  }

  Future<void> _addProtectionLeaf() async {
    final state = await (_database.select(
      _database.forestStreakStates,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    await _database
        .into(_database.forestStreakStates)
        .insertOnConflictUpdate(
          ForestStreakStatesCompanion(
            id: const Value(1),
            currentStreak: Value(state?.currentStreak ?? 0),
            bestStreak: Value(state?.bestStreak ?? 0),
            lastCompletedDay: Value(state?.lastCompletedDay),
            protectionLeaves: Value((state?.protectionLeaves ?? 0) + 1),
            growthHighWater: Value(state?.growthHighWater ?? 0),
          ),
        );
  }

  Future<void> _syncXp() async {
    final entries = await _database.select(_database.forestXpLedger).get();
    final xp = entries
        .fold<int>(0, (sum, entry) => sum + entry.amount)
        .clamp(0, 1 << 30)
        .toInt();
    final current = await _database.getGamificationState();
    if (current == null) return;
    await _database.updateGamificationState(
      current.copyWith(xp: xp, level: ForestProgressRules.levelForXp(xp)),
    );
  }

  SavingsGoalView? _primaryGoal(List<SavingsGoalView> goals) {
    for (final goal in goals) {
      if (goal.isPrimary) return goal;
    }
    return goals.isEmpty ? null : goals.first;
  }

  double _milestoneRatio(double progress) {
    if (progress >= 1) return 1;
    if (progress >= 0.75) return 0.75;
    if (progress >= 0.5) return 0.5;
    if (progress >= 0.25) return 0.25;
    if (progress >= 0.1) return 0.1;
    return 0;
  }

  void _notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
