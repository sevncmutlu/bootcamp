typedef NotificationOpened = Future<void> Function(String payload);

abstract interface class MakiNotificationScheduler {
  Future<void> initialize(NotificationOpened onOpened);

  Future<bool> requestPermission();

  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  });

  Future<void> cancelAll();
}
