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

  test('bağlam üretimi doğru boyut ve hafta sonu değerini döndürür', () async {
    final weekday = DateTime(2026, 7, 15); // Çarşamba
    final weekend = DateTime(2026, 7, 19); // Pazar

    final xWeekday = service.getContext(weekday);
    final xWeekend = service.getContext(weekend);

    expect(xWeekday.length, equals(2));
    expect(xWeekday[0], equals(1.0));
    expect(xWeekday[1], equals(0.0)); // Hafta sonu değil.

    expect(xWeekend.length, equals(2));
    expect(xWeekend[0], equals(1.0));
    expect(xWeekend[1], equals(1.0)); // Hafta sonu.
  });

  test(
    'uygun saat tahmini geçerli kol saati döndürür ve güncellenir',
    () async {
      final now = DateTime(2026, 7, 15);

      final initialHour = await service.predictOptimalHour(now);
      expect([9, 14, 20].contains(initialHour), isTrue);

      for (int i = 0; i < 15; i++) {
        await service.updateFeedback('evening', now, 1.0);
      }

      for (int i = 0; i < 15; i++) {
        await service.updateFeedback('morning', now, 0.0);
      }

      int eveningCount = 0;
      for (int i = 0; i < 20; i++) {
        final hour = await service.predictOptimalHour(now);
        if (hour == 20) {
          eveningCount++;
        }
      }

      expect(eveningCount, greaterThan(15));
    },
  );
}
