// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart'; // <<< NEW: Import path_provider
import 'dart:io'; // For File class, if needed for direct file operations

// Import all table definitions (should be present from previous steps)
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart'; // Import DataSyncService
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/login/login_screen.dart';
import 'package:biochecksheet7_flutter/ui/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/home/home_screen.dart';

// TODO: You will need to create these screens later
import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart'; // <<< Import Screen

// Import Notifications components
import 'package:biochecksheet7_flutter/ui/notifications/notifications_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart'; // <<< Import Screen

// Import Document components
import 'package:biochecksheet7_flutter/ui/document/document_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/document/document_screen.dart'; // <<< Import Screen

// Import DocumentMachine components
import 'package:biochecksheet7_flutter/ui/documentmachine/document_machine_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/documentmachine/document_machine_screen.dart'; // <<< Import Screen

// Import DocumentRecord components
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_screen.dart'; // Already imported, just for context

// CRUCIAL FIX: Conditional Import for ImageProcessor
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_native.dart'; // For Native platforms
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_web.dart'; // For Web platform

import 'package:biochecksheet7_flutter/ui/imagerecord/image_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_record_screen.dart';

// NEW: Import Problem components
import 'package:biochecksheet7_flutter/ui/problem/problem_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/problem/problem_screen.dart'; // <<< Import Screen

// Import MainWrapperScreen
import 'package:biochecksheet7_flutter/ui/main_wrapper/main_wrapper_screen.dart'; // <<< Import MainWrapperScreen
import 'package:biochecksheet7_flutter/data/services/database_maintenance_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; 

// Platform-specific image processor imports
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_native.dart'
    if (dart.library.html) 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_web.dart';


// lib/main.dart
  // CRUCIAL FIX: Add imports needed by the background isolate here


import 'package:biochecksheet7_flutter/data/services/device_info_service.dart'; // <<< NEW: Import DeviceInfoService
import 'package:biochecksheet7_flutter/data/services/data_cleanup_service.dart'; // <<< NEW: Import DataCleanupService
import 'package:workmanager/workmanager.dart';

// NEW: Import DeviceInfo components
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_viewmodel.dart'; // <<< Import ViewModel
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_screen.dart'; // <<< Import Screen


import 'dart:async';
import 'package:workmanager/workmanager.dart';

