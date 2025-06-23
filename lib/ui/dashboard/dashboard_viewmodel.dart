// lib/ui/dashboard/dashboard_viewmodel.dart
import 'package:flutter/material.dart';

// Data model for a dashboard item (similar to DashboardPlaceholderContent.kt.DummyItem)
class DashboardItem {
  final String id;
  final String content;
  final String details;

  DashboardItem({required this.id, required this.content, required this.details});
}

/// Equivalent to DashboardViewModel.kt
class DashboardViewModel extends ChangeNotifier {
  List<DashboardItem> _dashboardItems = [];
  List<DashboardItem> get dashboardItems => _dashboardItems;

  String _message = "Welcome to Dashboard!";
  String get message => _message;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DashboardViewModel() {
    _loadDashboardItems();
  }

  void _loadDashboardItems() {
    _isLoading = true;
    notifyListeners();

    // Simulate fetching data, similar to placeholder content
    Future.delayed(const Duration(seconds: 1), () {
      _dashboardItems = List.generate(
        5, // Generate 5 placeholder items
        (i) => DashboardItem(
          id: '${i + 1}',
          content: 'Dashboard Item ${i + 1}',
          details: 'Details for item ${i + 1}',
        ),
      );
      _message = "Dashboard data loaded.";
      _isLoading = false;
      notifyListeners();
    });
  }

  void refreshDashboard() {
    _message = "Refreshing dashboard...";
    _loadDashboardItems(); // Reloads items
  }

  // In the future, you might add methods to interact with DAOs here, e.g.:
  /*
  Future<void> loadSummaryData(JobDao jobDao) async {
    _isLoading = true;
    notifyListeners();
    // Example: Get total jobs
    final allJobs = await jobDao.getAllJobs();
    _dashboardItems = [
      DashboardItem(id: '1', content: 'Total Jobs', details: '${allJobs.length}'),
      // Add more summary items
    ];
    _isLoading = false;
    notifyListeners();
  }
  */
}