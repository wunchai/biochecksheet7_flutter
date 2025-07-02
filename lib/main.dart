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
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LoginViewModel(
                loginRepository: loginRepository)), // Pass loginRepository
        ChangeNotifierProvider(
            create: (_) => HomeViewModel(appDatabase: db)), // Pass appDatabase
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
      ChangeNotifierProvider(create: (_) => ProblemViewModel(appDatabase: db)), // <<< NEW: Add ProblemViewModel
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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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
          );
        },
        '/problem': (context) => const ProblemScreen(title: 'Problem List'), // <<< NEW: Add ProblemScreen Route
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
