// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


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


// Import MainWrapperScreen
import 'package:biochecksheet7_flutter/ui/main_wrapper/main_wrapper_screen.dart'; // <<< Import MainWrapperScreen


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppDatabase instance first, await it.
  final db = await AppDatabase.instance();

  // Initialize LoginRepository now that AppDatabase is ready.
  await LoginRepository.initialize(db);

  // Check initial login status
  final loginRepository = LoginRepository(); // Get the singleton instance
  await loginRepository.getLoggedInUserFromLocal();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LoginViewModel(
                loginRepository: loginRepository)), // Pass loginRepository
        ChangeNotifierProvider(
            create: (_) => HomeViewModel(appDatabase: db)), // Pass appDatabase
        ChangeNotifierProvider(create: (_) => DashboardViewModel()), // <<< Add DashboardViewModel
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()), // <<< Add NotificationsViewModel
         ChangeNotifierProvider(create: (_) => DocumentViewModel(appDatabase: db)), // <<< Add DocumentViewModel
      ],
      child: MyApp(
        initialRoute: loginRepository.isLoggedIn ? '/main_wrapper' : '/login', // <<< เปลี่ยน initialRoute
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
         '/main_wrapper': (context) => const MainWrapperScreen(), // <<< เพิ่ม Route สำหรับ MainWrapperScreen
        '/home': (context) => const HomeScreen(title: 'Home Screen'),
        '/dashboard': (context) =>
            const PlaceholderScreen(title: 'Dashboard Screen'),
        '/notifications': (context) =>
            const PlaceholderScreen(title: 'Notifications Screen'),
        '/document': (context) => const DocumentScreen(title: 'Document Screen'), // <<< Add Document Screen Route
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
