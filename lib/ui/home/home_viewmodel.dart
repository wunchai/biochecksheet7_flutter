// lib/ui/home/home_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart'; // <<< เพิ่ม import
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // สำหรับ SyncStatus
import 'package:drift/drift.dart' as drift; // Alias drift to avoid conflict with dart:core.String

class HomeViewModel extends ChangeNotifier {
  final JobDao _jobDao;
 final DataSyncService _dataSyncService; // <<< เพิ่ม DataSyncService
  // No longer needed: String _welcomeMessage = "Welcome Home!";

  // For Search/Filter TextFields
  final TextEditingController _editText5Controller = TextEditingController();
  final TextEditingController _editText6Controller = TextEditingController();

  String? _filterText5; // Corresponds to editText5
  String? _filterText6; // Corresponds to editText6
  
  // Loading state for ProgressBar
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _syncMessage; // สำหรับแสดงข้อความสถานะ Sync ใน Home
  String? get syncMessage => _syncMessage;

  // Stream for jobs, now will be filtered
  Stream<List<DbJob>>? _jobsStream;
  Stream<List<DbJob>>? get jobsStream => _jobsStream;

  set syncMessage(String? value) { // <<< เพิ่ม setter นี้
    _syncMessage = value;
    // notifyListeners(); // ไม่จำเป็นต้อง notifyListeners() ที่นี่เพราะมันจะถูกเรียกอีกครั้งหลัง setState ใน widget
  }

  HomeViewModel({JobDao? jobDao, DataSyncService? dataSyncService})
      : _jobDao = jobDao ?? AppDatabase.instance.jobDao,
        _dataSyncService = dataSyncService ?? DataSyncService() { // <<< สร้าง instance ของ DataSyncService
    _applyJobFilters();
  }

  // Dispose controllers
  @override
  void dispose() {
    _editText5Controller.dispose();
    _editText6Controller.dispose();
    super.dispose();
  }

  // Getters for controllers (for use in UI)
  TextEditingController get editText5Controller => _editText5Controller;
  TextEditingController get editText6Controller => _editText6Controller;

  // Method to handle search/filter button clicks or text changes
  void applyFilters() {
    _filterText5 = _editText5Controller.text.trim();
    _filterText6 = _editText6Controller.text.trim();
    _applyJobFilters();
  }

  // This method will now apply filters to the job query
  void _applyJobFilters() {
    _isLoading = true; // Set loading state
    notifyListeners();

    // Start with a base query
    drift.SimpleSelectStatement<$JobsTable, DbJob> query = _jobDao.select(
        _jobDao.jobs); // Use _jobDao.select to get a query builder instance

    // Apply filters if text is not empty
    if (_filterText5 != null && _filterText5!.isNotEmpty) {
      query = query..where((tbl) => tbl.jobName.contains(_filterText5!)); // Example: Filter by jobName
    }
    if (_filterText6 != null && _filterText6!.isNotEmpty) {
      query = query..where((tbl) => tbl.location.contains(_filterText6!)); // Example: Filter by location
    }

    _jobsStream = query.watch(); // Watch the filtered query
    _isLoading = false; // Reset loading state
    notifyListeners();
  }

  // เมธอดสำหรับ Refresh Button (Full Sync)
  Future<void> performFullSync() async {
    _isLoading = true;
    _syncMessage = "Syncing all data..."; // ข้อความเริ่มต้น Sync
    notifyListeners();

    try {
      final result = await _dataSyncService.performFullSync(); // <<< เรียกใช้ Full Sync

      if (result is SyncSuccess) {
        _syncMessage = "All data synced successfully!";
        _applyJobFilters(); // Re-apply filters to show new data
      } else if (result is SyncFailed) {
        _syncMessage = "Sync failed: ${result.errorMessage}";
      } else if (result is SyncError) {
        _syncMessage = "Sync error: ${result.exception.toString()}";
      }
    } catch (e) {
      _syncMessage = "An unexpected error occurred during full sync: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // You might want methods for specific button actions if they do more than just apply filters
  void onButton3Pressed() {
    print("Button 3 Pressed!"); // Placeholder
    // Example: Clear editText5
    _editText5Controller.clear();
    applyFilters(); // Re-apply filters after clearing
  }

  void onButton4Pressed() {
    print("Button 4 Pressed!"); // Placeholder
    // Example: Clear editText6
    _editText6Controller.clear();
    applyFilters(); // Re-apply filters after clearing
  }
}