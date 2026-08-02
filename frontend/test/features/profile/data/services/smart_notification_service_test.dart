import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/notifications/notification_scheduler.dart';
import 'package:maki_app/features/profile/data/services/smart_notification_service.dart';
import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SharedPreferences preferences;
  late _FakeScheduler scheduler;
  late _MutableClock clock;
  late SmartNotificationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    scheduler = _FakeScheduler();
    clock = _MutableClock(DateTime(2026, 8, 3, 8));
    service = SmartNotificationService(
      database: database,
      preferences: preferences,
      scheduler: scheduler,
      gaussianSource: const _ZeroGaussian(),
      clock: clock,
    );
  });

  tearDown(() => database.close());

  test('izin sonrası LinTS kararıyla günde tek bildirim planlar', () async {
    await service.initialize();
    expect(scheduler.scheduled, isEmpty);

    expect(await service.requestAndEnable(), isTrue);
    expect(scheduler.scheduled, hasLength(1));
    expect(scheduler.scheduled.single.at.hour, 14);

    await service.scheduleNext();
    expect(scheduler.scheduled, hasLength(1));

    final engagement = await database
        .select(database.notificationEngagements)
        .getSingle();
    expect(engagement.arm, 'afternoon');
    expect(engagement.rewardSettledAt, isNull);
  });

  test('açılıştan sonraki finans işlemini bir kez tam ödüllendirir', () async {
    await service.initialize();
    await service.requestAndEnable();
    await scheduler.openLast();
    await service.recordMeaningfulAction();
    await service.recordMeaningfulAction();

    final engagement = await database
        .select(database.notificationEngagements)
        .getSingle();
    expect(engagement.openedAt, isNotNull);
    expect(engagement.meaningfulActionAt, isNotNull);
    expect(engagement.rewardValue, 1);

    final snapshot = await database
        .select(database.notificationPolicySnapshots)
        .getSingle();
    final state = LinTsState.fromJson(
      Map<String, Object?>.from(jsonDecode(snapshot.stateJson) as Map),
    );
    expect(state.decisions.single.reward, 1);
  });

  test('24 saatte açılmayan kararı sıfır ödülle kapatır', () async {
    await service.initialize();
    await service.requestAndEnable();
    final firstId =
        (await database.select(database.notificationEngagements).getSingle())
            .id;

    clock.value = clock.value.add(const Duration(hours: 40));
    await service.scheduleNext();

    final first = await (database.select(
      database.notificationEngagements,
    )..where((row) => row.id.equals(firstId))).getSingle();
    expect(first.rewardValue, 0);
    expect(first.rewardSettledAt, isNotNull);
  });
}

class _FakeScheduler implements MakiNotificationScheduler {
  NotificationOpened? onOpened;
  bool permissionGranted = true;
  final scheduled = <_Scheduled>[];

  @override
  Future<void> initialize(NotificationOpened onOpened) async {
    this.onOpened = onOpened;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    scheduled.add(_Scheduled(at: at, payload: payload));
  }

  Future<void> openLast() async {
    await onOpened!(scheduled.last.payload);
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();
}

class _Scheduled {
  const _Scheduled({required this.at, required this.payload});

  final DateTime at;
  final String payload;
}

class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class _ZeroGaussian implements GaussianSource {
  const _ZeroGaussian();

  @override
  double next() => 0;
}
