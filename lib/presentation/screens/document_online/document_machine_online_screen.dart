// lib/presentation/screens/document_online/document_machine_online_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_machine_online_viewmodel.dart';

class DocumentMachineOnlineScreen extends StatefulWidget {
  final String title;
  final String documentId;
  final String jobId;
  final String userId;
  final String? lot;

  const DocumentMachineOnlineScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.jobId,
    required this.userId,
    this.lot,
  });

  @override
  State<DocumentMachineOnlineScreen> createState() => _DocumentMachineOnlineScreenState();
}

class _DocumentMachineOnlineScreenState extends State<DocumentMachineOnlineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<DocumentMachineOnlineViewModel>(context, listen: false);
      vm.fetchOnlineRecords(widget.userId, widget.jobId, widget.documentId);
      // Fetch machine summary
      vm.fetchMachineSummary(widget.userId, widget.jobId, widget.documentId);
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
                                subtitle: Builder(
                                  builder: (context) {
                                    final summary = viewModel.summaryMachines.firstWhere(
                                      (s) => s.machineId.toString() == machine.machineId,
                                      orElse: () => MachineSummaryOnline(),
                                    );

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          machine.uiType == 1 ? 'AM Checksheet (Online)' : 'Record (Online)',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        if (summary.documentId != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _buildStatusBadge('ผิดปกติ', summary.abnormalCount ?? 0, Colors.red),
                                              _buildStatusBadge('ปัญหา', summary.problemCount ?? 0, Colors.orange),
                                              _buildStatusBadge('เปิด Case', summary.caseOpened ?? 0, Colors.purple),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.assignment_ind, size: 14, color: (summary.supervisorChecked ?? 0) > 0 ? Colors.green : Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ตรวจสอบ: ${summary.supervisorCheckCount ?? 0} ครั้ง',
                                                style: TextStyle(fontSize: 12, color: (summary.supervisorChecked ?? 0) > 0 ? Colors.green[700] : Colors.grey[600]),
                                              ),
                                              if (summary.lastSupervisorCheckDate != null && summary.lastSupervisorCheckDate!.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  'ล่าสุด: ${summary.lastSupervisorCheckDate!.split('T').first}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ]
                                      ],
                                    );
                                  }
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
                                      'jobId': widget.jobId,
                                      'lot': widget.lot,
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

  Widget _buildStatusBadge(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