// TOP-LEVEL BACKGROUND TASK DISPATCHER
// This function needs to be outside of any class or main()
// Workmanager will call this function in a separate isolate.
@pragma('vm:entry-point') // Mandatory for workmanager
void callbackDispatcher() {



  Workmanager().executeTask((taskName, inputData) async {
    print("Background task '$taskName' started."); // Debugging

    try {
      // Initialize AppDatabase for the background task.
      // It must be initialized within the background isolate.
      final db = await AppDatabase.instance();
      // Initialize DataSyncService for the background task.
      // It needs access to DAOs and Repositories via appDatabase.
      final dataSyncService = DataSyncService(appDatabase: db);
      
      // NEW: Initialize DatabaseMaintenanceService for background task
      final databaseMaintenanceService = DatabaseMaintenanceService(appDatabase: db);
      final dataCleanupService = DataCleanupService(appDatabase: db); // <<< NEW: Initialize DataCleanupService
      final deviceInfoService = DeviceInfoService(); // <<< NEW: Initialize DeviceInfoService

     
      // Get device info for sync metadata
      // Use inputData if passed, otherwise get from device
      String deviceId = inputData?['deviceId'] ?? await deviceInfoService.getDeviceId();
      String serialNo = inputData?['serialNo'] ?? await deviceInfoService.getSerialNo();
      String appVersion = inputData?['appVersion'] ?? await deviceInfoService.getAppVersion();
      String ipAddress = inputData?['ipAddress'] ?? await deviceInfoService.getIpAddress();
      String wifiStrength = inputData?['wifiStrength'] ?? await deviceInfoService.getWifiStrength();
      String username = inputData?['username'] ?? 'unknown_user'; // Username should ideally come from inputData or persisted login state


      // Perform the specific sync/maintenance operation based on taskName.
      switch (taskName) {

         case "syncAllTask":
          final syncResult = await dataSyncService.performDocumentRecordUploadSync();
          if (syncResult is SyncSuccess) {
            print("Background: DocumentRecord upload sync SUCCESS: ${syncResult.message}");
            return Future.value(true); // Task successful
          } else if (syncResult is SyncError) {
            print("Background: DocumentRecord upload sync FAILED: ${syncResult.exception}");
            return Future.value(false); // Task failed
          }
          break; // Don't fall through

        case "documentRecordUploadSyncTask":
          final syncResult = await dataSyncService.performDocumentRecordUploadSync();
          if (syncResult is SyncSuccess) {
            print("Background: DocumentRecord upload sync SUCCESS: ${syncResult.message}");
            return Future.value(true); // Task successful
          } else if (syncResult is SyncError) {
            print("Background: DocumentRecord upload sync FAILED: ${syncResult.exception}");
            return Future.value(false); // Task failed
          }
          break; // Don't fall through

        case "databaseBackupUploadTask":
          // InputData could contain userId, deviceId
          final String? userId = inputData?['userId'];
          final String? deviceId = inputData?['deviceId'];
          final syncResult = await databaseMaintenanceService.backupAndUploadDb(
            userId: userId,
            deviceId: deviceId,
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
         case "syncAllTask": // <<< NEW: Case for syncAllTask
          print("Background: Running syncAllTask...");
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
          // After processing actions, perform regular data syncs (download new master data)
          await dataSyncService.performFullSync(); // Or specific syncs like _syncProblemsData, _syncUsersData etc.

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
          return Future.value(false); // Indicate failure for unknown task
      }
      print("Background task '$taskName' finished.");
      return Future.value(true); // Default success if no explicit return in case
    } catch (e) {
      print("Background task '$taskName' caught unexpected error: $e");
      return Future.value(false); // Indicate failure
    }
  });
}


// NEW: Define custom MaterialColor function
// This function creates a MaterialColor from a single base Color.
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[
    .05,
    0.1,
    0.2,
    0.3,
    0.4,
    0.5,
    0.6,
    0.7,
    0.8,
    0.9
  ];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(color.alpha * strength).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, <int, Color>{
    50: color.withOpacity(0.1),
    100: color.withOpacity(0.2),
    200: color.withOpacity(0.3),
    300: color.withOpacity(0.4),
    400: color
        .withOpacity(0.5), // This is often the default shade for primaryColor
    500: color.withOpacity(0.6),
    600: color.withOpacity(0.7),
    700: color.withOpacity(0.8),
    800: color.withOpacity(0.9),
    900: color.withOpacity(1.0),
  });
}

// Define your specific theme colors
const Color _primaryThemeBlue =
    Color(0xFF3F51B5); // Indigo (from Material Design palette)
const Color _accentThemeAmber =
    Color(0xFFFFC107); // Amber (from Material Design palette)
const Color _scaffoldBackgroundLightGrey =
    Color(0xFFF5F5F5); // Light Grey (Material Grey 100)
const Color _darkText =
    Color(0xFF212121); // Dark grey for text (Material Grey 900)
const Color _lightText = Colors.white; // White for text on dark backgrounds

Future<void> main1() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NEW: Print database path for debugging
  if (!kIsWeb) {
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = File('${dbFolder.path}/db.sqlite'); // Assuming 'biochecksheet.sqlite'
        print('Database path (db.sqlite): ${dbPath.path}');
        print('Database directory: ${dbFolder.path}');
      } catch (e) {
        print('Error getting database path: $e');
      }

      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

       // NEW: Register syncAllTask
      await Workmanager().registerPeriodicTask(
        "syncAllTask", // Unique name
        "syncAllTask", // Task name
        frequency: const Duration(minutes: 1), // Every 5 minutes
        initialDelay: const Duration(seconds: 30), // Start after 30 seconds
        constraints:  Constraints(
          networkType: NetworkType.connected,
        ),
      );


