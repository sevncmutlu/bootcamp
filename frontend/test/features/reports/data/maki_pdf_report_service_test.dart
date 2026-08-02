import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/reports/data/maki_pdf_report_service.dart';

void main() {
  late AppDatabase database;
  late MakiPdfReportService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = MakiPdfReportService(database);
  });

  tearDown(() => database.close());

  testWidgets('filters local data and creates a real private PDF', (
    tester,
  ) async {
    await database.insertExpense(
      ExpensesCompanion.insert(
        title: 'Market',
        amount: 350,
        date: DateTime(2026, 8, 1, 12),
        category: 'Alışveriş',
      ),
    );
    await database
        .into(database.incomes)
        .insert(
          IncomesCompanion.insert(
            title: 'Maaş',
            amount: 1000,
            date: DateTime(2026, 8, 1, 9),
            source: 'Maaş',
          ),
        );

    final snapshot = await service.loadSnapshot(
      period: MakiReportPeriod.daily,
      anchor: DateTime(2026, 8, 1),
    );
    final bytes = await service.buildPdf(
      snapshot: snapshot,
      hideAmounts: false,
      includeTransactions: true,
    );

    expect(snapshot.totalExpense, 350);
    expect(snapshot.totalIncome, 1000);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
