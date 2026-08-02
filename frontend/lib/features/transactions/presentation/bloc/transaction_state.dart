import 'package:equatable/equatable.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';

class TransactionState extends Equatable {
  final List<CategoryEntity> categories;
  final List<ExpenseEntity> expenses;
  final List<IncomeEntity> incomes;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const TransactionState({
    this.categories = const [],
    this.expenses = const [],
    this.incomes = const [],
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  TransactionState copyWith({
    List<CategoryEntity>? categories,
    List<ExpenseEntity>? expenses,
    List<IncomeEntity>? incomes,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return TransactionState(
      categories: categories ?? this.categories,
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    expenses,
    incomes,
    isLoading,
    error,
    isSuccess,
  ];
}
