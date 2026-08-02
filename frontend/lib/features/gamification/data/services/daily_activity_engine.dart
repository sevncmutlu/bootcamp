import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_finance_core/maki_finance_core.dart';

final class DailyActivityEngine {
  DailyActivityEngine(this._database);

  final AppDatabase _database;

  Future<int> addExpense(ExpensesCompanion expense) {
    return _database.transaction(() async {
      final sourceRef = expense.sourceRef.present
          ? expense.sourceRef.value
          : null;
      if (sourceRef != null) {
        final existing = await (_database.select(
          _database.expenses,
        )..where((row) => row.sourceRef.equals(sourceRef))).getSingleOrNull();
        if (existing != null) return existing.id;
      }
      final id = await _database.into(_database.expenses).insert(expense);
      final date = expense.date.value;
      final sourceType = expense.sourceType.present
          ? expense.sourceType.value
          : 'manual';
      await _recordMeaningful(
        kind: sourceType == 'receipt' ? 'receipt' : 'expense',
        occurredAt: date,
        sourceRef: sourceRef ?? 'expense:$id',
        bonus: sourceType == 'receipt'
            ? ForestActivityType.trustedReceipt
            : null,
      );
      return id;
    });
  }

  Future<int> addIncome(IncomesCompanion income) {
    return _database.transaction(() async {
      final id = await _database.into(_database.incomes).insert(income);
      await _recordMeaningful(
        kind: 'income',
        occurredAt: income.date.value,
        sourceRef: 'income:$id',
      );
      return id;
    });
  }

  Future<void> recordDailyReview(DateTime occurredAt) {
    return _database.transaction(() async {
      await _recordMeaningful(
        kind: 'daily_review',
        occurredAt: occurredAt,
        sourceRef: 'daily-review:${_dayKey(occurredAt)}',
        bonus: ForestActivityType.dailyReview,
      );
    });
  }

  Future<void> recordGoalContribution({
    required String sourceRef,
    required DateTime occurredAt,
  }) => _recordMeaningful(
    kind: 'goal_contribution',
    occurredAt: occurredAt,
    sourceRef: sourceRef,
    bonus: ForestActivityType.verifiedGoalContribution,
  );

  Future<void> recordDebtPayment({
    required String sourceRef,
    required DateTime occurredAt,
  }) => _recordMeaningful(
    kind: 'debt_payment',
    occurredAt: occurredAt,
    sourceRef: sourceRef,
    bonus: ForestActivityType.verifiedDebtPayment,
  );

  Future<void> _recordMeaningful({
    required String kind,
    required DateTime occurredAt,
    required String sourceRef,
    ForestActivityType? bonus,
  }) async {
    final day = DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
    final end = day.add(const Duration(days: 1));
    final existing =
        await (_database.select(_database.dailyForestActivities)
              ..where((row) => row.day.isBiggerOrEqualValue(day))
              ..where((row) => row.day.isSmallerThanValue(end)))
            .get();
    final rawId = '${_dayKey(day)}:raw:$sourceRef';
    if (existing.any((entry) => entry.id == rawId)) return;

    await _database
        .into(_database.dailyForestActivities)
        .insert(
          DailyForestActivitiesCompanion.insert(
            id: rawId,
            day: day,
            activityType: kind,
            sourceRef: Value(sourceRef),
            createdAt: occurredAt,
          ),
        );

    const rawKinds = <String>{
      'expense',
      'income',
      'receipt',
      'goal_contribution',
      'debt_payment',
      'daily_review',
    };
    final previousKinds = existing
        .where((entry) => rawKinds.contains(entry.activityType))
        .map((entry) => entry.activityType)
        .toSet();
    if (previousKinds.isEmpty) {
      await _award(
        day,
        ForestActivityType.firstMeaningfulAction,
        sourceRef: sourceRef,
      );
      await _updateStreak(day);
    } else if (!previousKinds.contains(kind) &&
        !existing.any(
          (entry) =>
              entry.activityType ==
              ForestActivityType.secondDistinctAction.name,
        )) {
      await _award(
        day,
        ForestActivityType.secondDistinctAction,
        sourceRef: sourceRef,
      );
    }
    if (bonus != null &&
        !existing.any((entry) => entry.activityType == bonus.name)) {
      await _award(day, bonus, sourceRef: sourceRef);
    }
    await _synchronizeGamificationState();
  }

