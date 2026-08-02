import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:maki_app/features/gamification/data/services/daily_activity_engine.dart';
import 'package:maki_app/features/gamification/data/services/living_forest_service.dart';
import 'package:maki_app/features/profile/data/services/smart_notification_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase database;
  final DailyActivityEngine activityEngine;
  final LivingForestService? livingForestService;
  final SmartNotificationService? smartNotificationService;

  TransactionRepositoryImpl(
    this.database, {
    DailyActivityEngine? activityEngine,
    this.livingForestService,
    this.smartNotificationService,
  }) : activityEngine = activityEngine ?? DailyActivityEngine(database);

  @override
  Future<void> seedCategories() async {
    await database.seedDefaultCategories();
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final categories = await database.getAllCategories();
    return categories
        .map(
          (c) => CategoryEntity(
            id: c.id,
            name: c.name,
            colorHex: c.colorHex,
            iconName: c.iconName,
          ),
        )
        .toList();
  }

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    final companion = ExpensesCompanion.insert(
      title: expense.title,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      notes: Value(expense.notes),
      sourceType: Value(expense.sourceType),
      sourceRef: Value(expense.sourceRef),
    );
    final id = await activityEngine.addExpense(companion);
    final goalId = expense.goalId;
    if (goalId != null && livingForestService != null) {
      await livingForestService!.applyTransactionImpact(
        goalId: goalId,
        sourceRef: 'expense:$id',
        amount: expense.amount,
        isExpense: true,
        occurredAt: expense.date,
      );
    }
    await smartNotificationService?.recordMeaningfulAction();
  }

  @override
  Future<void> addIncome(IncomeEntity income) async {
    final companion = IncomesCompanion.insert(
      title: income.title,
      amount: income.amount,
      date: income.date,
      source: income.source,
      notes: Value(income.notes),
    );
    final id = await activityEngine.addIncome(companion);
    final goalId = income.goalId;
    if (goalId != null && livingForestService != null) {
      await livingForestService!.applyTransactionImpact(
        goalId: goalId,
        sourceRef: 'income:$id',
        amount: income.amount,
        isExpense: false,
        occurredAt: income.date,
      );
    }
    await smartNotificationService?.recordMeaningfulAction();
  }

  @override
  Future<void> deleteExpense(int id) async {
    await livingForestService?.removeTransactionImpact('expense:$id');
    await database.deleteExpense(id);
  }

  @override
  Future<void> deleteIncome(int id) async {
    await livingForestService?.removeTransactionImpact('income:$id');
    await database.deleteIncome(id);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpenses() {
    return database.watchAllExpenses().map((list) {
      return list
          .map(
            (e) => ExpenseEntity(
              id: e.id,
              title: e.title,
              amount: e.amount,
              date: e.date,
              category: e.category,
              notes: e.notes,
              sourceType: e.sourceType,
              sourceRef: e.sourceRef,
              goalId: null,
            ),
          )
          .toList();
    });
  }

  @override
  Stream<List<IncomeEntity>> watchIncomes() {
    return database.watchAllIncomes().map((list) {
      return list
          .map(
            (i) => IncomeEntity(
              id: i.id,
              title: i.title,
              amount: i.amount,
              date: i.date,
              source: i.source,
              notes: i.notes,
              goalId: null,
            ),
          )
          .toList();
    });
  }
}
