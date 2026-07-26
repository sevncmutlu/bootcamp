import 'package:equatable/equatable.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object> get props => [];
}

class LoadCategoriesEvent extends TransactionEvent {}

class AddExpenseEvent extends TransactionEvent {
  final ExpenseEntity expense;

  const AddExpenseEvent(this.expense);

  @override
  List<Object> get props => [expense];
}

class AddIncomeEvent extends TransactionEvent {
  final IncomeEntity income;

  const AddIncomeEvent(this.income);

  @override
  List<Object> get props => [income];
}

class ExpensesUpdatedEvent extends TransactionEvent {
  final List<ExpenseEntity> expenses;
  const ExpensesUpdatedEvent(this.expenses);
  @override
  List<Object> get props => [expenses];
}

class IncomesUpdatedEvent extends TransactionEvent {
  final List<IncomeEntity> incomes;
  const IncomesUpdatedEvent(this.incomes);
  @override
  List<Object> get props => [incomes];
}

class DeleteExpenseEvent extends TransactionEvent {
  final int id;
  const DeleteExpenseEvent(this.id);
  @override
  List<Object> get props => [id];
}

class DeleteIncomeEvent extends TransactionEvent {
  final int id;
  const DeleteIncomeEvent(this.id);
  @override
  List<Object> get props => [id];
}
