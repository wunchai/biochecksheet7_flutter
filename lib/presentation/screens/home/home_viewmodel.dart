// lib/ui/home/home_viewmodel.dart
import 'package:flutter/material.dart';
//import 'package:drift/drift.dart' as drift;
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/job_repository.dart';
//import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import api_response_models.dart
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart'; // Make sure LoginViewModel is imported
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // Make sure LoginRepository is imported
//import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart'; // <<< NEW: Import DeviceInfoService
//import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import API Response Models (for SyncMetadataResponse)

class HomeViewModel extends ChangeNotifier {
  final JobRepository _jobRepository;
  final LoginRepository _loginRepository;
  final DataSyncService _dataSyncService;
  final DeviceInfoService
      _deviceInfoService; // <<< NEW: Add DeviceInfoService dependency

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
      {required AppDatabase appDatabase,
      required LoginRepository loginRepository,
      DataSyncService? dataSyncService})
      : _jobRepository = JobRepository(appDatabase: appDatabase),
        _loginRepository = loginRepository, // <<< Initialize from parameter
        _dataSyncService =
            dataSyncService ?? DataSyncService(appDatabase: appDatabase),
        _deviceInfoService =
            DeviceInfoService() // <<< NEW: Initialize DeviceInfoService
  {
    loadJobs();
  }

  // --- <<< ส่วนที่เพิ่มใหม่ >>> ---
  final ValueNotifier<double?> syncProgressNotifier = ValueNotifier(null);
  final ValueNotifier<String> syncStatusNotifier = ValueNotifier('');

  /// Performs manual metadata sync and processes server actions.
  Future<void> performManualMetadataSync() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังซิงค์ข้อมูล Metadata...";
    notifyListeners();

    try {
      // 1. Get device info
      final String deviceId = await _deviceInfoService.getDeviceId();
      final String serialNo = await _deviceInfoService.getSerialNo();
      final String appVersion = await _deviceInfoService.getAppVersion();
      final String ipAddress = await _deviceInfoService.getIpAddress();
      final String wifiStrength = await _deviceInfoService.getWifiStrength();
      final String username =
          _loginRepository.loggedInUser?.userId ?? 'unknown_user';

      // 2. Call checkSyncMetadata API
      final List<SyncMetadataResponse> syncMetadataResults =
          await _dataSyncService.checkSyncMetadata(
        username: username,
        deviceId: deviceId,
        serialNo: serialNo,
        version: appVersion,
        ipAddress: ipAddress,
        wifiStrength: wifiStrength,
      );

      // 3. Process actions from server response
      bool allActionsSuccessful = true;
      for (final action in syncMetadataResults) {
        print(
            "HomeViewModel: Processing action: ${action.actionType} (ID: ${action.actionId})");
        switch (action.actionType) {
          case "transferDB":
            final result = await _dataSyncService.databaseMaintenanceService
                .backupAndUploadDb(
                    userId: username,
                    deviceId: deviceId); // <<< CRUCIAL FIX: Use getter
            if (result is SyncError) allActionsSuccessful = false;
            break;
          case "update":
            if (action.actionSql != null && action.actionSql!.isNotEmpty) {
              final result = await _dataSyncService.databaseMaintenanceService
                  .executeRawSqlQuery(
                      action.actionSql!); // <<< CRUCIAL FIX: Use getter
              if (result is SyncError) allActionsSuccessful = false;
            }
            break;
          case "cleanEndData":
            final result = await _dataSyncService.dataCleanupService
                .cleanEndData(); // <<< CRUCIAL FIX: Use getter
            if (result is SyncError) allActionsSuccessful = false;
            break;
          default:
            print("HomeViewModel: Unknown actionType: ${action.actionType}");
            allActionsSuccessful = false;
            break;
        }
      }
      await _dataSyncService.performFullSync();

      if (allActionsSuccessful) {
        _syncMessage = "ซิงค์ Metadata และดำเนินการสำเร็จ!";
        _statusMessage = "ซิงค์สำเร็จ.";
      } else {
        _syncMessage = "ซิงค์ Metadata และดำเนินการบางส่วนล้มเหลว.";
        _statusMessage = "ซิงค์ล้มเหลว.";
      }
    } catch (e) {
      _syncMessage = "ข้อผิดพลาดในการซิงค์ Metadata: $e";
      _statusMessage = "ซิงค์ Metadata ล้มเหลว: $e";
      print("Error performing manual metadata sync: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _jobsStream = _jobRepository
          .watchAllJobs(); // TODO: Modify watchAllJobs to accept search query
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
  Future<SyncStatus> refreshJobs() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลัง Refresh Jobs...";
    notifyListeners();
    SyncStatus resultStatus = const SyncSuccess(message: "เริ่มต้นการ Refresh");

    try {
      final syncResult =
          await _dataSyncService.performFullSync(); // Perform a full sync
      if (syncResult is SyncSuccess) {
        _syncMessage = syncResult.message;
        _statusMessage =
            "Refresh Jobs สำเร็จ."; // Update status message on success
        resultStatus = syncResult;
      } else if (syncResult is SyncError) {
        _syncMessage = syncResult.exception.toString();
        _statusMessage =
            "Refresh Jobs ล้มเหลว."; // Update status message on error
        resultStatus = syncResult;
      }
      notifyListeners();
      await loadJobs(); // Reload jobs from local DB after sync
    } catch (e) {
      resultStatus = SyncError(
          exception: e,
          message: "ข้อผิดพลาดที่ไม่คาดคิดในการ Refresh Jobs: $e");
      _syncMessage = "ข้อผิดพลาดในการ Refresh Jobs: $e";
      _statusMessage = "ข้อผิดพลาดในการ Refresh Jobs.";
      print("Error refreshing jobs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return resultStatus;
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
  Future<SyncStatus> uploadAllDocumentRecords() async {
    // <<< CRUCIAL FIX: Change return type to Future<SyncStatus>
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังอัปโหลด DocumentRecords และรูปภาพ...";
    notifyListeners();
    SyncStatus finalResultStatus;

    try {
      // 1. Upload DocumentRecords
      final docSyncResult =
          await _dataSyncService.performDocumentRecordUploadSync();

      // 2. Upload associated Images
      final imageSyncResult = await _dataSyncService
          .performImageUploadSync(); // <<< NEW: Call image upload

      bool allSuccessful = true;
      String finalMessage = "";

      if (docSyncResult is SyncSuccess) {
        finalMessage += "อัปโหลดบันทึก: ${docSyncResult.message}\n";
      } else if (docSyncResult is SyncError) {
        finalMessage += "อัปโหลดบันทึกล้มเหลว: ${docSyncResult.exception}\n";
        allSuccessful = false;
      }

      if (imageSyncResult is SyncSuccess) {
        finalMessage += "อัปโหลดรูปภาพ: ${imageSyncResult.message}\n";
      } else if (imageSyncResult is SyncError) {
        finalMessage += "อัปโหลดรูปภาพล้มเหลว: ${imageSyncResult.exception}\n";
        allSuccessful = false;
      }

      // CRUCIAL FIX: Access message property safely based on actual type
      if (allSuccessful) {
        finalResultStatus = SyncSuccess(message: finalMessage.trim());
      } else {
        finalResultStatus = SyncError(message: finalMessage.trim());
      }

      _syncMessage =
          finalMessage.trim(); // <<< CRUCIAL FIX: Access message safely
      _statusMessage =
          allSuccessful ? "อัปโหลดทั้งหมดสำเร็จ." : "อัปโหลดบางส่วนล้มเหลว.";
    } catch (e) {
      finalResultStatus = SyncError(
          exception: e,
          message: "ข้อผิดพลาดในการอัปโหลด DocumentRecords และรูปภาพ: $e");
      _syncMessage = "อัปโหลด DocumentRecords ล้มเหลว: $e";
      _statusMessage = "อัปโหลด DocumentRecords ล้มเหลว: $e";
      print("Error uploading all document records: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      // อาจจะต้อง refresh jobs ด้วย ถ้าการอัปโหลดมีผลต่อการแสดงผลของ Job
      // หรือเพียงแค่ notifyListeners() เพื่ออัปเดตสถานะ
    }
    return finalResultStatus;
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
      final loginViewModel =
          Provider.of<LoginViewModel>(context, listen: false);
      await loginViewModel
          .logout(context); // <<< CRUCIAL FIX: Pass context here

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

  /// เริ่มกระบวนการ Sync Master Images และอัปเดต Notifiers
  Future<String> syncMasterImages() async {
    // รีเซ็ตสถานะเริ่มต้น
    syncProgressNotifier.value = null; // Indeterminate progress
    syncStatusNotifier.value = 'กำลังตรวจสอบข้อมูลรูปภาพ...';

    final result = await _dataSyncService.performMasterImageSync(
      onProgress: (current, total) {
        if (total > 0) {
          syncProgressNotifier.value = current / total;
          syncStatusNotifier.value =
              'กำลังดาวน์โหลดรูปภาพ $current จาก $total...';
        } else {
          syncStatusNotifier.value = 'ไม่พบรูปภาพใหม่ที่ต้องดาวน์โหลด';
        }
      },
    );

    // สิ้นสุดกระบวนการ
    syncProgressNotifier.value = null;

    if (result is SyncSuccess) {
      return result.message ?? 'การซิงค์สำเร็จ';
    } else if (result is SyncError) {
      return result.message ?? 'เกิดข้อผิดพลาดที่ไม่รู้จัก';
    }
    return 'การซิงค์สิ้นสุดลง';
  }
  // --- <<< สิ้นสุดส่วนที่เพิ่มใหม่ >>> ---
}
