import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/notification_table.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AppDatabase> with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Stream<List<Notification>> watchUserNotifications(String userId) {
    return (select(notifications)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Stream<int> watchUnreadCountForUser(String userId) {
    final countExp = notifications.id.count();
    final query = selectOnly(notifications)
      ..addColumns([countExp])
      ..where(notifications.userId.equals(userId) & notifications.isRead.equals(false));
      
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<int> getMaxServerId(String userId) async {
    final maxExp = notifications.serverId.max();
    final query = selectOnly(notifications)
      ..addColumns([maxExp])
      ..where(notifications.userId.equals(userId));

    final row = await query.getSingleOrNull();
    return row?.read(maxExp) ?? 0;
  }

  Future<int> insertNotification(NotificationsCompanion companion) {
    return into(notifications).insert(companion);
  }

  Future<void> markAllAsReadForUser(String userId) async {
    await (update(notifications)
          ..where((t) => t.userId.equals(userId) & t.isRead.equals(false)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  Future<void> markAsRead(int id) async {
    await (update(notifications)..where((t) => t.id.equals(id)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  Future<void> clearAllNotificationsForUser(String userId) async {
    await (delete(notifications)..where((t) => t.userId.equals(userId))).go();
  }
}