  Future<void> _award(
    DateTime day,
    ForestActivityType type, {
    required String sourceRef,
  }) async {
    final id = '${_dayKey(day)}:${type.name}';
    final exists = await (_database.select(
      _database.dailyForestActivities,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (exists != null) return;

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final monday = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    final dayTotals = await _activityTotals(dayStart, dayEnd);
    final weekTotals = await _activityTotals(monday, dayEnd);
    final rawXp = ForestProgressRules.xpRewards[type] ?? 0;
    final rawSeeds = ForestProgressRules.seedRewards[type] ?? 0;
    final xp = rawXp.clamp(0, (50 - dayTotals.xp).clamp(0, 50)).toInt();
    final weeklyXp = xp.clamp(0, (280 - weekTotals.xp).clamp(0, 280)).toInt();
    final seeds = rawSeeds
        .clamp(0, (20 - dayTotals.seeds).clamp(0, 20))
        .toInt();
    final weeklySeeds = seeds
        .clamp(0, (180 - weekTotals.seeds).clamp(0, 180))
        .toInt();

    await _database
        .into(_database.dailyForestActivities)
        .insert(
          DailyForestActivitiesCompanion.insert(
            id: id,
            day: day,
            activityType: type.name,
            sourceRef: Value(sourceRef),
            xpAward: Value(weeklyXp),
            seedAward: Value(weeklySeeds),
            createdAt: DateTime.now(),
          ),
        );
    if (weeklyXp > 0) {
      await _database
          .into(_database.forestXpLedger)
          .insert(
            ForestXpLedgerCompanion.insert(
              id: 'xp:$id',
              amount: weeklyXp,
              reason: type.name,
              sourceRef: Value(id),
              createdAt: DateTime.now(),
            ),
          );
    }
    if (weeklySeeds > 0) {
      await _database
          .into(_database.forestWalletLedger)
          .insert(
            ForestWalletLedgerCompanion.insert(
              id: 'seed:$id',
              amount: weeklySeeds,
              reason: type.name,
              sourceRef: Value(id),
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  Future<({int xp, int seeds})> _activityTotals(
    DateTime start,
    DateTime end,
  ) async {
    final activities =
        await (_database.select(_database.dailyForestActivities)
              ..where((row) => row.day.isBiggerOrEqualValue(start))
              ..where((row) => row.day.isSmallerThanValue(end)))
            .get();
    return (
      xp: activities.fold(0, (sum, entry) => sum + entry.xpAward),
      seeds: activities.fold(0, (sum, entry) => sum + entry.seedAward),
    );
  }

  Future<void> _updateStreak(DateTime day) async {
    final state = await (_database.select(
      _database.forestStreakStates,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    var current = 1;
    var best = state?.bestStreak ?? 0;
    var leaves = state?.protectionLeaves ?? 0;
    final previous = state?.lastCompletedDay;
    if (previous != null) {
      final previousDay = DateTime(previous.year, previous.month, previous.day);
      final distance = day.difference(previousDay).inDays;
      if (distance <= 0) return;
      if (distance == 1) {
        current = (state?.currentStreak ?? 0) + 1;
      } else if (distance == 2 && leaves > 0) {
        current = (state?.currentStreak ?? 0) + 1;
        leaves -= 1;
      }
    }
    if (current > best) best = current;
    await _database
        .into(_database.forestStreakStates)
        .insertOnConflictUpdate(
          ForestStreakStatesCompanion(
            id: const Value(1),
            currentStreak: Value(current),
            bestStreak: Value(best),
            lastCompletedDay: Value(day),
            protectionLeaves: Value(leaves),
            growthHighWater: Value(state?.growthHighWater ?? 0),
          ),
        );
  }

  Future<void> _synchronizeGamificationState() async {
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

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
