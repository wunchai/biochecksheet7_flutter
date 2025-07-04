// lib/ui/home/home_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/job_repository.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import api_response_models.dart
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart'; // Make sure LoginViewModel is imported
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // Make sure LoginRepository is imported
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:drift/drift.dart' as drift;
import 'package:provider/provider.dart';

class HomeViewModel extends ChangeNotifier {
    final JobRepository _jobRepository;
  final LoginRepository _loginRepository;
  final DataSyncService _dataSyncService;

  String? _searchQuery; // <<< NEW: Search Query property
  String? get searchQuery => _searchQuery; // Getter for search query

  String? _filterText5;
  String? _filterText6;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;

  String _statusMessage = "กำลังโหลดข้อมูล..."; // Default initial message
  String get statusMessage => _statusMessage;


  set syncMessage(String? value) {
    // Added setter to clear message
    _syncMessage = value;
    notifyListeners(); // Notify listeners when sync message changes
  }

  Stream<List<DbJob>>? _jobsStream;
  Stream<List<DbJob>>? get jobsStream => _jobsStream;

  // Constructor now takes resolved AppDatabase instance
  HomeViewModel(
      {required AppDatabase appDatabase,required LoginRepository loginRepository, DataSyncService? dataSyncService})
      :  _jobRepository = JobRepository(appDatabase: appDatabase),
        _loginRepository = loginRepository, // <<< Initialize from parameter
        _dataSyncService =
            dataSyncService ?? DataSyncService(appDatabase: appDatabase) {
              loadJobs();
    // Pass appDatabase to DataSyncService
    //_applyJobFilters();
  }

  @override
  void dispose() {
   
    super.dispose();
  }

 

  
  Future<void> performFullSync() async {
    _isLoading = true;
    _syncMessage = "Syncing all data...";
    notifyListeners();

    try {
      final result = await _dataSyncService.performFullSync();

      if (result is SyncSuccess) {
        _syncMessage = "All data synced successfully!";
       // _applyJobFilters(); // Re-apply filters to show new data
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


  // Method to load jobs from the repository (now includes search filter)
  Future<void> loadJobs() async {
    _isLoading = true;
    _statusMessage = "กำลังดึงข้อมูล Jobs...";
    notifyListeners();

    try {
      // Pass searchQuery to the repository method (if your jobDao supports it)
      // For now, let's assume watchAllJobs can be filtered by a property in the future.
      _jobsStream = _jobRepository.watchAllJobs(); // TODO: Modify watchAllJobs to accept search query
      _statusMessage = "Jobs โหลดแล้ว.";
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลด Jobs ได้: $e";
      print("Error loading jobs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to refresh jobs (e.g., after a sync)
  Future<void> refreshJobs() async {
    _isLoading = true;
    _syncMessage = "กำลัง Refresh Jobs...";
    _statusMessage = "กำลัง Refresh Jobs...";
    notifyListeners();

    try {
      final syncResult = await _dataSyncService.performFullSync(); // Perform a full sync
      if (syncResult is SyncSuccess) {
        _syncMessage = syncResult.message;
      } else if (syncResult is SyncError) {
        _syncMessage = syncResult.exception.toString();
      }
      await loadJobs(); // Reload jobs from local DB after sync
      _syncMessage = "Jobs Refresh แล้ว!";
    } catch (e) {
      _syncMessage = "ข้อผิดพลาดในการ Refresh Jobs: $e";
      _statusMessage = "ข้อผิดพลาดในการ Refresh Jobs.";
      print("Error refreshing jobs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

 /// NEW: Sets the search query and reloads jobs based on the new query.
  void setSearchQuery(String query) {
    // Only update if the query has actually changed to avoid unnecessary rebuilds.
    if (_searchQuery != query) {
      _searchQuery = query;
      // Reload jobs with the new search filter.
      // This will trigger the StreamBuilder in HomeScreen to update.
      loadJobs(); // Reload jobs with the new filter (loadJobs needs to be updated to use _searchQuery)
    }
  }
  


   /// อัปโหลด DocumentRecords ทั้งหมดที่มี status 2 และ syncStatus 0 ขึ้น Server.
  Future<void> uploadAllDocumentRecords() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังอัปโหลด DocumentRecords...";
    notifyListeners();

    try {
      final syncResult = await _dataSyncService.performDocumentRecordUploadSync();

      if (syncResult is SyncSuccess) {
        _syncMessage = syncResult.message;
        _statusMessage = "อัปโหลด DocumentRecords สำเร็จ.";
      } else if (syncResult is SyncError) {
        _syncMessage = syncResult.exception;
        _statusMessage = "อัปโหลด DocumentRecords ล้มเหลว.";
      }
    } catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปโหลด DocumentRecords: $e";
      _statusMessage = "อัปโหลด DocumentRecords ล้มเหลว: $e";
      print("Error uploading all document records: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      // อาจจะต้อง refresh jobs ด้วย ถ้าการอัปโหลดมีผลต่อการแสดงผลของ Job
      // หรือเพียงแค่ notifyListeners() เพื่ออัปเดตสถานะ
    }
  }
  // Calls LoginViewModel's logout method.
 /// Calls LoginViewModel's logout method.
  /// This is the correct way to trigger logout from HomeViewModel.
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังออกจากระบบ...";
    notifyListeners();

    try {
      final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
      await loginViewModel.logout(context); // <<< CRUCIAL FIX: Pass context here

      _syncMessage = "ออกจากระบบสำเร็จ!";
      _statusMessage = "ออกจากระบบแล้ว.";
    } catch (e) {
      _syncMessage = "ข้อผิดพลาดในการออกจากระบบ: $e";
      _statusMessage = "ออกจากระบบล้มเหลว: $e";
      print("Error during logout: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
