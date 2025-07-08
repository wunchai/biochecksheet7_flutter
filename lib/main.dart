// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import new modular files
import 'package:biochecksheet7_flutter/app_config.dart'; // For colors
import 'package:biochecksheet7_flutter/app_theme.dart'; // For appTheme()
import 'package:biochecksheet7_flutter/app_routes.dart'; // For appRoutes()
import 'package:biochecksheet7_flutter/app_providers.dart'; // For appProviders()
import 'package:biochecksheet7_flutter/background_tasks.dart'; // For callbackDispatcher

// Import AppDatabase (still needed directly for initialization)
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

// Import LoginRepository (still needed directly for initialization)
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';

// Import Workmanager (still needed directly for initialization)
import 'package:workmanager/workmanager.dart';

// Import path_provider and dart:io for conditional use in main
import 'package:path_provider/path_provider.dart';
import 'dart:io';


Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

 
    // CRUCIAL FIX: Only initialize Workmanager and related tasks on Android/iOS.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) { // <<< CRUCIAL FIX: Add Platform.isAndroid || Platform.isIOS
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = File('${dbFolder.path}/db.sqlite');
        print('Database path (db.sqlite): ${dbPath.path}');
        print('Database directory: ${dbFolder.path}');
      } catch (e) {
        print('Error getting database path: $e');
      }

      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

/*
      // Register and schedule background tasks
      await Workmanager().registerPeriodicTask(
        "documentRecordUploadSyncTask",
        "documentRecordUploadSyncTask",
        frequency: const Duration(hours: 4),
        initialDelay: const Duration(minutes: 1),
        constraints:  Constraints(
          networkType: NetworkType.connected,
        ),
      );

      await Workmanager().registerOneOffTask(
        "databaseBackupUploadTask",
        "databaseBackupUploadTask",
        inputData: {"userId": "current_user_id", "deviceId": "some_device_id"},
        constraints:  Constraints(networkType: NetworkType.connected),
        tag: "backup_db_tag",
      );

      await Workmanager().registerOneOffTask(
        "executeRawSqlQueryTask",
        "executeRawSqlQueryTask",
        inputData: {"rawQuery": "UPDATE users SET status = 0 WHERE userId = 'test';"},
        constraints:  Constraints(networkType: NetworkType.connected),
        tag: "raw_sql_tag",
      );
*/
      await Workmanager().registerPeriodicTask(
        "syncAllTask",
        "syncAllTask",
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(seconds: 30),
        constraints:  Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }

    // Initialize AppDatabase (singleton)
    final appDatabase = await AppDatabase.instance(); 

    // Initialize LoginRepository (singleton) after AppDatabase is ready
    await LoginRepository.initialize(appDatabase);
    final loginRepository = LoginRepository();
    await loginRepository.getLoggedInUserFromLocal(); 

    // Get the list of providers
    final providers = await appProviders(appDatabase); // Pass appDatabase to appProviders

    runApp(
      MultiProvider(
        providers: providers, // Use the list of providers
        child: MyApp(
          initialRoute: loginRepository.isLoggedIn ? '/main_wrapper' : '/login',
        ),
      ),
    );
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      print('Unhandled error caught by runZonedGuarded: $error');
      print('Stack trace: $stack');
    }
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter error caught by FlutterError.onError: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };
}


class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioCheckSheet7',
      theme: appTheme(), // Use the appTheme() function
      initialRoute: initialRoute,
      routes: appRoutes(), // Use the appRoutes() function
    );
  }
}

// PlaceholderScreen can remain here or be moved if it's generic
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('Welcome to $title!', style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}