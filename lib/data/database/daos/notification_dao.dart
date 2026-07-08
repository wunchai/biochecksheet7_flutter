import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/notification_table.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AppDatabase> with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Stream<List<Notification>> watchAllNotifications() {
    return (select(notifications)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).watch();
  }

  Stream<int> watchUnreadCount() {
    final countExp = notifications.id.count();
    final query = selectOnly(notifications)
      ..addColumns([countExp])
      ..where(notifications.isRead.equals(false));
      
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<int> insertNotification(NotificationsCompanion companion) {
    return into(notifications).insert(companion);
  }

  Future<void> markAllAsRead() async {
    await (update(notifications)..where((t) => t.isRead.equals(false)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  Future<void> clearAllNotifications() async {
    await delete(notifications).go();
  }
}
