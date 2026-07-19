import 'package:drift/drift.dart';
import 'package:maki_app/database/connection/connection.dart' as conn;

part 'database.g.dart';

@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  TextColumn get notes => text().nullable()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  TextColumn get colorHex =>
      text().withLength(min: 7, max: 9)(); // Onaltılık renk: #FFFFFFFF
  TextColumn get iconName => text().withLength(min: 1, max: 50)();
}

@DataClassName('Income')
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text().withLength(min: 1, max: 50)();
  TextColumn get notes => text().nullable()();
}

@DataClassName('UserGamificationState')
class UserGamificationStates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  TextColumn get badges => text().withDefault(const Constant(''))();
}

@DataClassName('DailyChallenge')
class DailyChallenges extends Table {
  TextColumn get id => text().withLength(min: 1, max: 100)();
  TextColumn get titleKey => text().withLength(min: 1, max: 100)();
  TextColumn get descKey => text().withLength(min: 1, max: 200)();
  IntColumn get xpReward => integer().withDefault(const Constant(10))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotificationBanditState')
class NotificationBanditStates extends Table {
  TextColumn get arm =>
      text().withLength(min: 1, max: 50)(); // Sabah, öğle veya akşam kolu.
  TextColumn get precisionMatrixJson => text()(); // 2x2 hassasiyet matrisi.
  TextColumn get projectionVectorJson => text()(); // İki elemanlı vektör.

  @override
  Set<Column> get primaryKey => {arm};
}

@DriftDatabase(
  tables: [
    Expenses,
    Categories,
    Incomes,
    UserGamificationStates,
    DailyChallenges,
    NotificationBanditStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect());

  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(userGamificationStates);
        await m.createTable(dailyChallenges);
      }
      if (from < 3) {
        await m.createTable(notificationBanditStates);
      }
      if (from < 4) {
        await _localizeLegacyCategories();
      }
    },
  );

  Stream<List<Expense>> watchAllExpenses() {
    return (select(expenses)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<List<Expense>> getAllExpenses() {
    return (select(expenses)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .get();
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

  Future<List<Income>> getAllIncomes() {
    return select(incomes).get();
  }

  Future<int> insertIncome(IncomesCompanion companion) {
    return into(incomes).insert(companion);
  }

  Future<UserGamificationState?> getGamificationState() async {
    final list = await select(userGamificationStates).get();
    if (list.isEmpty) {
      final id = await into(userGamificationStates).insert(
        UserGamificationStatesCompanion.insert(
          level: const Value(1),
          xp: const Value(0),
          badges: const Value(''),
        ),
      );
      return UserGamificationState(id: id, level: 1, xp: 0, badges: '');
    }
    return list.first;
  }

  Future<void> updateGamificationState(UserGamificationState state) {
    return update(userGamificationStates).replace(state);
  }

  Future<List<DailyChallenge>> getChallengesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(
      dailyChallenges,
    )..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))).get();
  }

  Future<void> insertChallenge(DailyChallenge challenge) {
    return into(
      dailyChallenges,
    ).insert(challenge, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateChallenge(DailyChallenge challenge) {
    return update(dailyChallenges).replace(challenge);
  }

  Future<List<NotificationBanditState>> getBanditStates() {
    return select(notificationBanditStates).get();
  }

  Future<void> updateBanditState(NotificationBanditState state) {
    return update(notificationBanditStates).replace(state);
  }

  Future<void> insertBanditState(NotificationBanditState state) {
    return into(
      notificationBanditStates,
    ).insert(state, mode: InsertMode.insertOrReplace);
  }

  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  Future<void> seedDefaultCategories() async {
    await _localizeLegacyCategories();
    final defaults = [
      CategoriesCompanion.insert(
        name: 'Market',
        colorHex: '#FFFF9F00',
        iconName: 'shopping_cart',
      ),
      CategoriesCompanion.insert(
        name: 'Restoran',
        colorHex: '#FFFF453A',
        iconName: 'restaurant',
      ),
      CategoriesCompanion.insert(
        name: 'Kira',
        colorHex: '#FF30D158',
        iconName: 'home',
      ),
      CategoriesCompanion.insert(
        name: 'Faturalar',
        colorHex: '#FF5E5CE6',
        iconName: 'receipt',
      ),
      CategoriesCompanion.insert(
        name: 'Ulaşım',
        colorHex: '#FF64D2FF',
        iconName: 'directions_bus',
      ),
      CategoriesCompanion.insert(
        name: 'Eğlence',
        colorHex: '#FFBF5AF2',
        iconName: 'sports_esports',
      ),
    ];

    for (final companion in defaults) {
      await into(categories).insert(companion, mode: InsertMode.insertOrIgnore);
    }
  }

  Future<void> _localizeLegacyCategories() async {
    const translations = <String, String>{
      'Restaurant': 'Restoran',
      'Dining': 'Restoran',
      'Rent': 'Kira',
      'Bills': 'Faturalar',
      'Transport': 'Ulaşım',
      'Fun': 'Eğlence',
      'Shopping': 'Alışveriş',
    };

    await transaction(() async {
      for (final entry in translations.entries) {
        await (update(expenses)..where((row) => row.category.equals(entry.key)))
            .write(ExpensesCompanion(category: Value(entry.value)));

        final oldCategory = await (select(
          categories,
        )..where((row) => row.name.equals(entry.key))).getSingleOrNull();
        if (oldCategory == null) continue;

        final localizedCategory = await (select(
          categories,
        )..where((row) => row.name.equals(entry.value))).getSingleOrNull();
        if (localizedCategory == null) {
          await (update(categories)
                ..where((row) => row.id.equals(oldCategory.id)))
              .write(CategoriesCompanion(name: Value(entry.value)));
        } else {
          await (delete(
            categories,
          )..where((row) => row.id.equals(oldCategory.id))).go();
        }
      }
    });
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(expenses).go();
      await delete(incomes).go();
      await delete(userGamificationStates).go();
      await delete(dailyChallenges).go();
      await delete(notificationBanditStates).go();
    });
  }
}
