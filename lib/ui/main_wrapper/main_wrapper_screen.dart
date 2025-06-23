// lib/ui/main_wrapper/main_wrapper_screen.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/ui/home/home_screen.dart';
import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart';
import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart';

/// This screen acts as a wrapper for the main content screens
/// and provides the Bottom Navigation Bar, similar to how
/// MainActivity with NavHostFragment and BottomNavigationView worked in Kotlin.
class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0; // Current selected tab index.
  late PageController _pageController; // Controller for PageView.

  // List of screens to display in the Bottom Navigation Bar.
  final List<Widget> _screens = [
    const HomeScreen(title: 'Home'),
    const DashboardScreen(title: 'Dashboard'),
    const NotificationsScreen(title: 'Notifications'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Method to handle tab selection.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index); // Jump to the selected page.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar will be managed by individual screens, so no AppBar here.
      // body contains the PageView for switching between screens.
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens, // Display the list of screens.
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
        currentIndex: _selectedIndex, // Highlight the currently selected tab.
        selectedItemColor: Colors.blue[800], // Color for selected icon/label.
        onTap: _onItemTapped, // Callback when a tab is tapped.
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown.
      ),
    );
  }
}