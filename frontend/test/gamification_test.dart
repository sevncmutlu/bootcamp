import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/services/gamification_service.dart';

void main() {
  late AppDatabase db;
  late GamificationService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = GamificationService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('günlük görev oluşturma bir tarih için tam üç görev üretir', () async {
    final now = DateTime(2026, 7, 15);
    final challenges = await service.getOrSeedDailyChallenges(now);

    expect(challenges.length, equals(3));
    expect(challenges.any((c) => c.titleKey == 'challengeCookHome'), isTrue);
    expect(challenges.any((c) => c.titleKey == 'challengeLogThree'), isTrue);
    expect(challenges.any((c) => c.titleKey == 'challengeNoShopping'), isTrue);
  });

  test('otomatik değerlendirme günlük koşulları doğru denetler', () async {
    final now = DateTime(2026, 7, 15);

    await service.getOrSeedDailyChallenges(now);

    await db.insertExpense(
      ExpensesCompanion.insert(
        title: 'Öğle yemeği',
        amount: 45.0,
        date: now,
        category: 'Restaurant',
      ),
    );
    await db.insertExpense(
      ExpensesCompanion.insert(
        title: 'Market alışverişi',
        amount: 120.0,
        date: now,
        category: 'Market',
      ),
    );
    await db.insertExpense(
      ExpensesCompanion.insert(
        title: 'Kitap',
        amount: 90.0,
        date: now,
        category: 'Shopping',
      ),
    );

    await service.evaluateDailyChallenges(now);

    final updated = await db.getChallengesForDate(now);

    final cookHome = updated.firstWhere(
      (c) => c.titleKey == 'challengeCookHome',
    );
    expect(cookHome.isCompleted, isFalse);

    final logThree = updated.firstWhere(
      (c) => c.titleKey == 'challengeLogThree',
    );
    expect(logThree.isCompleted, isTrue);

    final noShopping = updated.firstWhere(
      (c) => c.titleKey == 'challengeNoShopping',
    );
    expect(noShopping.isCompleted, isFalse);
  });

  test('tamamlanan görev deneyim kazandırır ve seviye atlatır', () async {
    final now = DateTime(2026, 7, 15);
    await service.getOrSeedDailyChallenges(now);

    final list = await db.getChallengesForDate(now);
    final logThree = list.firstWhere((c) => c.titleKey == 'challengeLogThree');

    final completed = logThree.copyWith(isCompleted: true);
    await db.updateChallenge(completed);

    final state = await service.claimXP(completed);

    expect(state.level, equals(1));
    expect(state.xp, equals(20)); // 20 deneyim puanı kazandırır.
    expect(state.badges.contains('badgeSavingsSeed'), isTrue);

    final massiveChallenge = completed.copyWith(xpReward: 90, id: 'massive');
    final levelUpState = await service.claimXP(massiveChallenge);

    expect(levelUpState.level, equals(2));
    expect(levelUpState.xp, equals(10));
  });
}
