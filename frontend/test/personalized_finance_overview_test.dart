import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/theme/app_theme.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/presentation/widgets/personalized_finance_overview.dart';
import 'package:maki_app/l10n/app_localizations.dart';

void main() {
  test('gün özeti yalnız seçilen günün gelir ve giderini hesaplar', () {
    final summary = PersonalizedFinanceOverview.summarizeDay(
      DateTime(2026, 7, 31),
      [
        ExpenseEntity(
          title: 'Market',
          amount: 320,
          date: DateTime(2026, 7, 31, 18),
          category: 'Food',
        ),
        ExpenseEntity(
          title: 'Dün',
          amount: 100,
          date: DateTime(2026, 7, 30),
          category: 'Food',
        ),
      ],
      [
        IncomeEntity(
          title: 'Maaş',
          amount: 2000,
          date: DateTime(2026, 7, 31, 9),
          source: 'Salary',
        ),
      ],
    );

    expect(summary.income, 2000);
    expect(summary.expense, 320);
    expect(summary.net, 1680);
    expect(summary.transactionCount, 2);
  });

  testWidgets('seçilen amaç takvim, görev ve Maki önerisini değiştirir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalizedFinanceOverview(
              primaryGoal: 'save_goal',
              expenses: const [],
              incomes: const [],
              selectedDate: DateTime(2026, 7, 31),
              today: DateTime(2026, 7, 31),
              streakDays: 12,
              onDateSelected: (_) {},
              onOpenCalendar: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('finance-week-calendar')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-streak-badge')), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-dashboard-card')), findsOneWidget);
    expect(find.text('Birikim yapmak'), findsOneWidget);
    expect(find.text('Hedefe katkı ayır'), findsOneWidget);
    expect(find.textContaining('Maki:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('aktif hedef ikinci kart sayfasında kalan yolu gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalizedFinanceOverview(
              primaryGoal: 'save_goal',
              expenses: const [],
              incomes: const [],
              selectedDate: DateTime(2026, 8, 1),
              today: DateTime(2026, 8, 1),
              onDateSelected: (_) {},
              savingsGoal: SavingsGoalView(
                id: 'goal-home',
                title: 'Hayalimdeki ev',
                targetAmount: 100000,
                startingAmount: 10000,
                contributedAmount: 15000,
                isPrimary: true,
                iconKey: 'home',
                targetDate: DateTime(2027, 8, 1),
              ),
              onOpenSavingsGoal: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('finance-overview-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('finance-page-dot-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('savings-goal-page')), findsOneWidget);
    expect(find.text('Hayalimdeki ev'), findsOneWidget);
    expect(find.text('%25'), findsOneWidget);
    expect(find.textContaining('yalnızca kayıt sırasında'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-savings-goal-route')));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
