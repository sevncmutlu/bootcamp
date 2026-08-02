import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/theme/app_theme.dart';
import 'package:maki_app/core/widgets/maki_navigation_dock.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/features/transactions/presentation/pages/expense_entry_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionBloc extends Mock implements TransactionBloc {}

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  setUpAll(() async {
    final sans = FontLoader('MakiSans')
      ..addFont(rootBundle.load('assets/fonts/MakiSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/MakiSans-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/MakiSans-Bold.ttf'));
    final display = FontLoader('MakiDisplay')
      ..addFont(rootBundle.load('assets/fonts/MakiDisplay-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/MakiDisplay-Bold.ttf'));
    final iconBytes = File(
      'test/fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.view(
            iconBytes.buffer,
            iconBytes.offsetInBytes,
            iconBytes.lengthInBytes,
          ),
        ),
      );
    await Future.wait([sans.load(), display.load(), icons.load()]);
  });

  testWidgets('Maki 2026 ana ekran görsel sözleşmesi', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transactionBloc = _MockTransactionBloc();
    final authBloc = _MockAuthBloc();
    final state = TransactionState(
      categories: const [
        CategoryEntity(
          id: 1,
          name: 'Market',
          colorHex: '#3E9B62',
          iconName: 'shopping_cart',
        ),
        CategoryEntity(
          id: 2,
          name: 'Ulaşım',
          colorHex: '#D7A84A',
          iconName: 'directions_car',
        ),
      ],
      incomes: [
        IncomeEntity(
          id: 1,
          title: 'Aylık gelir',
          amount: 48500,
          date: DateTime(2026, 7, 28),
          source: 'salary',
        ),
      ],
      expenses: [
        ExpenseEntity(
          id: 1,
          title: 'Haftalık market',
          amount: 1840,
          date: DateTime(2026, 7, 29),
          category: 'Market',
        ),
        ExpenseEntity(
          id: 2,
          title: 'Ulaşım kartı',
          amount: 620,
          date: DateTime(2026, 7, 27),
          category: 'Ulaşım',
        ),
      ],
    );

    when(() => transactionBloc.state).thenReturn(state);
    when(
      () => transactionBloc.stream,
    ).thenAnswer((_) => const Stream<TransactionState>.empty());
    when(() => transactionBloc.close()).thenAnswer((_) async {});
    when(() => authBloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.authenticated,
        user: UserEntity(
          userId: 'visual-contract',
          email: 'maki@example.test',
          displayName: 'Maki',
        ),
      ),
    );
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authBloc.close()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionBloc>.value(value: transactionBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ExpenseEntryScreen(today: DateTime(2026, 7, 31)),
            bottomNavigationBar: MakiNavigationDock(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.wallet_outlined),
                  selectedIcon: Icon(Icons.wallet_rounded),
                  label: 'Gelir/Gider',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Borç',
                ),
                NavigationDestination(
                  icon: Icon(Icons.compare_arrows_rounded),
                  label: 'Karşılaştır',
                ),
                NavigationDestination(
                  icon: Icon(Icons.donut_large_outlined),
                  label: 'Analiz',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  label: 'Lider',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ExpenseEntryScreen),
      matchesGoldenFile('goldens/maki_2026_home.png'),
    );
  });
}
