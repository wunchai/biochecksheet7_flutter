// lib/ui/main_wrapper/main_wrapper_screen.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_screen.dart';
//import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart';
//import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/problem_screen.dart'; // <<< NEW: Import ProblemScreen
import 'package:biochecksheet7_flutter/presentation/screens/datasummary/data_summary_screen.dart'; // <<< NEW: Import DataSummaryScreen

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
    const ProblemScreen(
        title: 'Problem List'), // <<< CHANGED: Dashboard to Problem
    const DataSummaryScreen(
        title: 'สรุปข้อมูล'), // <<< CHANGED: Notifications to DataSummaryScreen
  ];

  @override
  void initState() {
    super.initState();
    print('MainWrapperScreen: initState called.'); // Debugging
    _pageController = PageController(initialPage: _selectedIndex);

    // CRUCIAL FIX: Ensure page jump happens AFTER the first frame is rendered.
    // This prevents trying to control a PageView that isn't fully mounted yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
          'MainWrapperScreen: addPostFrameCallback - jumping to initial page.'); // Debugging
      _pageController.jumpToPage(_selectedIndex);
    });
  }

  @override
  void dispose() {
    print('MainWrapperScreen: dispose called.'); // Debugging
    _pageController.dispose();
    super.dispose();
  }

  // Method to handle tab selection.
  // Method to handle tab selection.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // CRUCIAL FIX: Tell the PageController to change the page.
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Smooth animation
      curve: Curves.ease, // Animation curve
    );
    print(
        'MainWrapperScreen: Tab tapped, index: $index - Animating to page.'); // Debugging
  }

  @override
  Widget build(BuildContext context) {
    // print('MainWrapperScreen: build called. Selected index: $_selectedIndex'); // Debugging
    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Match HomeScreen background for seamless look
      extendBody: false, // Fix obstruction: Reserve space for navbar
      body: PageView(
        key: const ValueKey('mainPageView'), // Add a key for stability
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // print('MainWrapperScreen: Page changed, index: $index'); // Debugging
        },
        children: _screens, // Display the list of screens.
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 24,
            top: 12), // Add top margin for spacing from list
        decoration: BoxDecoration(
          color: Colors.blue.shade900, // Dark Blue background
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.3), // Darker shadow for visibility
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            key: const ValueKey('mainBottomNavBar'), // Add a key for stability
            elevation: 0,
            backgroundColor: Colors.transparent,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warning_amber_rounded),
                activeIcon: Icon(Icons.warning_rounded),
                label: 'Problem',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.summarize_outlined),
                activeIcon: Icon(Icons.summarize_rounded),
                label: 'Summary',
              ),
            ],
            currentIndex:
                _selectedIndex, // Highlight the currently selected tab.
            selectedItemColor: Colors.white, // White for selected
            unselectedItemColor: Colors.white60, // White60 for unselected
            showUnselectedLabels: true,
            type:
                BottomNavigationBarType.fixed, // Ensures all labels are shown.
            onTap: _onItemTapped, // Callback when a tab is tapped.
          ),
        ),
      ),
    );
  }
}
