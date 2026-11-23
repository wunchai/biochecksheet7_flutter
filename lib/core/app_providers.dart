// lib/app_providers.dart
//import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart'; // For SingleChildWidget

// Import all necessary services, repositories, viewmodels
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/services/database_maintenance_service.dart';
import 'package:biochecksheet7_flutter/data/services/data_cleanup_service.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart';
import 'package:biochecksheet7_flutter/data/services/foreground_sync_service.dart';

import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/dashboard/dashboard_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/notifications/notifications_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document/document_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentmachine/document_machine_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/document_record_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/imagerecord/image_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/problem_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/document_image_online_api_service.dart'; // <<< NEW
import 'package:biochecksheet7_flutter/data/repositories/document_online_repository.dart';

import 'package:biochecksheet7_flutter/data/repositories/document_record_online_repository.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_machine_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/am_checksheet_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_record_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_image_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/repositories/draft_job_repository.dart';
import 'package:biochecksheet7_flutter/presentation/screens/draft_job/draft_job_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/network/draft_api_service.dart';

// CRUCIAL FIX: Conditional Import for ImageProcessor
import 'package:biochecksheet7_flutter/presentation/screens/imagerecord/image_processor.dart';
import 'package:biochecksheet7_flutter/presentation/screens/imagerecord/image_processor_native.dart'
    if (dart.library.html) 'package:biochecksheet7_flutter/presentation/screens/imagerecord/image_processor_web.dart';

// NEW: Import DeviceInfo components
import 'package:biochecksheet7_flutter/presentation/screens/deviceinfo/device_info_viewmodel.dart';

// Import DataSummary components
import 'package:biochecksheet7_flutter/presentation/screens/datasummary/data_summary_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/am_summary/am_summary_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/checksheet_audit/checksheet_audit_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/network/mt_request_api_service.dart';
import 'package:biochecksheet7_flutter/presentation/screens/mt_request/mt_request_viewmodel.dart';

// --- <<< เพิ่ม Import สำหรับ Image Sync >>> ---
import 'package:biochecksheet7_flutter/data/network/checksheet_image_api_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/checksheet_image_repository.dart';

