import '../../models/notification_item.dart';
import '../mock/mock_notifications.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> getNotifications();
  Future<void> markAllRead();
}

class MockNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationItem>> getNotifications() => Future.value(mockNotifications);

  @override
  Future<void> markAllRead() async {}
}
