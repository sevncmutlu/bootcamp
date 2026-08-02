import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';

NativeDatabase _legacyV5Database({bool invalidPrecision = false}) {
  return NativeDatabase.memory(
    setup: (raw) {
      raw.execute('''
        CREATE TABLE expenses (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          date INTEGER NOT NULL,
          category TEXT NOT NULL,
          notes TEXT,
          source_type TEXT NOT NULL DEFAULT 'manual',
          source_ref TEXT
        )
      ''');
      raw.execute('''
        CREATE TABLE incomes (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          date INTEGER NOT NULL,
          source TEXT NOT NULL,
          notes TEXT
        )
      ''');
      raw.execute('''
        CREATE TABLE savings_goals (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          target_amount REAL NOT NULL,
          starting_amount REAL NOT NULL DEFAULT 0,
          target_date INTEGER,
          icon_key TEXT NOT NULL DEFAULT 'seedling',
          priority INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'active',
          reward_target_high_water REAL NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      raw.execute('''
        CREATE TABLE goal_contributions (
          id TEXT NOT NULL PRIMARY KEY,
          goal_id TEXT NOT NULL REFERENCES savings_goals(id),
          amount REAL NOT NULL,
          date INTEGER NOT NULL,
          note TEXT,
          source_type TEXT NOT NULL,
          source_ref TEXT UNIQUE,
          reward_status TEXT NOT NULL DEFAULT 'none',
          created_at INTEGER NOT NULL
        )
      ''');
      raw.execute('''
        CREATE TABLE goal_milestone_awards (
          id TEXT NOT NULL PRIMARY KEY,
          goal_id TEXT NOT NULL REFERENCES savings_goals(id),
          milestone_percent INTEGER NOT NULL,
          target_high_water REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'awarded',
          created_at INTEGER NOT NULL
        )
      ''');
      raw.execute('''
        CREATE TABLE notification_engagements (
          id TEXT NOT NULL PRIMARY KEY,
          notification_type TEXT NOT NULL,
          arm TEXT NOT NULL,
          scheduled_at INTEGER NOT NULL,
          opened_at INTEGER,
          meaningful_action_at INTEGER
        )
      ''');

      final expense = invalidPrecision ? 12.345 : 12.34;
      raw.execute(
        "INSERT INTO expenses "
        "(title, amount, date, category, source_type) "
        "VALUES ('Market', $expense, 1785542400, 'Market', 'manual')",
      );
      raw.execute(
        "INSERT INTO incomes (title, amount, date, source) "
        "VALUES ('Maaş', 1234.56, 1785542400, 'Maaş')",
      );
      raw.execute(
        "INSERT INTO savings_goals "
        "(id, title, target_amount, starting_amount, "
        " reward_target_high_water, created_at) "
        "VALUES ('goal-1', 'Bisiklet', 10000.00, 250.25, 10000.00, "
        "1785542400)",
      );
      raw.execute(
        "INSERT INTO goal_contributions "
        "(id, goal_id, amount, date, source_type, created_at) "
        "VALUES ('contribution-1', 'goal-1', 50.50, 1785542400, "
        "'manual', 1785542400)",
      );
      raw.execute(
        "INSERT INTO goal_milestone_awards "
        "(id, goal_id, milestone_percent, target_high_water, created_at) "
        "VALUES ('award-1', 'goal-1', 25, 10000.00, 1785542400)",
      );
      raw.execute('PRAGMA user_version = 5');
    },
  );
}

void main() {
  test('V5 para alanlarını kayıpsız biçimde INTEGER kuruşa taşır', () async {
    final db = AppDatabase.forTesting(_legacyV5Database());
    addTearDown(db.close);

    final expenses = await db.getAllExpenses();
    final incomes = await db.getAllIncomes();
    expect(expenses.single.amount, 12.34);
    expect(incomes.single.amount, 1234.56);

    final stored = await db.customSelect('''
      SELECT amount, TYPEOF(amount) AS storage_type FROM expenses
    ''').getSingle();
    expect(stored.read<int>('amount'), 1234);
    expect(stored.read<String>('storage_type'), 'integer');

    final goalStored = await db.customSelect('''
      SELECT target_amount, starting_amount FROM savings_goals
    ''').getSingle();
    expect(goalStored.read<int>('target_amount'), 1000000);
    expect(goalStored.read<int>('starting_amount'), 25025);
  });

  test('V5 migration iki ondalıktan hassas veriyi yuvarlamaz', () async {
    final db = AppDatabase.forTesting(
      _legacyV5Database(invalidPrecision: true),
    );
    addTearDown(db.close);

    await expectLater(db.getAllExpenses(), throwsA(isA<StateError>()));
  });
}
