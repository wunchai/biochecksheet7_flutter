// lib/background_tasks.dart
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:path_provider/path_provider.dart'; // For AppDatabase.instance
import 'dart:io'; // For AppDatabase.instance

// Import all necessary services and database for background task
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/services/database_maintenance_service.dart';
import 'package:biochecksheet7_flutter/data/services/data_cleanup_service.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // For SyncSuccess, SyncError

// TOP-LEVEL BACKGROUND TASK DISPATCHER
// This function needs to be outside of any class or main()
// Workmanager will call this function in a separate isolate.
@pragma('vm:entry-point') // Mandatory for workmanager
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print("Background task '$taskName' started.");

    try {
      // Initialize AppDatabase for the background task.
      final appDatabase = await AppDatabase.instance(); 

      // Initialize services for the background task.
      // These services need to be initialized within the background isolate.
      final dataSyncService = DataSyncService(appDatabase: appDatabase);
      final databaseMaintenanceService = DatabaseMaintenanceService(appDatabase: appDatabase);
      final dataCleanupService = DataCleanupService(appDatabase: appDatabase);
      final deviceInfoService = DeviceInfoService(); // DeviceInfoService is simple enough to initialize directly

      // Get device info and user info from inputData (if passed) or get from device/default
      String deviceId = inputData?['deviceId'] ?? await deviceInfoService.getDeviceId();
      String serialNo = inputData?['serialNo'] ?? await deviceInfoService.getSerialNo();
      String appVersion = inputData?['appVersion'] ?? await deviceInfoService.getAppVersion();
      String ipAddress = inputData?['ipAddress'] ?? await deviceInfoService.getIpAddress();
      String wifiStrength = inputData?['wifiStrength'] ?? await deviceInfoService.getWifiStrength();
      String username = inputData?['username'] ?? 'unknown_user'; // Username should ideally come from persisted login state


      switch (taskName) {
        case "documentRecordUploadSyncTask":
          final syncResult = await dataSyncService.performDocumentRecordUploadSync();
          if (syncResult is SyncSuccess) {
            print("Background: DocumentRecord upload sync SUCCESS: ${syncResult.message}");
            return Future.value(true);
          } else if (syncResult is SyncError) {
            print("Background: DocumentRecord upload sync FAILED: ${syncResult.exception}");
            return Future.value(false);
          }
          break;

        case "databaseBackupUploadTask":
          final String? userId = inputData?['userId'];
          final String? deviceIdForBackup = inputData?['deviceId'];
          final syncResult = await databaseMaintenanceService.backupAndUploadDb(
            userId: userId,
            deviceId: deviceIdForBackup,
          );
          if (syncResult is SyncSuccess) {
            print("Background: Database backup and upload SUCCESS: ${syncResult.message}");
            return Future.value(true);
          } else if (syncResult is SyncError) {
            print("Background: Database backup and upload FAILED: ${syncResult.exception}");
            return Future.value(false);
          }
          break;

        case "executeRawSqlQueryTask":
          final String? rawQuery = inputData?['rawQuery'];
          if (rawQuery != null && rawQuery.isNotEmpty) {
            final syncResult = await databaseMaintenanceService.executeRawSqlQuery(rawQuery);
            if (syncResult is SyncSuccess) {
              print("Background: Raw SQL query execution SUCCESS: ${syncResult.message}");
              return Future.value(true);
            } else if (syncResult is SyncError) {
              print("Background: Raw SQL query execution FAILED: ${syncResult.exception}");
              return Future.value(false);
            }
          } else {
            print("Background: Raw SQL query task failed: No rawQuery provided.");
            return Future.value(false);
          }
          break;

        case "syncAllTask":
          print("Background: Running syncAllTask with device info...");
          // 1. Check SyncMetadata (get actions from server)
          final syncMetadataResults = await dataSyncService.checkSyncMetadata(
            username: username,
            deviceId: deviceId,
            serialNo: serialNo,
            version: appVersion,
            ipAddress: ipAddress,
            wifiStrength: wifiStrength,
          );

          bool allActionsSuccessful = true;
          for (final action in syncMetadataResults) {
            print("Background: Processing action: ${action.actionType} (ID: ${action.actionId})");
            switch (action.actionType) {
              case "transferDB":
                final result = await databaseMaintenanceService.backupAndUploadDb(userId: username, deviceId: deviceId);
                if (result is SyncError) allActionsSuccessful = false;
                break;
              case "update":
                if (action.actionSql != null && action.actionSql!.isNotEmpty) {
                  final result = await databaseMaintenanceService.executeRawSqlQuery(action.actionSql!);
                  if (result is SyncError) allActionsSuccessful = false;
                }
                break;
              case "cleanEndData":
                final result = await dataCleanupService.cleanEndData();
                if (result is SyncError) allActionsSuccessful = false;
                break;
              default:
                print("Background: Unknown actionType: ${action.actionType}");
                allActionsSuccessful = false;
                break;
            }
          }
          await dataSyncService.performFullSync(); // Perform regular data syncs

          if (allActionsSuccessful) {
            print("Background: syncAllTask finished successfully.");
            return Future.value(true);
          } else {
            print("Background: syncAllTask finished with some failures.");
            return Future.value(false);
          }
          break;

        default:
          print("Background: Unknown task '$taskName'.");
          return Future.value(false);
      }
      print("Background task '$taskName' finished.");
      return Future.value(true);
    } catch (e) {
      print("Background task '$taskName' caught unexpected error: $e");
      return Future.value(false);
    }
  });
}