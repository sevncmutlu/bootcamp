import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/services/lints_bandit_service.dart';

void main() {
  late AppDatabase db;
  late LintsBanditService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = LintsBanditService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('context generation returns correct dimension and weekend value', () async {
    final weekday = DateTime(2026, 7, 15); // Wednesday
    final weekend = DateTime(2026, 7, 19); // Sunday

    final xWeekday = service.getContext(weekday);
    final xWeekend = service.getContext(weekend);

    expect(xWeekday.length, equals(2));
    expect(xWeekday[0], equals(1.0));
    expect(xWeekday[1], equals(0.0)); // not weekend

    expect(xWeekend.length, equals(2));
    expect(xWeekend[0], equals(1.0));
    expect(xWeekend[1], equals(1.0)); // weekend
  });

  test('predicting optimal hour returns valid arm hours and handles updates', () async {
    final now = DateTime(2026, 7, 15);
    
    // Initial prediction should be safe (one of 9, 14, 20)
    final initialHour = await service.predictOptimalHour(now);
    expect([9, 14, 20].contains(initialHour), isTrue);

    // 1. Train the 'evening' arm with a positive reward (1.0) 15 times to build high preference
    for (int i = 0; i < 15; i++) {
      await service.updateFeedback('evening', now, 1.0);
    }

    // 2. Train the 'morning' arm with a negative reward (0.0) 15 times to discourage it
    for (int i = 0; i < 15; i++) {
      await service.updateFeedback('morning', now, 0.0);
    }

    // 3. Since 'evening' has high reward expectation and 'morning' has low,
    // predictions should lock onto the evening arm (hour 20) with high probability.
    int eveningCount = 0;
    for (int i = 0; i < 20; i++) {
      final hour = await service.predictOptimalHour(now);
      if (hour == 20) {
        eveningCount++;
      }
    }

    expect(eveningCount, greaterThan(15));
  });
}
