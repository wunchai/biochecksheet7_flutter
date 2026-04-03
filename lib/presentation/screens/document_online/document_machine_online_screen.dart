// lib/presentation/screens/document_online/document_machine_online_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_machine_online_viewmodel.dart';

class DocumentMachineOnlineScreen extends StatefulWidget {
  final String title;
  final String documentId;
  final String jobId;
  final String userId;

  const DocumentMachineOnlineScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.jobId,
    required this.userId,
  });

  @override
  State<DocumentMachineOnlineScreen> createState() => _DocumentMachineOnlineScreenState();
}

class _DocumentMachineOnlineScreenState extends State<DocumentMachineOnlineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentMachineOnlineViewModel>(context, listen: false)
          .fetchOnlineRecords(widget.userId, widget.jobId, widget.documentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Consumer<DocumentMachineOnlineViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "โหมดดูข้อมูลย้อนหลัง (Read-only)",
                    style: TextStyle(fontSize: 14.0, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<DbDocumentRecordOnline>>(
                    stream: viewModel.getMachinesForDocument(widget.documentId),
                    builder: (context, snapshot) {
                      if (viewModel.isLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('กำลังดึงข้อมูลรายละเอียดเอกสาร...'),
                            ],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('ไม่พบเครื่องจักรสำหรับเอกสารนี้'));
                      } else {
                        final machines = snapshot.data!;
                        return ListView.builder(
                          itemCount: machines.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          itemBuilder: (context, index) {
                            final machine = machines[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(
                                  machine.uiType == 1 ? Icons.architecture : Icons.precision_manufacturing,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                                title: Text(
                                  'รหัสเครื่องจักร: ${machine.machineId ?? "Unknown"} ${machine.description != null ? '(${machine.description})' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  machine.uiType == 1 ? 'AM Checksheet (Online)' : 'Record (Online)',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  String routeName = '/document_record_online';
                                  String detailTitle = 'Record: ${machine.machineId}';
                                  
                                  if (machine.uiType == 1) {
                                    routeName = '/am_checksheet_online';
                                    detailTitle = 'AM Check: ${machine.machineId}';
                                  }

                                  Navigator.pushNamed(
                                    context,
                                    routeName,
                                    arguments: {
                                      'title': detailTitle,
                                      'documentId': widget.documentId,
                                      'machineId': machine.machineId,
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
