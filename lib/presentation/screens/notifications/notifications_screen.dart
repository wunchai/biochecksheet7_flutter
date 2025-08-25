// lib/ui/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/notifications/notifications_viewmodel.dart';

/// Equivalent to NotificationsFragment.kt
class NotificationsScreen extends StatefulWidget {
  final String title;
  const NotificationsScreen({super.key, required this.title});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsViewModel>(context, listen: false)
          .refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NotificationsViewModel>(context, listen: false)
                  .refreshNotifications();
            },
          ),
        ],
      ),
      body: Consumer<NotificationsViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      viewModel.text,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (viewModel.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              // Loading overlay
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
