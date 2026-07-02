import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:biochecksheet7_flutter/data/services/fcm_service.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationsViewModel extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  late StreamSubscription<RemoteMessage> _subscription;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationsViewModel() {
    // Listen to incoming FCM messages
    _subscription = fcmService.messageStream.listen((message) {
      if (message.notification != null) {
        _addNotification(
          message.notification?.title ?? 'No Title',
          message.notification?.body ?? 'No Content',
        );
      }
    });
  }

  void _addNotification(String title, String body) {
    // Add to the top of the list
    _notifications.insert(
      0,
      NotificationItem(
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );
    _unreadCount++;
    notifyListeners();
  }

  void markAllAsRead() {
    if (_unreadCount == 0) return;
    
    for (var item in _notifications) {
      item.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}