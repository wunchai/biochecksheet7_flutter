// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart'; // Import DataSyncService
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/login/login_screen.dart';
import 'package:biochecksheet7_flutter/ui/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/home/home_screen.dart';

// TODO: You will need to create these screens later
//import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart';
//import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart';

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
        // LoginRepository is already initialized as a singleton, no need to provide it explicitly here
        // as long as you access it via LoginRepository() factory.
      ],
      child: MyApp(
        initialRoute: loginRepository.isLoggedIn ? '/home' : '/login',
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
        '/home': (context) => const HomeScreen(title: 'Home Screen'),
        '/dashboard': (context) =>
            const PlaceholderScreen(title: 'Dashboard Screen'),
        '/notifications': (context) =>
            const PlaceholderScreen(title: 'Notifications Screen'),
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
