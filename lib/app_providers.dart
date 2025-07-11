// lib/app_providers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart'; // For SingleChildWidget
import 'package:flutter/foundation.dart';

// Import all necessary services, repositories, viewmodels
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/services/database_maintenance_service.dart';
import 'package:biochecksheet7_flutter/data/services/data_cleanup_service.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart';

import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/notifications/notifications_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/document/document_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/documentmachine/document_machine_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/problem/problem_viewmodel.dart';

// CRUCIAL FIX: Conditional Import for ImageProcessor
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_native.dart'; // For Native platforms
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_web.dart'; // For Web platform

// Platform-specific image processor imports
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_native.dart'
    if (dart.library.html) 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_web.dart';

// Import the abstract ImageProcessor class (still needed for type hinting)
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart'; // <<< Make sure this is imported

// NEW: Import DeviceInfo components
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_screen.dart'; // <<< Import Screen

// Import DataSummary components
import 'package:biochecksheet7_flutter/ui/datasummary/data_summary_viewmodel.dart'; // <<< NEW: Import ViewModel
import 'package:biochecksheet7_flutter/ui/datasummary/data_summary_screen.dart'; // <<< NEW: Import Screen

// Define the list of all providers for the application
Future<List<SingleChildWidget>> appProviders(AppDatabase appDatabase) async {
  // Initialize singletons that need to be ready before providers are created
  await LoginRepository.initialize(appDatabase);
  final loginRepository = LoginRepository();
  await loginRepository.getLoggedInUserFromLocal();

  final ImageProcessor
      imageProcessor; // Declare type as abstract ImageProcessor
  if (kIsWeb) {
    // Check if running on web
    imageProcessor =
        ImageProcessorWeb(); // Now ImageProcessorWeb is defined due to conditional import
  } else {
    // Assume native (Android, iOS, Windows, Linux, macOS)
    imageProcessor =
        ImageProcessorNative(); // Now ImageProcessorNative is defined
  }
  // Create DeviceInfoService instance
  final DeviceInfoService deviceInfoService = DeviceInfoService();
  final DataSyncService dataSyncService =
      DataSyncService(appDatabase: appDatabase); // Create instance once

  return [
    // Repositories (provided as value as they are singletons)
    Provider<LoginRepository>.value(value: loginRepository),

    // ViewModels (provided as ChangeNotifierProvider)
    ChangeNotifierProvider(
        create: (_) => LoginViewModel(loginRepository: loginRepository)),
    ChangeNotifierProvider(
        create: (_) => HomeViewModel(
            appDatabase: appDatabase, loginRepository: loginRepository)),
    ChangeNotifierProvider(create: (_) => DashboardViewModel()),
    ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
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
    Provider<DeviceInfoService>(
        create: (context) => DeviceInfoService()), // <<< Change to (context)
    ChangeNotifierProvider(
        create: (context) => DeviceInfoViewModel(
            deviceInfoService:
                Provider.of<DeviceInfoService>(context, listen: false),
            dataSyncService: dataSyncService)),
    Provider<DataSyncService>(
        create: (_) => DataSyncService(appDatabase: appDatabase)),
    Provider<DatabaseMaintenanceService>(
        create: (_) => DatabaseMaintenanceService(appDatabase: appDatabase)),
    Provider<DataCleanupService>(
        create: (_) => DataCleanupService(appDatabase: appDatabase)),
    // NEW: DataSummaryViewModel
    ChangeNotifierProvider(
        create: (_) => DataSummaryViewModel(
            appDatabase: appDatabase)), // <<< NEW: Provide DataSummaryViewModel
  ];
}
