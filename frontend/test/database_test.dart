import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:maki_app/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Initialize database in-memory with the required encryption setup
    db = AppDatabase.forTesting(NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = 'maki_secure_encryption_key_120';");
      },
    ));
  });

  tearDown(() async {
    await db.close();
  });

  test('categories can be seeded and queried', () async {
    await db.seedDefaultCategories();
    
    final categories = await db.getAllCategories();
    expect(categories.length, equals(6));
    expect(categories.any((c) => c.name == 'Market'), isTrue);
  });

  test('expenses can be inserted, queried, and deleted', () async {
    // 1. Insert expense
    final companion = ExpensesCompanion.insert(
      title: 'Coffee',
      amount: 4.50,
      date: DateTime(2026, 7, 15),
      category: 'Restaurant',
      notes: const drift.Value('Morning coffee'),
    );

    final insertedId = await db.insertExpense(companion);
    expect(insertedId, greaterThan(0));

    // 2. Query expense
    final expenses = await db.getAllExpenses();
    expect(expenses.length, equals(1));
    expect(expenses.first.title, equals('Coffee'));
    expect(expenses.first.amount, equals(4.50));

    // 3. Delete expense
    final deletedRows = await db.deleteExpense(insertedId);
    expect(deletedRows, equals(1));

    final expensesAfterDelete = await db.getAllExpenses();
    expect(expensesAfterDelete.isEmpty, isTrue);
  });
}
