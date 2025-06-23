// lib/ui/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_viewmodel.dart';

/// Equivalent to DashboardFragment.kt in the original Kotlin project.
/// This screen displays a dashboard with various items, fetched and managed by DashboardViewModel.
class DashboardScreen extends StatefulWidget {
  final String title; // Title for the app bar.
  const DashboardScreen({super.key, required this.title});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule a callback for after the first frame is rendered.
    // This ensures the ViewModel's data loading is triggered only after the widget is fully initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access the DashboardViewModel and trigger a data refresh.
      // listen: false because we are only calling a method, not listening for rebuilds here.
      Provider.of<DashboardViewModel>(context, listen: false).refreshDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Display the screen title from widget property.
        actions: [
          // Refresh button in the AppBar.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a data refresh when the refresh button is pressed.
              Provider.of<DashboardViewModel>(context, listen: false).refreshDashboard();
            },
          ),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        // Consumer widget listens to changes in DashboardViewModel and rebuilds its builder.
        builder: (context, viewModel, child) {
          return Stack(
            // Stack allows placing widgets on top of each other, used here for the loading overlay.
            children: [
              Column(
                // Main column to arrange UI elements vertically.
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Padding around the message text.
                    child: Text(
                      viewModel.message, // Display a message or status from the ViewModel.
                      style: Theme.of(context).textTheme.headlineSmall, // Apply a heading style.
                      textAlign: TextAlign.center, // Center-align the text.
                    ),
                  ),
                  Expanded(
                    // Expanded widget ensures the ListView takes up the remaining vertical space.
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator()) // Show loading spinner if data is loading.
                        : ListView.builder(
                            itemCount: viewModel.dashboardItems.length, // Number of items in the list.
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Padding for the entire list.
                            itemBuilder: (context, index) {
                              final item = viewModel.dashboardItems[index]; // Get the current dashboard item.
                              // Each item is displayed as a Card, conceptually similar to dashboard_fragment_item.xml.
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0), // Vertical margin between cards.
                                elevation: 4.0, // Adds a shadow effect to the card.
                                child: InkWell(
                                  // InkWell provides a visual ripple effect when the card is tapped.
                                  onTap: () {
                                    // TODO: Implement navigation or action for when a dashboard item is tapped.
                                    print('Dashboard Item Tapped: ${item.content}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0), // Internal padding of the card content.
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left).
                                      children: [
                                        Text(
                                          item.content, // Display the main content of the item.
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Bold title.
                                        ),
                                        const SizedBox(height: 4.0), // Small vertical space.
                                        Text(
                                          item.details, // Display additional details of the item.
                                          style: Theme.of(context).textTheme.bodySmall, // Smaller text style for details.
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Loading overlay that appears on top of the content when isLoading is true.
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5), // Semi-transparent black background.
                  alignment: Alignment.center, // Centers the loading spinner.
                  child: const CircularProgressIndicator(), // The actual loading spinner.
                ),
            ],
          );
        },
      ),
    );
  }
}
