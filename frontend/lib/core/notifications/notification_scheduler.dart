import 'notification_scheduler_contract.dart';
import 'notification_scheduler_stub.dart'
    if (dart.library.io) 'notification_scheduler_native.dart'
    as platform;

export 'notification_scheduler_contract.dart';

MakiNotificationScheduler createMakiNotificationScheduler() =>
    platform.createMakiNotificationScheduler();
