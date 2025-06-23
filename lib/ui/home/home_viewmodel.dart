// lib/ui/home/home_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
// Removed unused import: import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:drift/drift.dart' as drift;

class HomeViewModel extends ChangeNotifier {
  final JobDao _jobDao; // Now direct instance
  final DataSyncService _dataSyncService;

  // Removed unnecessary getters/setters for controllers, access directly
  final TextEditingController editText5Controller = TextEditingController();
  final TextEditingController editText6Controller = TextEditingController();

  String? _filterText5;
  String? _filterText6;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    // Added setter to clear message
    _syncMessage = value;
    notifyListeners(); // Notify listeners when sync message changes
  }

  Stream<List<DbJob>>? _jobsStream;
  Stream<List<DbJob>>? get jobsStream => _jobsStream;

  // Constructor now takes resolved AppDatabase instance
  HomeViewModel(
      {required AppDatabase appDatabase, DataSyncService? dataSyncService})
      : _jobDao = appDatabase.jobDao, // Access dao directly
        _dataSyncService =
            dataSyncService ?? DataSyncService(appDatabase: appDatabase) {
    // Pass appDatabase to DataSyncService
    _applyJobFilters();
  }

  @override
  void dispose() {
    editText5Controller.dispose();
    editText6Controller.dispose();
    super.dispose();
  }

  void applyFilters() {
    _filterText5 = editText5Controller.text.trim();
    _filterText6 = editText6Controller.text.trim();
    _applyJobFilters();
  }

  void _applyJobFilters() {
    _isLoading = true;
    _syncMessage = null;
    notifyListeners();

    drift.SimpleSelectStatement<$JobsTable, DbJob> query =
        _jobDao.select(_jobDao.jobs);

    if (_filterText5 != null && _filterText5!.isNotEmpty) {
      query = query..where((tbl) => tbl.jobName.contains(_filterText5!));
    }
    if (_filterText6 != null && _filterText6!.isNotEmpty) {
      query = query..where((tbl) => tbl.location.contains(_filterText6!));
    }

    _jobsStream = query.watch();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> performFullSync() async {
    _isLoading = true;
    _syncMessage = "Syncing all data...";
    notifyListeners();

    try {
      final result = await _dataSyncService.performFullSync();

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

  // You can remove or re-purpose refreshJobs if performFullSync covers it
  // For now, let's keep a basic refresh that just re-applies filters without a full sync.
  Future<void> refreshJobs() async {
    _applyJobFilters(); // Re-apply current filters
  }

  // Placeholder methods for buttons
  void onButton3Pressed() {
    print("Button 3 Pressed!");
    editText5Controller.clear();
    applyFilters();
  }

  void onButton4Pressed() {
    print("Button 4 Pressed!");
    editText6Controller.clear();
    applyFilters();
  }
}
