import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/insights/data/services/personal_finance_insight_service.dart';

void main() {
  late AppDatabase database;
  late PersonalFinanceInsightService service;
  final now = DateTime(2026, 8, 2, 12);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = PersonalFinanceInsightService(database, clock: () => now);
  });

  tearDown(() async => database.close());

  Future<void> addExpense({
    required String title,
    required double amount,
    required DateTime date,
    String category = 'Market',
  }) => database.insertExpense(
    ExpensesCompanion.insert(
      title: title,
      amount: amount,
      date: date,
      category: category,
    ),
  );

  test(
    'compares two periods and keeps debt outside consumption change',
    () async {
      await database.insertIncome(
        IncomesCompanion.insert(
          title: 'Maaş',
          amount: 10000,
          date: DateTime(2026, 8, 1),
          source: 'Maaş',
        ),
      );
      await addExpense(
        title: 'Market 1',
        amount: 1000,
        date: DateTime(2026, 7, 10),
      );
      await addExpense(
        title: 'Market 2',
        amount: 1000,
        date: DateTime(2026, 7, 20),
      );
      await addExpense(
        title: 'Market 3',
        amount: 1000,
        date: DateTime(2026, 8, 1),
      );
      await addExpense(
        title: 'Kredi kartı borcu',
        amount: 1000,
        date: DateTime(2026, 8, 2),
        category: 'Borç',
      );
      await addExpense(
        title: 'Önceki 1',
        amount: 1000,
        date: DateTime(2026, 6, 10),
      );
      await addExpense(
        title: 'Önceki 2',
        amount: 1000,
        date: DateTime(2026, 6, 20),
      );
      await addExpense(
        title: 'Önceki 3',
        amount: 500,
        date: DateTime(2026, 7, 1),
      );
      await database
          .into(database.officialInflationSnapshots)
          .insert(
            OfficialInflationSnapshotsCompanion.insert(
              id: '2026-07',
              period: '2026-07',
              rateBasisPoints: 352,
              source: 'TÜİK',
              sourceUrl: 'https://data.tuik.gov.tr/',
              retrievedAt: now,
            ),
          );

      final result = await service.calculate();

      expect(result.hasComparisonData, isTrue);
      expect(result.personalInflation, closeTo(20, 0.001));
      expect(result.officialInflation, 3.52);
      expect(result.currentIncome, 10000);
      expect(result.currentExpenses, 4000);
      expect(result.debtPayments, 1000);
      expect(result.netCashFlow, 6000);
      expect(result.financialPressure, closeTo(38.25, 0.001));
      expect(result.currentTransactionCount, 3);
      expect(result.previousTransactionCount, 3);
      expect(result.status, 'ready');
    },
  );

  test(
    'shows finance pressure without inventing a personal comparison',
    () async {
      await database.insertIncome(
        IncomesCompanion.insert(
          title: 'Gelir',
          amount: 5000,
          date: DateTime(2026, 8, 1),
          source: 'Diğer',
        ),
      );
      await addExpense(
        title: 'Tek gider',
        amount: 1000,
        date: DateTime(2026, 8, 1),
      );

      final result = await service.calculate();

      expect(result.personalInflation, isNull);
      expect(result.financialPressure, isNotNull);
      expect(result.status, 'insufficient_history');
    },
  );

  test('does not publish a pressure score without income', () async {
    for (var index = 0; index < 3; index++) {
      await addExpense(
        title: 'Güncel $index',
        amount: 100,
        date: DateTime(2026, 7, 10 + index),
      );
      await addExpense(
        title: 'Önceki $index',
        amount: 100,
        date: DateTime(2026, 6, 10 + index),
      );
    }

    final result = await service.calculate();

    expect(result.personalInflation, 0);
    expect(result.financialPressure, isNull);
    expect(result.status, 'missing_income');
  });
}
