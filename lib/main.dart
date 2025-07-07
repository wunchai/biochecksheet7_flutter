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
// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// ... (imports อื่นๆ) ...
// NEW: Top-level function for background tasks
@pragma('vm:entry-point') // Mandatory for workmanager
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print("Native/Web: Background task '$taskName' started."); // Debugging

    try {
      // Initialize AppDatabase for the background task.
      final appDatabase =
          await AppDatabase.instance; // Needs AppDatabase to be a static getter

      // Initialize DataSyncService for the background task.
      final dataSyncService = DataSyncService(appDatabase: appDatabase);

      // Perform the specific sync operation based on taskName.
      if (taskName == "documentRecordUploadSyncTask") {
        final syncResult =
            await dataSyncService.performDocumentRecordUploadSync();
        if (syncResult is SyncSuccess) {
          print(
              "Native/Web: DocumentRecord upload sync SUCCESS: ${syncResult.message}");
          return Future.value(true); // Task successful
        } else if (syncResult is SyncError) {
          print(
              "Native/Web: DocumentRecord upload sync FAILED: ${syncResult.exception}");
          return Future.value(false); // Task failed
        }
      }
      // TODO: Add other background tasks here (e.g., database backup/restore)
      // For example, if taskName == "databaseBackupTask":
      //   final dbBackupService = DatabaseMaintenanceService(appDatabase: appDatabase);
      //   final backupResult = await dbBackupService.backupAndUploadDb();
      //   return Future.value(backupResult);

      print("Native/Web: Background task '$taskName' finished. Unknown task.");
      return Future.value(false); // Indicate failure for unknown task
    } catch (e) {
      print("Native/Web: Background task '$taskName' caught error: $e");
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NEW: Print database path for debugging
  try {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = File('${dbFolder.path}/db.sqlite'); // Assuming 'db.sqlite'
    print(
        'Database path (db.sqlite): ${dbPath.path}'); // <<< CRUCIAL: Print path
    print('Database directory: ${dbFolder.path}'); // <<< Print directory
  } catch (e) {
    print('Error getting database path: $e');
  }

// NEW: Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher, // The top-level function to run in background
    isInDebugMode: kDebugMode, // Set to true in debug mode for easier testing
  );

  // NEW: Register and schedule the task (e.g., a periodic task)
  await Workmanager().registerPeriodicTask(
    "documentRecordUploadSyncTask", // Unique name for your task
    "documentRecordUploadSyncTask", // Task name (must match in executeTask)
    frequency: const Duration(hours: 4), // Run every 4 hours
    initialDelay: const Duration(minutes: 1), // Start after 1 minute
    constraints: Constraints(
      // Optional: Add constraints
      networkType: NetworkType.connected, // Only run when connected to network
    ),
    // You can also use registerOneOffTask for one-time tasks.
  );

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

  final DatabaseMaintenanceService databaseMaintenanceService =
      DatabaseMaintenanceService(appDatabase: db); // <<< NEW
  runApp(
    MultiProvider(
      providers: [
        // Provide LoginRepository as a value, as it's a pre-initialized singleton.
        Provider<LoginRepository>.value(
            value: loginRepository), // <<< NEW: Provide LoginRepository
        ChangeNotifierProvider(
            create: (_) => LoginViewModel(loginRepository: loginRepository)),
        // Inject LoginRepository into HomeViewModel
        ChangeNotifierProvider(
            create: (_) => HomeViewModel(
                appDatabase: db,
                loginRepository:
                    loginRepository)), // <<< CRUCIAL FIX: Pass loginRepository

        ChangeNotifierProvider(
            create: (_) => DashboardViewModel()), // <<< Add DashboardViewModel
        ChangeNotifierProvider(
            create: (_) =>
                NotificationsViewModel()), // <<< Add NotificationsViewModel
        ChangeNotifierProvider(
            create: (_) => DocumentViewModel(
                appDatabase: db)), // <<< Add DocumentViewModel
        ChangeNotifierProvider(
            create: (_) => DocumentMachineViewModel(
                appDatabase: db)), // <<< Add DocumentMachineViewModel
        ChangeNotifierProvider(
            create: (_) => DocumentRecordViewModel(
                appDatabase: db)), // <<< Add DocumentRecordViewModel
        // CRUCIAL FIX: Inject the imageProcessor into ImageViewModel
        ChangeNotifierProvider(
            create: (_) => ImageViewModel(
                appDatabase: db,
                imageProcessor: imageProcessor)), // <<< Pass imageProcessor
        ChangeNotifierProvider(
            create: (_) => ProblemViewModel(
                appDatabase: db)), // <<< NEW: Add ProblemViewModel
        ChangeNotifierProvider(
            create: (_) => DataSyncService(
                appDatabase: db,
                databaseMaintenanceService:
                    databaseMaintenanceService)), // <<< Inject
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
