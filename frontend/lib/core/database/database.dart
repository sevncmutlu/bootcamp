// ignore_for_file: experimental_member_use

import 'package:drift/drift.dart';
import 'package:maki_app/core/database/connection/connection.dart' as conn;
import 'package:maki_app/core/database/money_minor_converter.dart';

part 'database.g.dart';

const bool _webDemoMode = bool.fromEnvironment('WEB_DEMO_MODE');

@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  IntColumn get amount => integer().map(const MoneyMinorConverter())();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  TextColumn get notes => text().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  TextColumn get sourceRef => text().nullable()();
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
  IntColumn get amount => integer().map(const MoneyMinorConverter())();
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

@DataClassName('SavingsGoal')
class SavingsGoals extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  IntColumn get targetAmount => integer().map(const MoneyMinorConverter())();
  IntColumn get startingAmount => integer()
      .map(const MoneyMinorConverter())
      .withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get iconKey => text().withDefault(const Constant('seedling'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get rewardTargetHighWater => integer()
      .map(const MoneyMinorConverter())
      .withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalContribution')
class GoalContributions extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();
  TextColumn get goalId =>
      text().customConstraint('NOT NULL REFERENCES savings_goals(id)')();
  IntColumn get amount => integer().map(const MoneyMinorConverter())();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get sourceType => text()();
  TextColumn get sourceRef => text().nullable().unique()();
  TextColumn get rewardStatus => text().withDefault(const Constant('none'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyForestActivity')
class DailyForestActivities extends Table {
  TextColumn get id => text().withLength(min: 1, max: 96)();
  DateTimeColumn get day => dateTime()();
  TextColumn get activityType => text()();
  TextColumn get sourceRef => text().nullable()();
  IntColumn get xpAward => integer().withDefault(const Constant(0))();
  IntColumn get seedAward => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ForestXpEntry')
class ForestXpLedger extends Table {
  TextColumn get id => text().withLength(min: 1, max: 96)();
  IntColumn get amount => integer()();
  TextColumn get reason => text()();
  TextColumn get sourceRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ForestWalletEntry')
class ForestWalletLedger extends Table {
  TextColumn get id => text().withLength(min: 1, max: 96)();
  IntColumn get amount => integer()();
  TextColumn get reason => text()();
  TextColumn get sourceRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ForestInventoryItem')
class ForestInventory extends Table {
  TextColumn get itemKey => text().withLength(min: 1, max: 64)();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  BoolColumn get equipped => boolean().withDefault(const Constant(false))();
  TextColumn get selectedPlot => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemKey};
}

@DataClassName('ForestStreakState')
class ForestStreakStates extends Table {
  IntColumn get id => integer()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get bestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastCompletedDay => dateTime().nullable()();
  IntColumn get protectionLeaves => integer().withDefault(const Constant(0))();
  RealColumn get growthHighWater => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MerchantCategoryMapping')
class MerchantCategoryMappings extends Table {
  TextColumn get merchantKey => text().withLength(min: 1, max: 160)();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  DateTimeColumn get confirmedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {merchantKey};
}

@DataClassName('GoalMilestoneAward')
class GoalMilestoneAwards extends Table {
  TextColumn get id => text().withLength(min: 1, max: 96)();
  TextColumn get goalId =>
      text().customConstraint('NOT NULL REFERENCES savings_goals(id)')();
  IntColumn get milestonePercent => integer()();
  IntColumn get targetHighWater => integer().map(const MoneyMinorConverter())();
  TextColumn get status => text().withDefault(const Constant('awarded'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotificationEngagement')
class NotificationEngagements extends Table {
  TextColumn get id => text().withLength(min: 1, max: 96)();
  TextColumn get notificationType => text()();
  TextColumn get arm => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get meaningfulActionAt => dateTime().nullable()();
  DateTimeColumn get rewardSettledAt => dateTime().nullable()();
  RealColumn get rewardValue => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotificationPolicySnapshot')
class NotificationPolicySnapshots extends Table {
  IntColumn get id => integer()();
  TextColumn get stateJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PriceProduct')
class PriceProducts extends Table {
  TextColumn get id => text().withLength(min: 1, max: 96)();
  TextColumn get normalizedName =>
      text().withLength(min: 1, max: 200).unique()();
  TextColumn get displayName => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  IntColumn get baseQuantityMilli =>
      integer().withDefault(const Constant(1000))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PriceObservation')
class PriceObservations extends Table {
  TextColumn get id => text().withLength(min: 1, max: 128)();
  TextColumn get productId =>
      text().customConstraint('NOT NULL REFERENCES price_products(id)')();
  DateTimeColumn get observedAt => dateTime()();
  IntColumn get unitPriceMinor => integer()();
  IntColumn get quantityMilli => integer().withDefault(const Constant(1000))();
  TextColumn get sourceType => text()();
  TextColumn get sourceRef => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(1))();
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OfficialInflationSnapshot')
class OfficialInflationSnapshots extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();
  TextColumn get period => text().withLength(min: 7, max: 10)();
  IntColumn get rateBasisPoints => integer()();
  TextColumn get source => text().withLength(min: 1, max: 32)();
  TextColumn get sourceUrl => text()();
  DateTimeColumn get retrievedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BackupManifest')
class BackupManifests extends Table {
  IntColumn get id => integer()();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get lastExportedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Expenses,
    Categories,
    Incomes,
    UserGamificationStates,
    DailyChallenges,
    NotificationBanditStates,
    SavingsGoals,
    GoalContributions,
    DailyForestActivities,
    ForestXpLedger,
    ForestWalletLedger,
    ForestInventory,
    ForestStreakStates,
    MerchantCategoryMappings,
    GoalMilestoneAwards,
    NotificationEngagements,
    NotificationPolicySnapshots,
    PriceProducts,
    PriceObservations,
    OfficialInflationSnapshots,
    BackupManifests,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect());

  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      if (_webDemoMode) await _seedWebPreviewData();
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
      if (from < 5) {
        await m.addColumn(expenses, expenses.sourceType);
        await m.addColumn(expenses, expenses.sourceRef);
        await m.createTable(savingsGoals);
        await m.createTable(goalContributions);
        await m.createTable(dailyForestActivities);
        await m.createTable(forestXpLedger);
        await m.createTable(forestWalletLedger);
        await m.createTable(forestInventory);
        await m.createTable(forestStreakStates);
        await m.createTable(merchantCategoryMappings);
        await m.createTable(goalMilestoneAwards);
        await m.createTable(notificationEngagements);
        await m.createTable(backupManifests);
      }
      if (from < 6) {
        await _migrateMoneyColumnsToMinorUnits(m);
      }
      if (from < 7) {
        await m.addColumn(
          notificationEngagements,
          notificationEngagements.rewardSettledAt,
        );
        await m.addColumn(
          notificationEngagements,
          notificationEngagements.rewardValue,
        );
        await m.createTable(notificationPolicySnapshots);
      }
      if (from < 8) {
        await m.createTable(priceProducts);
        await m.createTable(priceObservations);
        await m.createTable(officialInflationSnapshots);
      }
    },
  );

  Future<void> _migrateMoneyColumnsToMinorUnits(Migrator migrator) async {
    const columns = <String, List<String>>{
      'expenses': ['amount'],
      'incomes': ['amount'],
      'savings_goals': [
        'target_amount',
        'starting_amount',
        'reward_target_high_water',
      ],
      'goal_contributions': ['amount'],
      'goal_milestone_awards': ['target_high_water'],
    };

    final rowCounts = <String, int>{};
    for (final entry in columns.entries) {
      rowCounts[entry.key] = await _scalarInt(
        'SELECT COUNT(*) AS value FROM ${entry.key}',
      );
      for (final column in entry.value) {
        final invalid = await _scalarInt('''
          SELECT COUNT(*) AS value
          FROM ${entry.key}
          WHERE $column IS NULL
             OR ABS($column) > 92233720368547758.07
             OR ABS(($column * 100.0) - ROUND($column * 100.0)) > 0.000001
        ''');
        if (invalid != 0) {
          throw StateError(
            '${entry.key}.$column alanında kuruşa kayıpsız çevrilemeyen '
            '$invalid kayıt bulundu.',
          );
        }
      }
    }

    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      await transaction(() async {
        const amountToMinor = CustomExpression<int>(
          'CAST(ROUND(amount * 100.0) AS INTEGER)',
        );
        await migrator.alterTable(
          TableMigration(
            expenses,
            columnTransformer: {expenses.amount: amountToMinor},
          ),
        );
        await migrator.alterTable(
          TableMigration(
            incomes,
            columnTransformer: {incomes.amount: amountToMinor},
          ),
        );
        await migrator.alterTable(
          TableMigration(
            goalContributions,
            columnTransformer: {goalContributions.amount: amountToMinor},
          ),
        );
        await migrator.alterTable(
          TableMigration(
            goalMilestoneAwards,
            columnTransformer: {
              goalMilestoneAwards.targetHighWater: const CustomExpression<int>(
                'CAST(ROUND(target_high_water * 100.0) AS INTEGER)',
              ),
            },
          ),
        );
        await migrator.alterTable(
          TableMigration(
            savingsGoals,
            columnTransformer: {
              savingsGoals.targetAmount: const CustomExpression<int>(
                'CAST(ROUND(target_amount * 100.0) AS INTEGER)',
              ),
              savingsGoals.startingAmount: const CustomExpression<int>(
                'CAST(ROUND(starting_amount * 100.0) AS INTEGER)',
              ),
              savingsGoals.rewardTargetHighWater: const CustomExpression<int>(
                'CAST(ROUND(reward_target_high_water * 100.0) AS INTEGER)',
              ),
            },
          ),
        );

        for (final entry in columns.entries) {
          final count = await _scalarInt(
            'SELECT COUNT(*) AS value FROM ${entry.key}',
          );
          if (count != rowCounts[entry.key]) {
            throw StateError(
              '${entry.key} migration satır sayısı doğrulanamadı.',
            );
          }
          for (final column in entry.value) {
            final nonInteger = await _scalarInt('''
              SELECT COUNT(*) AS value
              FROM ${entry.key}
              WHERE TYPEOF($column) <> 'integer'
            ''');
            if (nonInteger != 0) {
              throw StateError(
                '${entry.key}.$column INTEGER olarak saklanamadı.',
              );
            }
          }
        }

        final foreignKeyFailures = await customSelect(
          'PRAGMA foreign_key_check',
        ).get();
        if (foreignKeyFailures.isNotEmpty) {
          throw StateError(
            'Para migration sonrası yabancı anahtar hatası var.',
          );
        }
      });
    } finally {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<int> _scalarInt(String sql) async {
    final row = await customSelect(sql).getSingle();
    return row.read<int>('value');
  }

  Future<void> _seedWebPreviewData() async {
    final today = DateTime.now();
    await batch((batch) {
      for (var day = 0; day < 90; day++) {
        final date = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: day));
        final amount = 45 + ((day * 37) % 260) + (day % 4) * 0.25;
        batch.insert(
          expenses,
          ExpensesCompanion.insert(
            title: day % 3 == 0
                ? 'Demo market alışverişi'
                : 'Demo günlük gider',
            amount: amount,
            date: date,
            category: day % 3 == 0 ? 'Market' : 'Diğer',
            sourceType: const Value('demo'),
          ),
        );
        if (day % 30 == 0) {
          batch.insert(
            incomes,
            IncomesCompanion.insert(
              title: 'Demo aylık gelir',
              amount: 32500,
              date: date,
              source: 'Demo',
            ),
          );
        }
      }
      batch.insert(
        savingsGoals,
        SavingsGoalsCompanion.insert(
          id: 'preview-goal',
          title: 'Demo bisiklet hedefi',
          targetAmount: 24000,
          startingAmount: const Value(6500),
          rewardTargetHighWater: const Value(24000),
          createdAt: today,
        ),
      );
      final baseDate = DateTime(
        today.year,
        today.month,
        1,
      ).subtract(const Duration(days: 60));
      final currentDate = DateTime(today.year, today.month, 1);
      for (final product in const [
        ('preview-milk', 'SÜT 1 L', 'Süt 1 L', 4000, 4400),
        ('preview-bread', 'EKMEK', 'Ekmek', 1500, 1650),
      ]) {
        batch.insert(
          priceProducts,
          PriceProductsCompanion.insert(
            id: product.$1,
            normalizedName: product.$2,
            displayName: product.$3,
            category: 'Market',
            createdAt: baseDate,
          ),
        );
        batch.insert(
          priceObservations,
          PriceObservationsCompanion.insert(
            id: '${product.$1}-base',
            productId: product.$1,
            observedAt: baseDate,
            unitPriceMinor: product.$4,
            sourceType: 'demo',
            confirmed: const Value(true),
            createdAt: baseDate,
          ),
        );
        batch.insert(
          priceObservations,
          PriceObservationsCompanion.insert(
            id: '${product.$1}-current',
            productId: product.$1,
            observedAt: currentDate,
            unitPriceMinor: product.$5,
            sourceType: 'demo',
            confirmed: const Value(true),
            createdAt: currentDate,
          ),
        );
      }
      batch.insert(
        officialInflationSnapshots,
        OfficialInflationSnapshotsCompanion.insert(
          id: 'preview-${today.year}-${today.month}',
          period: '${today.year}-${today.month.toString().padLeft(2, '0')}',
          rateBasisPoints: 352,
          source: 'Demo TÜİK örneği',
          sourceUrl: 'https://data.tuik.gov.tr/',
          retrievedAt: today,
        ),
      );
    });
  }

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

  Stream<List<Income>> watchAllIncomes() {
    return (select(incomes)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<List<Income>> getAllIncomes() {
    return (select(incomes)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<int> insertIncome(IncomesCompanion companion) {
    return into(incomes).insert(companion);
  }

  Future<int> deleteIncome(int id) {
    return (delete(incomes)..where((t) => t.id.equals(id))).go();
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

  Future<String?> getMerchantCategory(String merchantName) async {
    final key = normalizeMerchantKey(merchantName);
    if (key.isEmpty) return null;
    final mapping = await (select(
      merchantCategoryMappings,
    )..where((row) => row.merchantKey.equals(key))).getSingleOrNull();
    return mapping?.category;
  }

  Future<void> confirmMerchantCategory(
    String merchantName,
    String category,
  ) async {
    final key = normalizeMerchantKey(merchantName);
    if (key.isEmpty || category.trim().isEmpty) return;
    await into(merchantCategoryMappings).insertOnConflictUpdate(
      MerchantCategoryMappingsCompanion.insert(
        merchantKey: key,
        category: category,
        confirmedAt: DateTime.now(),
      ),
    );
  }

  static String normalizeMerchantKey(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9ÇĞİÖŞÜ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

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
      await delete(notificationEngagements).go();
      await delete(notificationPolicySnapshots).go();
      await delete(priceObservations).go();
      await delete(priceProducts).go();
      await delete(officialInflationSnapshots).go();
      await delete(goalMilestoneAwards).go();
      await delete(goalContributions).go();
      await delete(savingsGoals).go();
      await delete(dailyForestActivities).go();
      await delete(forestXpLedger).go();
      await delete(forestWalletLedger).go();
      await delete(forestInventory).go();
      await delete(forestStreakStates).go();
      await delete(merchantCategoryMappings).go();
      await delete(backupManifests).go();
    });
  }
}
