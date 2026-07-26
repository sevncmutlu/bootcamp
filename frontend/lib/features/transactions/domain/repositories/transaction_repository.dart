import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';

abstract class TransactionRepository {
  Future<void> seedCategories();
  Future<List<CategoryEntity>> getCategories();
  Future<void> addExpense(ExpenseEntity expense);
  Future<void> addIncome(IncomeEntity income);
  Future<void> deleteExpense(int id);
  Future<void> deleteIncome(int id);
  Stream<List<ExpenseEntity>> watchExpenses();
  Stream<List<IncomeEntity>> watchIncomes();
}