/*
      // Example 2: One-off task for database backup (you can trigger this from a UI button)
      await Workmanager().registerOneOffTask( // <<< NEW: Register one-off task
        "databaseBackupUploadTask",
        "databaseBackupUploadTask",
        inputData: {"userId": "current_user_id", "deviceId": "some_device_id"}, // Example input data
        constraints:  Constraints(networkType: NetworkType.connected),
        tag: "backup_db_tag", // Optional: Tag for grouping/cancelling tasks
      );

      // Example 3: One-off task for executing raw SQL (VERY DANGEROUS - use with extreme caution)
      await Workmanager().registerOneOffTask( // <<< NEW: Register one-off task
        "executeRawSqlQueryTask",
        "executeRawSqlQueryTask",
        inputData: {"rawQuery": "UPDATE users SET status = 0 WHERE userId = 'test';"}, // Example raw query
        constraints:  Constraints(networkType: NetworkType.connected),
        tag: "raw_sql_tag",
      );
      */
    }
  // Initialize AppDatabase instance first, await it.
  final db = await AppDatabase.instance();

  // Initialize LoginRepository now that AppDatabase is ready.
  await LoginRepository.initialize(db);
  // Check initial login status
  final loginRepository = LoginRepository(); // Get the singleton instance
  await loginRepository.getLoggedInUserFromLocal();
  // CRUCIAL FIX: Create platform-specific ImageProcessor directly using the imported concrete class.

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


    // Create DeviceInfoService here
 // CRUCIAL FIX: Create DeviceInfoService as a Provider
    // This ensures it's available in the widget tree for DeviceInfoViewModel
    // and also allows it to be passed to DataSyncService in the background.
    final DeviceInfoService deviceInfoService = DeviceInfoService(); // Create instance once
  final DataSyncService dataSyncService = DataSyncService(appDatabase: db); // Create instance once


  final DatabaseMaintenanceService databaseMaintenanceService =
      DatabaseMaintenanceService(appDatabase: db); // <<< NEW
  runApp(
    MultiProvider(
      providers: [
          Provider<LoginRepository>.value(value: loginRepository),
          ChangeNotifierProvider(create: (_) => LoginViewModel(loginRepository: loginRepository)),
          ChangeNotifierProvider(create: (_) => HomeViewModel(appDatabase: db, loginRepository: loginRepository)),
          ChangeNotifierProvider(create: (_) => DashboardViewModel()),
          ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
          ChangeNotifierProvider(create: (_) => DocumentViewModel(appDatabase: db)),
          ChangeNotifierProvider(create: (_) => DocumentMachineViewModel(appDatabase: db)),
          ChangeNotifierProvider(create: (_) => DocumentRecordViewModel(appDatabase: db)),
          ChangeNotifierProvider(create: (_) => ImageViewModel(appDatabase: db, imageProcessor: imageProcessor)),
          ChangeNotifierProvider(create: (_) => ProblemViewModel(appDatabase: db)),
               // CRUCIAL FIX: Provide DeviceInfoService as a regular Provider
          Provider<DeviceInfoService>(create: (context) => DeviceInfoService()), // <<< Change to (context)
          ChangeNotifierProvider(create: (context) => DeviceInfoViewModel(deviceInfoService: Provider.of<DeviceInfoService>(context, listen: false), dataSyncService: dataSyncService)), // <<< Change to (context) ChangeNotifierProvider(create: (_) => DeviceInfoViewModel(deviceInfoService: Provider.of<DeviceInfoService>(context, listen: false))), // <<< Get DeviceInfoService from Provider
          Provider<DataSyncService>(create: (_) => DataSyncService(appDatabase: db)),
          Provider<DatabaseMaintenanceService>(create: (_) => DatabaseMaintenanceService(appDatabase: db)),
          Provider<DataCleanupService>(create: (_) => DataCleanupService(appDatabase: db)),
      ],
      child: MyApp(
        initialRoute: loginRepository.isLoggedIn
            ? '/main_wrapper'
            : '/login', // <<< เปลี่ยน initialRoute
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioCheckSheet7',
      theme: ThemeData(
        // Primary Color Palette
        primarySwatch: createMaterialColor(_primaryThemeBlue),
        primaryColor: _primaryThemeBlue,

        // Accent Color (used by FloatingActionButton, etc.)
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: createMaterialColor(_primaryThemeBlue),
          accentColor: _accentThemeAmber, // Use accent color from your palette
          backgroundColor: _scaffoldBackgroundLightGrey,
          // You can define more colors here if needed, like surface, error, etc.
        ).copyWith(
            secondary:
                _accentThemeAmber), // Ensure accentColor is set as secondary

        // Scaffold Background Color
        scaffoldBackgroundColor: _scaffoldBackgroundLightGrey,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryThemeBlue, // Solid primary blue for AppBar
          foregroundColor: _lightText, // White text/icons on AppBar
        ),

        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _primaryThemeBlue, // Primary blue for filled buttons
            foregroundColor: _lightText, // White text on filled buttons
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)), // Rounded corners
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        // OutlinedButton Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor:
                _primaryThemeBlue, // Primary blue text for outlined buttons
            side: const BorderSide(
                color: _primaryThemeBlue), // Primary blue border
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor:
                _primaryThemeBlue, // Primary blue text for text buttons
          ),
        ),

        // TextField/Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(8.0)), // Rounded corners for inputs
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(
                color: _primaryThemeBlue,
                width: 2.0), // Primary blue border when focused
          ),
          labelStyle: const TextStyle(color: _darkText), // Color of label text
          hintStyle: TextStyle(
              color: _darkText.withOpacity(0.6)), // Color of hint text
          errorStyle: const TextStyle(color: Colors.red), // Color of error text
        ),

        // Typography (for general text styles)
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: _darkText),
          displayMedium: TextStyle(color: _darkText),
          displaySmall: TextStyle(color: _darkText),
          headlineLarge: TextStyle(color: _darkText),
          headlineMedium: TextStyle(color: _darkText),
          headlineSmall: TextStyle(color: _darkText),
          titleLarge: TextStyle(color: _darkText),
          titleMedium: TextStyle(color: _darkText),
          titleSmall: TextStyle(color: _darkText),
          bodyLarge: TextStyle(color: _darkText),
          bodyMedium: TextStyle(color: _darkText),
          bodySmall: TextStyle(color: _darkText),
          labelLarge: TextStyle(color: _darkText),
          labelMedium: TextStyle(color: _darkText),
          labelSmall: TextStyle(color: _darkText),
        ),

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      /*
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      */
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main_wrapper': (context) =>
            const MainWrapperScreen(), // <<< เพิ่ม Route สำหรับ MainWrapperScreen
        '/home': (context) => const HomeScreen(title: 'Home Screen'),
        '/dashboard': (context) =>
            const PlaceholderScreen(title: 'Dashboard Screen'),
        '/notifications': (context) =>
            const PlaceholderScreen(title: 'Notifications Screen'),
        '/document': (context) => const DocumentScreen(
            title: 'Document Screen'), // <<< Add Document Screen Route
        '/document_machine': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return DocumentMachineScreen(
            title: args?['title'] ?? 'Machines',
            jobId: args?['jobId'] ?? '',
            documentId: args?['documentId'] ?? '',
          );
        },
        '/document_record': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return DocumentRecordScreen(
            title: args?['title'] ?? 'Document Record',
            documentId: args?['documentId'] ?? '',
            machineId: args?['machineId'] ?? '',
            jobId: args?['jobId'] ?? '',
          );
        },
        // NEW: Add route for ImageRecordScreen
        '/image_record': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ImageRecordScreen(
            title: args?['title'] ?? 'Image Records',
            documentId: args?['documentId'] ?? '',
            machineId: args?['machineId'] ?? '',
            jobId: args?['jobId'] ?? '',
            tagId: args?['tagId'] ?? '',
            problemId: args?['problemId']?.toString() ??
                '', // <<< CRUCIAL FIX: Ensure it's String and not null
            isReadOnly:
                args?['isReadOnly'] ?? false, // <<< NEW: Receive isReadOnly
          );
        },
        '/problem': (context) => const ProblemScreen(
            title: 'Problem List'), // <<< NEW: Add ProblemScreen Route
        '/device_info': (context) => const DeviceInfoScreen(title: 'ข้อมูลอุปกรณ์'), // <<< NEW: Add DeviceInfoScreen Route
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('Welcome to $title!',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
