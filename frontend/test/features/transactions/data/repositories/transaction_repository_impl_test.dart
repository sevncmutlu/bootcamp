import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/gamification/data/services/daily_activity_engine.dart';
import 'package:maki_app/features/gamification/data/services/living_forest_service.dart';
import 'package:maki_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';

void main() {
  late AppDatabase database;
  late TransactionRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TransactionRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('TransactionRepositoryImpl', () {
    test('seedCategories seeds default categories', () async {
      await repository.seedCategories();
      final categories = await repository.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name == 'Market'), isTrue);
      expect(categories.any((c) => c.name == 'Restoran'), isTrue);
    });

    test(
      'addExpense inserts an expense and watchExpenses streams it',
      () async {
        final expense = ExpenseEntity(
          id: 1,
          title: 'Test Expense',
          amount: 50.0,
          date: DateTime(2023, 1, 1),
          category: 'Food',
          notes: 'Test notes',
        );

        await repository.addExpense(expense);

        final stream = repository.watchExpenses();

        expect(
          stream,
          emitsInOrder([
            isA<List<ExpenseEntity>>()
                .having((list) => list.length, 'length', 1)
                .having((list) => list.first.title, 'title', 'Test Expense'),
          ]),
        );
      },
    );

    test('addIncome inserts an income and watchIncomes streams it', () async {
      final income = IncomeEntity(
        id: 1,
        title: 'Test Income',
        amount: 100.0,
        date: DateTime(2023, 1, 1),
        source: 'Salary',
        notes: 'Test notes',
      );

      await repository.addIncome(income);

      final stream = repository.watchIncomes();

      expect(
        stream,
        emitsInOrder([
          isA<List<IncomeEntity>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.title, 'title', 'Test Income'),
        ]),
      );
    });

    test('deleteExpense removes the expense', () async {
      final expense = ExpenseEntity(
        id: 1, // Auto-increment will likely give it 1 in an empty DB
        title: 'Test Expense',
        amount: 50.0,
        date: DateTime(2023, 1, 1),
        category: 'Food',
        notes: 'Test notes',
      );

      await repository.addExpense(expense);

      // Allow database to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await repository.deleteExpense(1);

      final stream = repository.watchExpenses();
      expect(stream, emits(isEmpty));
    });

    test('deleteIncome removes the income', () async {
      final income = IncomeEntity(
        id: 1,
        title: 'Test Income',
        amount: 100.0,
        date: DateTime(2023, 1, 1),
        source: 'Salary',
        notes: 'Test notes',
      );

      await repository.addIncome(income);

      // Allow database to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await repository.deleteIncome(1);

      final stream = repository.watchIncomes();
      expect(stream, emits(isEmpty));
    });

    test(
      'yalnızca açıkça bağlanan gelir ve gider hedef yolunu etkiler',
      () async {
        final engine = DailyActivityEngine(database);
        final forest = LivingForestService(database, engine);
        final linkedRepository = TransactionRepositoryImpl(
          database,
          activityEngine: engine,
          livingForestService: forest,
        );
        final goalId = await forest.createGoal(
          title: 'Yeni bilgisayar',
          targetAmount: 10000,
          primary: true,
        );

        await linkedRepository.addIncome(
          IncomeEntity(
            title: 'Maaş',
            amount: 500,
            date: DateTime(2026, 8, 1),
            source: 'Salary',
          ),
        );
        expect((await forest.load()).primaryGoal!.totalSaved, 0);

        await linkedRepository.addIncome(
          IncomeEntity(
            title: 'Hedef payı',
            amount: 1000,
            date: DateTime(2026, 8, 1),
            source: 'Salary',
            goalId: goalId,
          ),
        );
        expect((await forest.load()).primaryGoal!.totalSaved, 1000);

        await linkedRepository.addExpense(
          ExpenseEntity(
            title: 'Hedef için harcama',
            amount: 250,
            date: DateTime(2026, 8, 1),
            category: 'Other',
            goalId: goalId,
          ),
        );
        expect((await forest.load()).primaryGoal!.totalSaved, 750);
      },
    );
  });
}
