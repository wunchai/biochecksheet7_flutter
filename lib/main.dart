// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/login/login_screen.dart';
import 'package:biochecksheet7_flutter/ui/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/home/home_screen.dart';

// TODO: You will need to create these screens later
//import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart';
//import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart';
// import 'package:biochecksheet7_flutter/ui/sync/sync_screen.dart'; // This path is placeholder

Future<void> main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize your database (ensure it's done once and available globally)
  AppDatabase.instance; // Accessing the singleton instance to ensure it's initialized

  // Check initial login status
  final loginRepository = LoginRepository();
  await loginRepository.getLoggedInUserFromLocal(); // Pre-load user if available

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        Provider<LoginRepository>(create: (_) => LoginRepository()),
      ],
      child: MyApp(
        initialRoute: loginRepository.isLoggedIn ? '/home' : '/login', // Set initial route based on login status
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute; // Accept initial route from main

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioCheckSheet7',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: initialRoute, // Use the dynamically determined initial route
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(title: 'Home Screen'),
        '/dashboard': (context) => const PlaceholderScreen(title: 'Dashboard Screen'),
        '/notifications': (context) => const PlaceholderScreen(title: 'Notifications Screen'),
        // '/sync': (context) => const PlaceholderScreen(title: 'Sync Screen'), // Removed if not using now
        // Define other routes as needed
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
        child: Text('Welcome to $title!', style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}