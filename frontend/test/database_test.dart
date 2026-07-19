import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:maki_app/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = 'maki_secure_encryption_key_120';");
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('kategoriler oluşturulup sorgulanabilir', () async {
    await db.seedDefaultCategories();

    final categories = await db.getAllCategories();
    expect(categories.length, equals(6));
    expect(categories.any((c) => c.name == 'Market'), isTrue);
    expect(categories.any((c) => c.name == 'Kira'), isTrue);
    expect(categories.any((c) => c.name == 'Faturalar'), isTrue);
    expect(categories.any((c) => c.name == 'Ulaşım'), isTrue);
    expect(categories.any((c) => c.name == 'Eğlence'), isTrue);
    expect(categories.any((c) => c.name == 'Rent'), isFalse);
  });

  test(
    'eski İngilizce kategoriler veri kaybetmeden Türkçeleştirilir',
    () async {
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Transport',
              colorHex: '#FF64D2FF',
              iconName: 'directions_bus',
            ),
          );
      await db.insertExpense(
        ExpensesCompanion.insert(
          title: 'Otobüs',
          amount: 25,
          date: DateTime(2026, 7, 15),
          category: 'Transport',
        ),
      );

      await db.seedDefaultCategories();

      final categories = await db.getAllCategories();
      final expenses = await db.getAllExpenses();
      expect(categories.any((c) => c.name == 'Transport'), isFalse);
      expect(categories.any((c) => c.name == 'Ulaşım'), isTrue);
      expect(expenses.single.category, equals('Ulaşım'));
    },
  );

  test('harcamalar eklenip sorgulanabilir ve silinebilir', () async {
    final companion = ExpensesCompanion.insert(
      title: 'Kahve',
      amount: 4.50,
      date: DateTime(2026, 7, 15),
      category: 'Restoran',
      notes: const drift.Value('Sabah kahvesi'),
    );

    final insertedId = await db.insertExpense(companion);
    expect(insertedId, greaterThan(0));

    final expenses = await db.getAllExpenses();
    expect(expenses.length, equals(1));
    expect(expenses.first.title, equals('Kahve'));
    expect(expenses.first.amount, equals(4.50));

    final deletedRows = await db.deleteExpense(insertedId);
    expect(deletedRows, equals(1));

    final expensesAfterDelete = await db.getAllExpenses();
    expect(expensesAfterDelete.isEmpty, isTrue);
  });
}
