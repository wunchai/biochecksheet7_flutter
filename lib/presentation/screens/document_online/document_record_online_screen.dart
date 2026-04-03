// lib/presentation/screens/document_online/document_record_online_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_record_online_viewmodel.dart';

class DocumentRecordOnlineScreen extends StatelessWidget {
  final String title;
  final String documentId;
  final String machineId;

  const DocumentRecordOnlineScreen({
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
      body: Consumer<DocumentRecordOnlineViewModel>(
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
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.tagName ?? 'Unknown Tag',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          if (record.description != null && record.description!.isNotEmpty)
                            Text(
                              record.description!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          const Divider(),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('ค่าที่บันทึก: ${record.value ?? "-"}',
                                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                              if (record.unReadable == 'true')
                                const Text('อ่านค่าไม่ได้', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              if (record.remark != null && record.remark!.isNotEmpty)
                                Text('หมายเหตุ: ${record.remark}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ],
                      ),
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
