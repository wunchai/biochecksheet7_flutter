// lib/presentation/screens/document_online/am_checksheet_online_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/am_checksheet_online_viewmodel.dart';
import 'package:collection/collection.dart'; // For grouping

class AMChecksheetOnlineScreen extends StatelessWidget {
  final String title;
  final String documentId;
  final String machineId;

  const AMChecksheetOnlineScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<AMChecksheetOnlineViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<List<DbDocumentRecordOnline>>(
            stream: viewModel.getRecordsForMachine(documentId, machineId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('ไม่พบรายการสำหรับเครื่องนี้'));
              }

              final records = snapshot.data!;
              
              // Group records by tagGroupId/tagGroupName
              final groupedRecords = groupBy(records, (DbDocumentRecordOnline r) => r.tagGroupName ?? 'อื่นๆ');

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: groupedRecords.keys.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = groupedRecords.keys.elementAt(groupIndex);
                  final groupItems = groupedRecords[groupName]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[100],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: Text(
                            groupName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        // Group Items
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: groupItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, itemIndex) {
                            final item = groupItems[itemIndex];
                            
                            // Determine style based on value
                            Color valueColor = Colors.black87;
                            if (item.value == 'ปกติ' || item.value == 'ผ่าน' || item.value == 'Pass') {
                              valueColor = Colors.green[700]!;
                            } else if (item.value != null && item.value!.contains('ผิดปกติ') || item.value == 'ไม่ผ่าน') {
                              valueColor = Colors.red[700]!;
                            }

                            return Container(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Leading number or icon
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      '${itemIndex + 1}',
                                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Tag Name and Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.tagName ?? 'Unknown Tag',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              item.description!,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Value
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: valueColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: valueColor.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          item.value?.isNotEmpty == true ? item.value! : '-',
                                          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (item.unReadable == 'true')
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Text('อ่านไม่ได้', style: TextStyle(color: Colors.red, fontSize: 10)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
