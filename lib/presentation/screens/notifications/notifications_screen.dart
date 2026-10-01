import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/notifications/notifications_viewmodel.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final String title;
  const NotificationsScreen({super.key, required this.title});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // We don't mark all as read automatically on enter anymore, 
    // so the user can clearly see which ones are unread.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.done_all),
            tooltip: 'อ่านทั้งหมด',
            onPressed: () {
              Provider.of<NotificationsViewModel>(context, listen: false).markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              Provider.of<NotificationsViewModel>(context, listen: false).fetchNotifications(forceRefresh: true);
            },
          ),
        ],
      ),
      body: Consumer<NotificationsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter logic
          final filteredList = viewModel.notifications.where((item) {
            bool matchesSearch = true;
            if (_searchController.text.isNotEmpty) {
              matchesSearch = item.title.toLowerCase().contains(_searchController.text.toLowerCase());
            }
            
            bool matchesDate = true;
            if (_selectedDate != null) {
              final d = item.timestamp;
              matchesDate = d.year == _selectedDate!.year && 
                            d.month == _selectedDate!.month && 
                            d.day == _selectedDate!.day;
            }
            
            return matchesSearch && matchesDate;
          }).toList();

          return Column(
            children: [
              // Search & Filter Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}), // Rebuild on type
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่อเอกสาร...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedDate != null ? Colors.blue.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedDate != null ? Colors.blue : Colors.grey.shade400,
                          )
                        ),
                        child: Icon(
                          Icons.calendar_month, 
                          color: _selectedDate != null ? Colors.blue.shade800 : Colors.black87,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                      )
                  ],
                ),
              ),

              // List View
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              viewModel.notifications.isEmpty ? 'ไม่มีการแจ้งเตือน' : 'ไม่พบข้อมูลที่ค้นหา',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            if (viewModel.isLoading) ...[
                              const SizedBox(height: 16),
                              const CircularProgressIndicator(),
                            ]
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final sendDate = item.timestamp;
                              
                              final title = item.title;
                              final body = item.body;
                  final isSuccess = body.contains('สำเร็จ');

                  return Card(
                    elevation: item.isRead ? 0 : 2,
                    color: item.isRead ? Colors.white : Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: item.isRead 
                          ? (isSuccess ? Colors.green.shade200 : Colors.red.shade200)
                          : Colors.blue.shade300, width: item.isRead ? 1 : 1.5),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Mark as read
                        viewModel.markAsRead(item.id);

                        // Decode payload back to map
                        if (item.payloadData != null) {
                          try {
                            final Map<String, dynamic> payload = jsonDecode(item.payloadData!);
                            fcmService.handleNotificationClick(payload);
                          } catch (e) {
                            print('Error decoding notification payload: $e');
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
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSuccess ? Icons.check_circle : Icons.error,
                                        size: 16,
                                        color: isSuccess ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                            color: item.isRead ? Colors.black87 : Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(sendDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 14,
                                color: item.isRead ? Colors.grey[700] : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(sendDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (viewModel.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  },
      ),
    );
  }
}
