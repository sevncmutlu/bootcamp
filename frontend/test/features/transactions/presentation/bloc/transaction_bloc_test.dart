import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepository;
  late TransactionBloc bloc;

  setUp(() {
    mockRepository = MockTransactionRepository();
    // Default mock behavior for streams
    when(() => mockRepository.watchExpenses()).thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.watchIncomes()).thenAnswer((_) => const Stream.empty());
  });

  group('TransactionBloc', () {
    final tExpense = ExpenseEntity(
      id: 1,
      title: 'Coffee',
      amount: 4.5,
      date: DateTime(2023, 1, 1),
      category: 'Food',
    );

    final tIncome = IncomeEntity(
      id: 1,
      title: 'Salary',
      amount: 5000,
      date: DateTime(2023, 1, 1),
      source: 'Work',
    );

    final tCategory = CategoryEntity(
      id: 1,
      name: 'Food',
      colorHex: '#FF0000',
      iconName: 'fastfood',
    );

    test('emits [isLoading, loaded categories] when LoadCategoriesEvent is added successfully', () async {
      when(() => mockRepository.seedCategories()).thenAnswer((_) async {});
      when(() => mockRepository.getCategories()).thenAnswer((_) async => [tCategory]);
      
      bloc = TransactionBloc(repository: mockRepository);
      
      final expectedStates = [
        const TransactionState(isLoading: true),
        TransactionState(isLoading: false, categories: [tCategory]),
      ];
      
      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(LoadCategoriesEvent());
    });

    test('emits [isLoading, error] when LoadCategoriesEvent fails', () async {
      when(() => mockRepository.seedCategories()).thenThrow(Exception('Failed'));
      
      bloc = TransactionBloc(repository: mockRepository);
      
      final expectedStates = [
        const TransactionState(isLoading: true),
        const TransactionState(isLoading: false, error: 'Exception: Failed'),
      ];
      
      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(LoadCategoriesEvent());
    });

    test('emits [isLoading, isSuccess] when AddExpenseEvent is successful', () async {
      when(() => mockRepository.addExpense(tExpense)).thenAnswer((_) async {});
      
      bloc = TransactionBloc(repository: mockRepository);
      
      final expectedStates = [
        const TransactionState(isLoading: true, isSuccess: false),
        const TransactionState(isLoading: false, isSuccess: true),
      ];
      
      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(AddExpenseEvent(tExpense));
    });

    test('emits [isLoading, isSuccess] when AddIncomeEvent is successful', () async {
      when(() => mockRepository.addIncome(tIncome)).thenAnswer((_) async {});
      
      bloc = TransactionBloc(repository: mockRepository);
      
      final expectedStates = [
        const TransactionState(isLoading: true, isSuccess: false),
        const TransactionState(isLoading: false, isSuccess: true),
      ];
      
      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(AddIncomeEvent(tIncome));
    });

    test('calls deleteExpense when DeleteExpenseEvent is added', () async {
      when(() => mockRepository.deleteExpense(1)).thenAnswer((_) async {});
      
      bloc = TransactionBloc(repository: mockRepository);
      bloc.add(const DeleteExpenseEvent(1));
      
      // small delay to let bloc process
      await Future.delayed(const Duration(milliseconds: 50));
      
      verify(() => mockRepository.deleteExpense(1)).called(1);
    });

    test('calls deleteIncome when DeleteIncomeEvent is added', () async {
      when(() => mockRepository.deleteIncome(1)).thenAnswer((_) async {});
      
      bloc = TransactionBloc(repository: mockRepository);
      bloc.add(const DeleteIncomeEvent(1));
      
      // small delay to let bloc process
      await Future.delayed(const Duration(milliseconds: 50));
      
      verify(() => mockRepository.deleteIncome(1)).called(1);
    });

    test('streams update state correctly on init', () async {
      when(() => mockRepository.watchExpenses())
          .thenAnswer((_) => Stream.value([tExpense]));
      when(() => mockRepository.watchIncomes())
          .thenAnswer((_) => Stream.value([tIncome]));
          
      bloc = TransactionBloc(repository: mockRepository);
      
      // Wait for stream subscription to emit and bloc to process
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(bloc.state.expenses, equals([tExpense]));
      expect(bloc.state.incomes, equals([tIncome]));
      
      await bloc.close();
    });
  });
}
