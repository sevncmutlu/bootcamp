import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/gamification/data/datasources/gamification_local_data_source.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_catalog.dart';

void main() {
  late AppDatabase database;
  late GamificationLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = GamificationLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('katalog tam 325 benzersiz gorev icerir', () {
    expect(DailyChallengeCatalog.templates, hasLength(325));
    expect(
      DailyChallengeCatalog.templates.map((item) => item.id).toSet(),
      hasLength(325),
    );
  });

  test('her gun dort farkli rotadan deterministik gorev secer', () async {
    final firstDay = DateTime(2026, 8, 1, 9);
    final first = await dataSource.getOrSeedDailyChallenges(firstDay);
    final repeated = await dataSource.getOrSeedDailyChallenges(firstDay);
    final nextDay = await dataSource.getOrSeedDailyChallenges(
      firstDay.add(const Duration(days: 1)),
    );

    expect(first, hasLength(4));
    expect(first.map((item) => item.id), repeated.map((item) => item.id));
    expect(
      first.every((item) => item.id.startsWith('v4_track_spending_')),
      isTrue,
    );
    expect(nextDay, hasLength(4));
    expect(
      nextDay.map((item) => item.titleKey).toSet(),
      isNot(equals(first.map((item) => item.titleKey).toSet())),
    );
  });

  test('ana hedef degisince ayni gunun gorev rotasi da degisir', () async {
    var route = 'pay_debt';
    dataSource = GamificationLocalDataSourceImpl(
      database,
      primaryGoalProvider: () async => route,
    );
    final day = DateTime(2026, 8, 1);

    final debtTasks = await dataSource.getOrSeedDailyChallenges(day);
    route = 'learn_invest';
    final learningTasks = await dataSource.getOrSeedDailyChallenges(day);

    expect(
      debtTasks.every((item) => item.id.startsWith('v4_pay_debt_')),
      isTrue,
    );
    expect(
      learningTasks.every((item) => item.id.startsWith('v4_learn_invest_')),
      isTrue,
    );
    expect(
      debtTasks.map((item) => item.titleKey).toSet(),
      isNot(equals(learningTasks.map((item) => item.titleKey).toSet())),
    );
  });

  test('gunluk setin ucu secilen rotanin ailelerinden gelir', () {
    final tasks = DailyChallengeCatalog.selectionForDay(
      DateTime(2026, 8, 1),
      routeKey: 'save_goal',
    );
    final routeFamilies = DailyChallengeCatalog.routeFamilies['save_goal']!;

    expect(
      tasks.where((item) => routeFamilies.contains(item.family)).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('eski yedi gorev yerine yeni rotasyon dondurur', () async {
    final day = DateTime(2026, 8, 1);
    await database.insertChallenge(
      DailyChallenge(
        id: 'legacy_task_2026-08-01',
        titleKey: 'legacy',
        descKey: 'legacyDesc',
        xpReward: 10,
        isCompleted: false,
        date: day,
      ),
    );

    final result = await dataSource.getOrSeedDailyChallenges(day);

    expect(result, hasLength(4));
    expect(result.any((item) => item.titleKey == 'legacy'), isFalse);
  });
}
