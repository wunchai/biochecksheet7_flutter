// lib/ui/deviceinfo/device_info_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart'; // Import DeviceInfoService
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart'; // <<< NEW: Import DataSyncService
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import API Response Models
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // <<< NEW: Import SyncStatus

class DeviceInfoViewModel extends ChangeNotifier {
  final DeviceInfoService _deviceInfoService;
  final DataSyncService _dataSyncService; // <<< NEW: Add DataSyncService dependency

  String _deviceId = 'กำลังโหลด...';
  String get deviceId => _deviceId;

  String _serialNo = 'กำลังโหลด...';
  String get serialNo => _serialNo;

  String _appVersion = 'กำลังโหลด...';
  String get appVersion => _appVersion;

  String _ipAddress = 'กำลังโหลด...';
  String get ipAddress => _ipAddress;

  String _wifiStrength = 'กำลังโหลด...';
  String get wifiStrength => _wifiStrength;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _statusMessage = "กำลังโหลดข้อมูล..."; // Default initial message
  String get statusMessage => _statusMessage;
  
   String? _syncMessage; // For displaying sync messages
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

 
  DeviceInfoViewModel({required DeviceInfoService deviceInfoService, required DataSyncService dataSyncService}) // <<< NEW: Receive DataSyncService
      : _deviceInfoService = deviceInfoService,
        _dataSyncService = dataSyncService; // <<< NEW: Initialize DataSyncService
       
  /// Fetches all device information.
  Future<void> fetchDeviceInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _deviceId = await _deviceInfoService.getDeviceId();
      _serialNo = await _deviceInfoService.getSerialNo();
      _appVersion = await _deviceInfoService.getAppVersion();
      _ipAddress = await _deviceInfoService.getIpAddress();
      _wifiStrength = await _deviceInfoService.getWifiStrength();
    } catch (e) {
      _errorMessage = 'ข้อผิดพลาดในการโหลดข้อมูลอุปกรณ์: $e';
      print('Error fetching device info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

   /// NEW: Performs manual metadata sync and processes server actions.
  Future<void> performManualMetadataSync() async {
    _isLoading = true;
    _syncMessage = null;
    _errorMessage = null; // Clear previous error
    notifyListeners();

    try {
      // 1. Get current device info (ensure it's up-to-date)
      await fetchDeviceInfo(); // Refresh device info before sending

      // 2. Call checkSyncMetadata API
      final List<SyncMetadataResponse> syncMetadataResults = await _dataSyncService.checkSyncMetadata(
        username: 'admin', // TODO: Replace with actual logged-in username
        deviceId: _deviceId,
        serialNo: _serialNo,
        version: _appVersion,
        ipAddress: _ipAddress,
        wifiStrength: _wifiStrength,
      );
        
   
      // 3. Process actions from server response
      bool allActionsSuccessful = true;
      for (final action in syncMetadataResults) {
      
        print("DeviceInfoViewModel: Processing action: ${action.actionType} (ID: ${action.actionId})");
        switch (action.actionType) {
          case "transferDB":
            final result = await _dataSyncService.databaseMaintenanceService.backupAndUploadDb(userId: 'admin', deviceId: _deviceId); // TODO: Replace userId
            if (result is SyncError) allActionsSuccessful = false;
            break;
          case "update":
            if (action.actionSql != null && action.actionSql!.isNotEmpty) {
              final result = await _dataSyncService.databaseMaintenanceService.executeRawSqlQuery(action.actionSql!);
              if (result is SyncError) allActionsSuccessful = false;
            }
            break;
          case "cleanEndData":
            final result = await _dataSyncService.dataCleanupService.cleanEndData();
            if (result is SyncError) allActionsSuccessful = false;
            break;
          default:
            print("DeviceInfoViewModel: Unknown actionType: ${action.actionType}");
            allActionsSuccessful = false;
            break;
        }
      }
      // After processing actions, perform regular data syncs (download new master data)
     // await _dataSyncService.performFullSync(); // Or specific syncs

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
}