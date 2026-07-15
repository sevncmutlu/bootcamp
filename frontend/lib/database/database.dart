import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// =============================================================================
// Database Tables Definitions
// =============================================================================

/// Table representing local user expenses.
@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  TextColumn get notes => text().nullable()();
}

/// Table representing expense categories.
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  TextColumn get colorHex => text().withLength(min: 7, max: 9)(); // Hex format e.g., #FFFFFFFF
  TextColumn get iconName => text().withLength(min: 1, max: 50)();
}

/// Table representing local user incomes.
@DataClassName('Income')
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text().withLength(min: 1, max: 50)();
  TextColumn get notes => text().nullable()();
}

// =============================================================================
// Drift Database Orchestration
// =============================================================================

@DriftDatabase(tables: [Expenses, Categories, Incomes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Testing constructor to run in-memory executions
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  /// Thread-safe singleton instance
  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 1;

  // ===========================================================================
  // Expense Management Queries
  // ===========================================================================

  Stream<List<Expense>> watchAllExpenses() {
    return (select(expenses)..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])).watch();
  }

  Future<List<Expense>> getAllExpenses() {
    return (select(expenses)..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])).get();
  }

  Future<int> insertExpense(ExpensesCompanion companion) {
    return into(expenses).insert(companion);
  }

  Future<bool> updateExpense(Expense entity) {
    return update(expenses).replace(entity);
  }

  Future<int> deleteExpense(int id) {
    return (delete(expenses)..where((t) => t.id.equals(id))).go();
  }

  // ===========================================================================
  // Category Management & Seeding
  // ===========================================================================

  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  Future<void> seedDefaultCategories() async {
    final existing = await select(categories).get();
    if (existing.isEmpty) {
      final defaults = [
        CategoriesCompanion.insert(name: 'Market', colorHex: '#FFFF9F00', iconName: 'shopping_cart'),
        CategoriesCompanion.insert(name: 'Restaurant', colorHex: '#FFFF453A', iconName: 'restaurant'),
        CategoriesCompanion.insert(name: 'Rent', colorHex: '#FF30D158', iconName: 'home'),
        CategoriesCompanion.insert(name: 'Bills', colorHex: '#FF5E5CE6', iconName: 'receipt'),
        CategoriesCompanion.insert(name: 'Transport', colorHex: '#FF64D2FF', iconName: 'directions_bus'),
        CategoriesCompanion.insert(name: 'Fun', colorHex: '#FFBF5AF2', iconName: 'sports_esports'),
      ];
      
      for (final companion in defaults) {
        await into(categories).insert(companion);
      }
    }
  }
}

// =============================================================================
// Encrypted SQLite connection via SQLite3MC (SQLite3 Multiple Ciphers)
// =============================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'maki_finance.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // Define and execute PRAGMA key for transparent encryption.
        // TODO: In production, retrieve the encryption key securely from 
        // the device's secure hardware store (e.g. Keychain/Keystore).
        const encryptionKey = 'maki_secure_encryption_key_120';
        rawDb.execute("PRAGMA key = '$encryptionKey';");
      },
    );
  });
}
