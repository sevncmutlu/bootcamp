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

  test('seeding daily challenges creates exactly 3 challenges for a date', () async {
    final now = DateTime(2026, 7, 15);
    final challenges = await service.getOrSeedDailyChallenges(now);

    expect(challenges.length, equals(3));
    expect(challenges.any((c) => c.titleKey == 'challengeCookHome'), isTrue);
    expect(challenges.any((c) => c.titleKey == 'challengeLogThree'), isTrue);
    expect(challenges.any((c) => c.titleKey == 'challengeNoShopping'), isTrue);
  });

  test('automated evaluation correctly checks daily constraints', () async {
    final now = DateTime(2026, 7, 15);
    
    // Seed challenges
    await service.getOrSeedDailyChallenges(now);

    // 1. Insert 3 expenses (two Market/Shopping, one Restaurant)
    await db.insertExpense(ExpensesCompanion.insert(
      title: 'Lunch',
      amount: 45.0,
      date: now,
      category: 'Restaurant',
    ));
    await db.insertExpense(ExpensesCompanion.insert(
      title: 'Groceries',
      amount: 120.0,
      date: now,
      category: 'Market',
    ));
    await db.insertExpense(ExpensesCompanion.insert(
      title: 'Books',
      amount: 90.0,
      date: now,
      category: 'Shopping',
    ));

    // Evaluate
    await service.evaluateDailyChallenges(now);

    final updated = await db.getChallengesForDate(now);
    
    // Cook at Home should be false (since we spent in Restaurant category)
    final cookHome = updated.firstWhere((c) => c.titleKey == 'challengeCookHome');
    expect(cookHome.isCompleted, isFalse);

    // Log Three should be true (since we logged 3 expenses today)
    final logThree = updated.firstWhere((c) => c.titleKey == 'challengeLogThree');
    expect(logThree.isCompleted, isTrue);

    // No Shopping should be false (since we spent in Market/Shopping categories)
    final noShopping = updated.firstWhere((c) => c.titleKey == 'challengeNoShopping');
    expect(noShopping.isCompleted, isFalse);
  });

  test('claiming completed challenge awards XP and handles level-up correctly', () async {
    final now = DateTime(2026, 7, 15);
    await service.getOrSeedDailyChallenges(now);

    // Complete the Log 3 challenge
    final list = await db.getChallengesForDate(now);
    final logThree = list.firstWhere((c) => c.titleKey == 'challengeLogThree');
    
    final completed = logThree.copyWith(isCompleted: true);
    await db.updateChallenge(completed);

    // Claim XP
    final state = await service.claimXP(completed);

    expect(state.level, equals(1));
    expect(state.xp, equals(20)); // rewarded 20 XP
    expect(state.badges.contains('badgeSavingsSeed'), isTrue);

    // Simulate level up by claiming another massive challenge
    final massiveChallenge = completed.copyWith(xpReward: 90, id: 'massive');
    final levelUpState = await service.claimXP(massiveChallenge);

    // level 1 needs 100 XP. 20 + 90 = 110 XP.
    // 110 XP - 100 XP = 10 XP, level 2.
    expect(levelUpState.level, equals(2));
    expect(levelUpState.xp, equals(10));
  });
}
