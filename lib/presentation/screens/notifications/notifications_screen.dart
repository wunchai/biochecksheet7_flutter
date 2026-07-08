import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/notifications/notifications_viewmodel.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
    // Mark all as read when opening this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsViewModel>(context, listen: false).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: () {
              Provider.of<NotificationsViewModel>(context, listen: false).clearAll();
            },
          ),
        ],
      ),
      body: Consumer<NotificationsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีการแจ้งเตือน',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: viewModel.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = viewModel.notifications[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (item.payloadData != null && item.payloadData!.isNotEmpty) {
                      try {
                        final payload = jsonDecode(item.payloadData!);
                        fcmService.handleNotificationClick(payload);
                      } catch (e) {
                        debugPrint('Error parsing notification payload: $e');
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(item.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(item.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ), // Close InkWell
              ); // Close Card
            },
          );
        },
      ),
    );
  }
}
