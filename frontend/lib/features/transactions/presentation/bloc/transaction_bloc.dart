import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;
  StreamSubscription<List<ExpenseEntity>>? _expensesSubscription;
  StreamSubscription<List<IncomeEntity>>? _incomesSubscription;

  TransactionBloc({required this.repository})
    : super(const TransactionState()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<AddExpenseEvent>(_onAddExpense);
    on<AddIncomeEvent>(_onAddIncome);
    on<ExpensesUpdatedEvent>(_onExpensesUpdated);
    on<IncomesUpdatedEvent>(_onIncomesUpdated);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<DeleteIncomeEvent>(_onDeleteIncome);

    _expensesSubscription = repository.watchExpenses().listen(
      (expenses) => add(ExpensesUpdatedEvent(expenses)),
    );
    _incomesSubscription = repository.watchIncomes().listen(
      (incomes) => add(IncomesUpdatedEvent(incomes)),
    );
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    _incomesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await repository.seedCategories();
      final categories = await repository.getCategories();
      emit(state.copyWith(categories: categories, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      await repository.addExpense(event.expense);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddIncome(
    AddIncomeEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      await repository.addIncome(event.income);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.deleteExpense(event.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteIncome(
    DeleteIncomeEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.deleteIncome(event.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onExpensesUpdated(
    ExpensesUpdatedEvent event,
    Emitter<TransactionState> emit,
  ) {
    emit(state.copyWith(expenses: event.expenses));
  }

  void _onIncomesUpdated(
    IncomesUpdatedEvent event,
    Emitter<TransactionState> emit,
  ) {
    emit(state.copyWith(incomes: event.incomes));
  }
}
