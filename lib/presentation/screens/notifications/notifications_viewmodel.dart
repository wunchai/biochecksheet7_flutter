import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:biochecksheet7_flutter/data/database/app_database.dart' as db;
import 'package:biochecksheet7_flutter/data/database/daos/notification_dao.dart';

class NotificationsViewModel extends ChangeNotifier {
  final DocumentOnlineApiService apiService;
  final LoginRepository loginRepository;
  final NotificationDao dao;

  List<db.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  StreamSubscription? _notificationsSub;
  StreamSubscription? _unreadCountSub;

  List<db.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  String? _currentUserId;

  NotificationsViewModel({
    required this.apiService,
    required this.loginRepository,
    required this.dao,
  }) {
    _init();
  }

  void _init() {
    final user = loginRepository.loggedInUser;
    if (user != null) {
      _currentUserId = user.userId;
      _subscribeToUserNotifications(user.userId);
      fetchNotifications();
    }
  }

  void _subscribeToUserNotifications(String userId) {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();

    _notificationsSub = dao.watchUserNotifications(userId).listen((data) {
      _notifications = data;
      notifyListeners();
    });

    _unreadCountSub = dao.watchUnreadCountForUser(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications({int pageIndex = 1, int pageSize = 20, bool forceRefresh = false}) async {
    final user = loginRepository.loggedInUser;
    if (user == null) return;

    if (_currentUserId != user.userId) {
      _currentUserId = user.userId;
      _subscribeToUserNotifications(user.userId);
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get max serverId for this user
      final maxId = await dao.getMaxServerId(user.userId);
      
      // We pass the lastId to the API so we only get newer ones
      final response = await apiService.getNotificationHistory(
        user.userId,
        pageIndex: pageIndex,
        pageSize: pageSize,
        lastId: maxId,
      );

      if (response != null && response.status == 'success') {
        // We do NOT clear the local database. We only insert new ones.
        for (var item in response.history) {
          // Check if already exists locally to prevent duplicates
          if (_notifications.any((n) => n.serverId == item.id)) {
            continue;
          }
          
          final isSuccess = item.isSuccess ?? false;
          final title = item.jobName ?? 'การแจ้งเตือน';
          final body = isSuccess 
              ? 'ดำเนินการสำเร็จ' 
              : (item.errorMessage ?? 'มีข้อผิดพลาดบางอย่างเกิดขึ้น');
          final sendDate = item.sendDate != null 
              ? DateTime.tryParse(item.sendDate!) ?? DateTime.now() 
              : DateTime.now();

          // Match payload with fcm_service.dart expectations
          final payload = {
            "documentId": item.documentId,
            "jobId": item.jobId,
            "machineId": item.machineId,
            "target_screen": item.targetScreen,
            "title": title,
            "userId": item.userId,
          };

          await dao.insertNotification(db.NotificationsCompanion(
            serverId: drift.Value(item.id),
            userId: drift.Value(item.userId),
            title: drift.Value(title),
            body: drift.Value(body),
            timestamp: drift.Value(sendDate),
            payloadData: drift.Value(jsonEncode(payload)),
            isRead: const drift.Value(false), // New notifications are unread by default
          ));
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId != null) {
      await dao.markAllAsReadForUser(_currentUserId!);
    }
  }

  Future<void> markAsRead(int id) async {
    await dao.markAsRead(id);
  }
}