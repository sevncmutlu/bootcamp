import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/core/widgets/empty_state.dart';
import 'package:maki_app/features/transactions/presentation/pages/expense_entry_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';

class MockTransactionBloc extends Mock implements TransactionBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockTransactionBloc mockTransactionBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const TransactionState());
    registerFallbackValue(const AuthState());
    registerFallbackValue(LoadCategoriesEvent());
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    when(() => mockTransactionBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockTransactionBloc.close()).thenAnswer((_) async {});
    
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExpenseEntryScreen(),
      ),
    );
  }

  group('ExpenseEntryScreen UI Tests', () {
    testWidgets('renders empty state when there are no transactions', (tester) async {
      when(() => mockTransactionBloc.state).thenReturn(const TransactionState(
        expenses: [],
        incomes: [],
        categories: [],
      ));
      
      final user = const UserEntity(
        userId: '123',
        email: 'test@test.com',
        displayName: 'Test User',
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseEntryScreen), findsOneWidget);
      // Empty state shows when no transactions are present
      expect(find.byType(EmptyState), findsWidgets); 
      
      // Tabs should be present
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byKey(const ValueKey('fab-expense')), findsOneWidget);
    });

    testWidgets('shows Add Expense bottom sheet', (tester) async {
      when(() => mockTransactionBloc.state).thenReturn(TransactionState(
        expenses: [],
        incomes: [],
        categories: [CategoryEntity(id: 1, name: 'Food', colorHex: '#FF0000', iconName: 'food')],
      ));
      
      final user = const UserEntity(
        userId: '123',
        email: 'test@test.com',
        displayName: 'Test User',
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final addButton = find.byKey(const ValueKey('fab-expense'));
      expect(addButton, findsOneWidget);
      
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Check if dialog/bottom sheet opened by looking for a text field
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
