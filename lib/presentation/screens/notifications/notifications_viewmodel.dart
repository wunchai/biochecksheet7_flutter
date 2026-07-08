import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' hide Notification;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:drift/drift.dart' as drift;
import 'package:biochecksheet7_flutter/data/services/fcm_service.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/notification_dao.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationDao dao;
  
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  
  late StreamSubscription<List<Notification>> _dbSubscription;
  late StreamSubscription<int> _unreadSubscription;
  late StreamSubscription<RemoteMessage> _fcmSubscription;

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => false;

  NotificationsViewModel({required this.dao}) {
    // Listen to DB changes
    _dbSubscription = dao.watchAllNotifications().listen((data) {
      _notifications = data;
      notifyListeners();
    });

    _unreadSubscription = dao.watchUnreadCount().listen((count) {
      _unreadCount = count;
      notifyListeners();
    });

    // Listen to incoming FCM messages and insert to DB
    _fcmSubscription = fcmService.messageStream.listen((message) {
      if (message.notification != null) {
        dao.insertNotification(
          NotificationsCompanion.insert(
            title: message.notification?.title ?? 'No Title',
            body: message.notification?.body ?? 'No Content',
            timestamp: DateTime.now(),
            isRead: const drift.Value(false),
            payloadData: drift.Value(jsonEncode(message.data)),
          ),
        );
      }
    });
  }

  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;
    await dao.markAllAsRead();
  }

  Future<void> clearAll() async {
    await dao.clearAllNotifications();
  }

  @override
  void dispose() {
    _dbSubscription.cancel();
    _unreadSubscription.cancel();
    _fcmSubscription.cancel();
    super.dispose();
  }
}