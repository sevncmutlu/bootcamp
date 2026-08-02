import 'notification_scheduler_contract.dart';

MakiNotificationScheduler createMakiNotificationScheduler() =>
    const _NoopNotificationScheduler();

class _NoopNotificationScheduler implements MakiNotificationScheduler {
  const _NoopNotificationScheduler();

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize(NotificationOpened onOpened) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {}
}
