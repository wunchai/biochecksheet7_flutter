// lib/ui/notifications/notifications_viewmodel.dart
import 'package:flutter/material.dart';

/// Equivalent to NotificationsViewModel.kt
class NotificationsViewModel extends ChangeNotifier {
  String _text = 'This is notifications fragment';
  String get text => _text;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationsViewModel() {
    _loadNotifications();
  }

  void _loadNotifications() {
    _isLoading = true;
    notifyListeners();

    // Simulate fetching notifications
    Future.delayed(const Duration(seconds: 1), () {
      _text = "Notifications loaded: You have 3 new messages!";
      _isLoading = false;
      notifyListeners();
    });
  }

  void refreshNotifications() {
    _text = "Refreshing notifications...";
    _loadNotifications(); // Reloads items
  }
}