// Define the list of all providers for the application
Future<List<SingleChildWidget>> appProviders(AppDatabase appDatabase) async {
  // Initialize singletons that need to be ready before providers are created
  await LoginRepository.initialize(appDatabase);
  final loginRepository = LoginRepository();
  await loginRepository.getLoggedInUserFromLocal();

  // Use the factory function from the conditionally imported file
  final ImageProcessor imageProcessor = getPlatformImageProcessor();

  // Remove unused local variable if created inside Provider
  // final DeviceInfoService deviceInfoService = DeviceInfoService();

  // --- <<< สร้าง Dependencies สำหรับ Image Sync >>> ---
  final checksheetImageApiService = ChecksheetImageApiService();
  final checksheetImageRepository = ChecksheetImageRepository(
    appDatabase: appDatabase,
    apiService: checksheetImageApiService,
  );

  final dataSyncService = DataSyncService(
    appDatabase: appDatabase,
    // --- <<< ส่ง Repository ของรูปภาพเข้าไปใน DataSyncService >>> ---
    checksheetImageRepository: checksheetImageRepository,
  );

  final documentOnlineRepository = DocumentOnlineRepository(appDatabase: appDatabase);

  final documentOnlineApiService = DocumentOnlineApiService();
  final documentRecordOnlineRepository = DocumentRecordOnlineRepository(appDatabase.documentRecordOnlineDao, documentOnlineApiService);

  final draftApiService = DraftApiService();
  final draftJobRepository = DraftJobRepository(appDatabase.draftJobDao, draftApiService);

  final documentImageOnlineApiService = DocumentImageOnlineApiService(); // <<< NEW
  final mtRequestApiService = MtRequestApiService();
  final deviceInfoService = DeviceInfoService();
  final databaseMaintenanceService =
      DatabaseMaintenanceService(appDatabase: appDatabase);
  final dataCleanupService = DataCleanupService(appDatabase: appDatabase);

  return [
    // Repositories (provided as value as they are singletons)
    Provider<AppDatabase>.value(value: appDatabase),
    Provider<LoginRepository>.value(value: loginRepository),

    // ViewModels (provided as ChangeNotifierProvider)
    ChangeNotifierProvider(
        create: (_) => LoginViewModel(loginRepository: loginRepository)),
    ChangeNotifierProvider(
        create: (_) => HomeViewModel(
            appDatabase: appDatabase, loginRepository: loginRepository)),
    ChangeNotifierProvider(create: (_) => DashboardViewModel()),
    ChangeNotifierProvider(
        create: (_) => NotificationsViewModel(
              apiService: documentOnlineApiService,
              loginRepository: loginRepository,
              dao: appDatabase.notificationDao,
            )),
    ChangeNotifierProvider(
        create: (_) => DocumentViewModel(appDatabase: appDatabase)),
    ChangeNotifierProvider(
        create: (_) => DocumentMachineViewModel(appDatabase: appDatabase)),
    ChangeNotifierProvider(
        create: (_) => DocumentRecordViewModel(appDatabase: appDatabase)),
    ChangeNotifierProvider(
        create: (_) => ImageViewModel(
            appDatabase: appDatabase, imageProcessor: imageProcessor)),
    ChangeNotifierProvider(
        create: (_) => ProblemViewModel(appDatabase: appDatabase)),

    // CRUCIAL FIX: Provide DeviceInfoService as a regular Provider
    Provider<DeviceInfoService>.value(value: deviceInfoService),
    ChangeNotifierProvider(
        create: (context) => DeviceInfoViewModel(
            deviceInfoService: deviceInfoService,
            dataSyncService: dataSyncService,
            loginRepository: loginRepository)), // <<< NEW
    Provider.value(value: dataSyncService), // Use existing instance
    Provider.value(value: documentOnlineApiService), // NEW: Provide DocumentOnlineApiService

    Provider<DatabaseMaintenanceService>.value(
        value: databaseMaintenanceService),
    Provider<DataCleanupService>.value(value: dataCleanupService),
    Provider<ForegroundSyncService>.value(
      value: ForegroundSyncService(
        dataSyncService: dataSyncService,
        databaseMaintenanceService: databaseMaintenanceService,
        dataCleanupService: dataCleanupService,
        deviceInfoService: deviceInfoService,
        loginRepository: loginRepository,
        appDatabase: appDatabase,
      )..start(interval: const Duration(minutes: 5)),
    ),
    // NEW: DataSummaryViewModel
    ChangeNotifierProvider(
        create: (_) => DataSummaryViewModel(
            appDatabase: appDatabase)), // <<< NEW: Provide DataSummaryViewModel
    ChangeNotifierProvider(
        create: (_) => AMChecksheetViewModel(appDatabase: appDatabase)),
    ChangeNotifierProvider(
        create: (_) => DocumentOnlineViewModel(repository: documentOnlineRepository)),

    // Online Read-only ViewModels
    ChangeNotifierProvider(
        create: (_) => DocumentMachineOnlineViewModel(repository: documentRecordOnlineRepository)),
    ChangeNotifierProvider(
        create: (_) => AMChecksheetOnlineViewModel(repository: documentRecordOnlineRepository)),
    ChangeNotifierProvider(
        create: (_) => DocumentRecordOnlineViewModel(repository: documentRecordOnlineRepository)),
    ChangeNotifierProvider(
        create: (_) => DocumentImageOnlineViewModel(appDatabase: appDatabase, apiService: documentImageOnlineApiService)), // <<< NEW

    // Custom Job Draft ViewModel
    ChangeNotifierProvider(
        create: (_) => DraftJobViewModel(repository: draftJobRepository)),

    // AM Management Summary Dashboard ViewModel
    ChangeNotifierProvider(
        create: (_) => AmSummaryViewModel(documentOnlineApiService)),

    // CheckSheet Audit ViewModel
    ChangeNotifierProvider(
        create: (_) => ChecksheetAuditViewModel(documentOnlineApiService)),

    // MT Request ViewModel (CHECKSHEET_MT_REQUEST)
    Provider<MtRequestApiService>.value(value: mtRequestApiService),
    ChangeNotifierProvider(
        create: (_) => MtRequestViewModel(
              apiService: mtRequestApiService,
              appDatabase: appDatabase,
              loginRepository: loginRepository,
            )),
  ];
}
