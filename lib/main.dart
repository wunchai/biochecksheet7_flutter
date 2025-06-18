// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your database
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart'; // Import your LoginViewModel
import 'package:biochecksheet7_flutter/ui/login/login_screen.dart'; // Import your LoginScreen

// TODO: You will need to create these screens later
//import 'package:biochecksheet7_flutter/ui/home/home_screen.dart'; // Placeholder for your home screen
//import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart'; // Placeholder for dashboard
//import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart'; // Placeholder for notifications
//import 'package:biochecksheet7_flutter/ui/sync/sync_screen.dart'; // Placeholder for sync

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your database (ensure it's done once and available globally)
  // We already set up AppDatabase as a singleton, so just accessing it initializes.
  // AppDatabase.instance; // This line might be enough to trigger initialization if designed that way,
                        // or you might have a specific init() method for the database.
  // If your AppDatabase has an async init, use await here:
  // await AppDatabase.instance.initializeDatabase(); // Example if you have an async init

  runApp(
    // MultiProvider is used to provide multiple ViewModels/providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        // TODO: Add other ViewModels here as you create them
        // ChangeNotifierProvider(create: (_) => HomeViewModel()),
        // ChangeNotifierProvider(create: (_) => DashboardViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioCheckSheet7',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login', // Set initial route to login screen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const PlaceholderScreen(title: 'Home Screen'), // Placeholder until you create HomeScreen
        '/dashboard': (context) => const PlaceholderScreen(title: 'Dashboard Screen'), // Placeholder
        '/notifications': (context) => const PlaceholderScreen(title: 'Notifications Screen'), // Placeholder
        '/sync': (context) => const PlaceholderScreen(title: 'Sync Screen'), // Placeholder
        // Define other routes as needed
      },
    );
  }
}

// A simple placeholder screen for demonstration
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