import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase database;

  TransactionRepositoryImpl(this.database);

  @override
  Future<void> seedCategories() async {
    await database.seedDefaultCategories();
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final categories = await database.getAllCategories();
    return categories.map((c) => CategoryEntity(
      id: c.id,
      name: c.name,
      colorHex: c.colorHex,
      iconName: c.iconName,
    )).toList();
  }

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    final companion = ExpensesCompanion.insert(
      title: expense.title,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      notes: Value(expense.notes),
    );
    await database.insertExpense(companion);
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
    await database.insertIncome(companion);
  }

  @override
  Future<void> deleteExpense(int id) async {
    await database.deleteExpense(id);
  }

  @override
  Future<void> deleteIncome(int id) async {
    await database.deleteIncome(id);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpenses() {
    return database.watchAllExpenses().map((list) {
      return list.map((e) => ExpenseEntity(
        id: e.id,
        title: e.title,
        amount: e.amount,
        date: e.date,
        category: e.category,
        notes: e.notes,
      )).toList();
    });
  }

  @override
  Stream<List<IncomeEntity>> watchIncomes() {
    return database.watchAllIncomes().map((list) {
      return list.map((i) => IncomeEntity(
        id: i.id,
        title: i.title,
        amount: i.amount,
        date: i.date,
        source: i.source,
        notes: i.notes,
      )).toList();
    });
  }
}
