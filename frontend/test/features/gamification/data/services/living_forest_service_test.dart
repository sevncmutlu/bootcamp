import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/gamification/data/services/daily_activity_engine.dart';
import 'package:maki_app/features/gamification/data/services/living_forest_service.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';

void main() {
  late AppDatabase database;
  late DailyActivityEngine activityEngine;
  late LivingForestService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    activityEngine = DailyActivityEngine(database);
    service = LivingForestService(database, activityEngine);
  });

  tearDown(() => database.close());

  test(
    'first and second distinct finance actions award once and build streak',
    () async {
      final day = DateTime(2026, 8, 1, 10);
      await activityEngine.addExpense(
        ExpensesCompanion.insert(
          title: 'Market',
          amount: 100,
          date: day,
          category: 'Market',
        ),
      );
      await activityEngine.addIncome(
        IncomesCompanion.insert(
          title: 'Gelir',
          amount: 1000,
          date: day,
          source: 'Maaş',
        ),
      );

      final snapshot = await service.load(now: day);

      expect(snapshot.xp, 30);
      expect(snapshot.seedBalance, 12);
      expect(snapshot.currentStreak, 1);
      expect(snapshot.completedDaysLast7, 1);
    },
  );

  test('receipt source is idempotent', () async {
    final receipt = ExpensesCompanion.insert(
      title: 'Maki Market',
      amount: 61,
      date: DateTime(2026, 8, 1),
      category: 'Market',
      sourceType: const Value('receipt'),
      sourceRef: const Value('job-123'),
    );

    final first = await activityEngine.addExpense(receipt);
    final second = await activityEngine.addExpense(receipt);

    expect(second, first);
    expect((await database.getAllExpenses()).length, 1);
    expect((await service.load(now: DateTime(2026, 8, 1))).xp, 25);
  });

  test('manual contribution moves route but does not award', () async {
    final goalId = await service.createGoal(
      title: 'Yeni bilgisayar',
      targetAmount: 10000,
    );
    await service.addContribution(
      goalId: goalId,
      amount: 1000,
      source: GoalContributionSource.manualUnverified,
    );

    final snapshot = await service.load(now: DateTime(2026, 8, 1));

    expect(snapshot.primaryGoal?.contributedAmount, 1000);
    expect(snapshot.xp, 0);
    expect(snapshot.seedBalance, 0);
  });

  test('active goal selection is atomic and preserves contributions', () async {
    final firstId = await service.createGoal(
      title: 'Bilgisayar',
      targetAmount: 50000,
    );
    final secondId = await service.createGoal(
      title: 'Tatil',
      targetAmount: 20000,
    );
    await service.addContribution(
      goalId: firstId,
      amount: 2500,
      source: GoalContributionSource.manualUnverified,
    );

    await service.selectPrimaryGoal(secondId);
    final snapshot = await service.load(now: DateTime(2026, 8, 1));

    expect(snapshot.primaryGoal?.id, secondId);
    expect(snapshot.goals.first.id, secondId);
    expect(snapshot.goals.first.isPrimary, isTrue);
    expect(
      snapshot.goals
          .singleWhere((goal) => goal.id == firstId)
          .contributedAmount,
      2500,
    );
  });

  test(
    'linked transaction contribution awards and cannot be linked twice',
    () async {
      final expenseId = await activityEngine.addExpense(
        ExpensesCompanion.insert(
          title: 'Hedef hesabı',
          amount: 500,
          date: DateTime(2026, 8, 1),
          category: 'Birikim',
        ),
      );
      final goalId = await service.createGoal(
        title: 'Kamera',
        targetAmount: 5000,
      );
      await service.addContribution(
        goalId: goalId,
        amount: 500,
        source: GoalContributionSource.linkedTransaction,
        sourceRef: 'expense:$expenseId',
        date: DateTime(2026, 8, 1),
      );

      expect(
        () => service.addContribution(
          goalId: goalId,
          amount: 500,
          source: GoalContributionSource.linkedTransaction,
          sourceRef: 'expense:$expenseId',
        ),
        throwsA(anything),
      );
      final snapshot = await service.load(now: DateTime(2026, 8, 1));
      expect(snapshot.xp, 70);
      expect(snapshot.seedBalance, 32);
    },
  );

  test('store purchase is atomic and updates inventory', () async {
    await database
        .into(database.forestWalletLedger)
        .insert(
          ForestWalletLedgerCompanion.insert(
            id: 'seed-fixture',
            amount: 100,
            reason: 'test',
            createdAt: DateTime(2026, 8, 1),
          ),
        );

    await service.buyItem('protection_leaf');
    final snapshot = await service.load(now: DateTime(2026, 8, 1));

    expect(snapshot.seedBalance, 10);
    expect(
      snapshot.store
          .singleWhere((item) => item.key == 'protection_leaf')
          .quantity,
      1,
    );
  });
}
