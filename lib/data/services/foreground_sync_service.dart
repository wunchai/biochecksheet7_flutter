// lib/data/services/foreground_sync_service.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/services/data_cleanup_service.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/services/database_maintenance_service.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart';
import 'package:biochecksheet7_flutter/data/services/fcm_service.dart';

/// Service for handling silent automatic synchronization while the app is in the foreground.
/// Runs periodically (default every 5 minutes) and also on app resume without freezing the UI.
class ForegroundSyncService with WidgetsBindingObserver {
  final DataSyncService _dataSyncService;
  final DatabaseMaintenanceService _databaseMaintenanceService;
  final DataCleanupService _dataCleanupService;
  final DeviceInfoService _deviceInfoService;
  final LoginRepository _loginRepository;
  final AppDatabase _appDatabase;

  Timer? _timer;
  bool _isSyncing = false;
  Duration _interval = const Duration(minutes: 5);

  ForegroundSyncService({
    required DataSyncService dataSyncService,
    required DatabaseMaintenanceService databaseMaintenanceService,
    required DataCleanupService dataCleanupService,
    required DeviceInfoService deviceInfoService,
    required LoginRepository loginRepository,
    required AppDatabase appDatabase,
  })  : _dataSyncService = dataSyncService,
        _databaseMaintenanceService = databaseMaintenanceService,
        _dataCleanupService = dataCleanupService,
        _deviceInfoService = deviceInfoService,
        _loginRepository = loginRepository,
        _appDatabase = appDatabase;

  /// Start foreground sync timer and observe app lifecycle.
  void start({Duration interval = const Duration(minutes: 5)}) {
    _interval = interval;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);

    debugPrint(
      '[ForegroundSync] Started with interval: ${_interval.inMinutes} mins',
    );
    _timer = Timer.periodic(_interval, (_) => syncNow());
  }

  /// Stop foreground sync timer and remove observer.
  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[ForegroundSync] Stopped');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[ForegroundSync] App resumed, triggering immediate sync...');
      syncNow();
    }
  }

  Future<String> _resolveActiveUsername() async {
    final loggedInUserId = _loginRepository.loggedInUser?.userId;
    if (loggedInUserId != null && loggedInUserId.isNotEmpty) {
      return loggedInUserId;
    }
    try {
      final users = await _appDatabase.userDao.getAllUsers();
      for (final u in users) {
        if (u.isLocalSessionActive && u.userId != null && u.userId!.isNotEmpty) {
          return u.userId!;
        }
      }
    } catch (e) {
      debugPrint('[ForegroundSync] Error getting active user: $e');
    }
    return 'unknown_user';
  }

  /// Perform silent sync for server commands and pending client transactions.
  Future<void> syncNow() async {
    if (_isSyncing) {
      debugPrint('[ForegroundSync] Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;
    debugPrint('[ForegroundSync] Auto-sync running...');

    try {
      final deviceId = await _deviceInfoService.getDeviceId();
      final serialNo = await _deviceInfoService.getSerialNo();
      final appVersion = await _deviceInfoService.getAppVersion();
      final ipAddress = await _deviceInfoService.getIpAddress();
      final wifiStrength = await _deviceInfoService.getWifiStrength();
      final username = await _resolveActiveUsername();

      String? fcmToken;
      try {
        fcmToken = await fcmService.getDeviceToken();
      } catch (_) {
        fcmToken = null;
      }

      // 1. Check SyncMetadata (get server commands & maintenance actions)
      final syncMetadataResults = await _dataSyncService.checkSyncMetadata(
        username: username,
        deviceId: deviceId,
        serialNo: serialNo,
        version: appVersion,
        ipAddress: ipAddress,
        wifiStrength: wifiStrength,
        fcmToken: fcmToken,
      );

      bool allActionsSuccessful = true;
      for (final action in syncMetadataResults) {
        debugPrint(
          '[ForegroundSync] Processing action: ${action.actionType} (ID: ${action.actionId})',
        );
        switch (action.actionType) {
          case 'transferDB':
            final result = await _databaseMaintenanceService.backupAndUploadDb(
              userId: username,
              deviceId: deviceId,
            );
            if (result is SyncError) allActionsSuccessful = false;
            break;
          case 'update':
            if (action.actionSql != null && action.actionSql!.isNotEmpty) {
              final result = await _databaseMaintenanceService
                  .executeRawSqlQuery(action.actionSql!);
              if (result is SyncError) allActionsSuccessful = false;
            }
            break;
          case 'cleanEndData':
            final result = await _dataCleanupService.cleanEndData();
            if (result is SyncError) allActionsSuccessful = false;
            break;
          default:
            debugPrint(
              '[ForegroundSync] Unknown actionType: ${action.actionType}',
            );
            allActionsSuccessful = false;
            break;
        }
      }

      // 2. Upload pending client transactions (DocumentRecords, Problems, Images)
      debugPrint('[ForegroundSync] Uploading DocumentRecords...');
      final docUploadResult =
          await _dataSyncService.performDocumentRecordUploadSync();
      if (docUploadResult is SyncError) allActionsSuccessful = false;

      debugPrint('[ForegroundSync] Uploading Problems...');
      final problemUploadResult =
          await _dataSyncService.performProblemUploadSync();
      if (problemUploadResult is SyncError) allActionsSuccessful = false;

      debugPrint('[ForegroundSync] Uploading Images...');
      final imageUploadResult =
          await _dataSyncService.performImageUploadSync();
      if (imageUploadResult is SyncError) allActionsSuccessful = false;

      debugPrint(
        '[ForegroundSync] Auto-sync completed: ${allActionsSuccessful ? "SUCCESS" : "FAILURES"}',
      );
    } catch (e) {
      debugPrint('[ForegroundSync] Unexpected error during auto-sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    stop();
  }
}
