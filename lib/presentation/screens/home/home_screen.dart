// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_viewmodel.dart';
//import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/presentation/screens/document/document_screen.dart'; // <<< Import DocumentScreen
import 'package:biochecksheet7_flutter/presentation/screens/home/widgets/home_app_bar.dart'; // <<< NEW: Import HomeAppBar
//import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_screen.dart'; // <<< NEW: Import DeviceInfoScreen
import 'package:biochecksheet7_flutter/presentation/widgets/error_dialog.dart'; // <<< NEW: Import ErrorDialog
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // Import SyncStatus
import 'package:biochecksheet7_flutter/presentation/widgets/sync_progress_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String title;
  // Constructor for HomeScreen, takes a 'title' string.
  const HomeScreen({super.key, this.title = 'Home'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // No explicit call to refreshJobs() here anymore.
    // The ViewModel initializes its job stream when it's created,
    // so the initial list will load automatically.
  }

  @override
  void dispose() {
    // The ViewModel manages its own controllers' disposal.
    super.dispose();
  }

  // --- <<< ฟังก์ชันใหม่สำหรับจัดการการกดปุ่ม >>> ---
  void _onSyncMasterImagesPressed(
      BuildContext context, HomeViewModel viewModel) async {
    // 1. แสดงหน้าต่าง Progress ทันที
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SyncProgressDialog(
        progressNotifier: viewModel.syncProgressNotifier,
        statusNotifier: viewModel.syncStatusNotifier,
      ),
    );

    // 2. เริ่มกระบวนการ Sync (ซึ่งจะใช้เวลา)
    final String resultMessage = await viewModel.syncMasterImages();

    // 3. เมื่อ Sync เสร็จสิ้น ให้ปิดหน้าต่าง Progress
    if (context.mounted) Navigator.of(context).pop();

    // 4. แสดงผลลัพธ์สุดท้ายด้วย SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultMessage)),
      );
    }
  }

  // Helper method to display sync results (SnackBar or ErrorDialog)
  Future<void> _showSyncResultFeedback(
      BuildContext context, SyncStatus syncResult, String titlePrefix) async {
    final String? message = (syncResult is SyncSuccess)
        ? syncResult.message
        : (syncResult is SyncError ? syncResult.message : null);
    if (message != null) {
      bool isError = message.toLowerCase().contains('ล้มเหลว') ||
          message.toLowerCase().contains('ข้อผิดพลาด') ||
          message.toLowerCase().contains('failed') ||
          message.toLowerCase().contains('error') ||
          message.toLowerCase().contains('exception') ||
          message.toLowerCase().contains('timed out') ||
          message.toLowerCase().contains('ไม่สามารถเชื่อมต่อ');

      if (isError) {
        await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return ErrorDialog(
              title: 'ข้อผิดพลาดในการซิงค์/อัปโหลด',
              message: message,
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100], // New light background
        appBar: HomeAppBar(
          title: widget.title,
          searchController: TextEditingController(),
          onRefreshPressed: () async {
            final viewModel =
                Provider.of<HomeViewModel>(context, listen: false);
            final syncResult = await viewModel.refreshJobs();
            if (!mounted) return;
            _showSyncResultFeedback(context, syncResult, 'การซิงค์ปัญหา');
          },
          onImagePressed: () async {
            _onSyncMasterImagesPressed(
                context, Provider.of<HomeViewModel>(context, listen: false));
          },
          onUploadPressed: () async {
            final viewModel =
                Provider.of<HomeViewModel>(context, listen: false);
            final uploadResult = await viewModel.uploadAllDocumentRecords();
            if (!mounted) return;
            _showSyncResultFeedback(context, uploadResult, 'การซิงค์ปัญหา');
          },
          onLogoutPressed: () {
            Provider.of<HomeViewModel>(context, listen: false).logout(context);
          },
        ),
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, viewModel, child) {
              return Stack(
                children: [
                  Column(
                    children: [
                      // Status Message
                      if (viewModel.statusMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          color: Colors.blue.shade50,
                          child: Text(
                            viewModel.statusMessage,
                            style: TextStyle(
                                fontSize: 13.0, color: Colors.blue.shade900),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Job List
                      Expanded(
                        child: StreamBuilder<List<DbJob>>(
                          stream: viewModel.jobsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !viewModel.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text('Error: ${snapshot.error}'),
                                  ],
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.work_off_outlined,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'ไม่พบรายการงาน (No Jobs)',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              final jobs = snapshot.data!;
                              return ListView.separated(
                                itemCount: jobs.length,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildJobCard(context, jobs[index]);
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (viewModel.isLoading)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                ],
              );
            },
          ),
        ));
  }

  Widget _buildJobCard(BuildContext context, DbJob job) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentScreen(
                title: 'เอกสารของงาน: ${job.jobName ?? ''}',
                jobId: job.jobId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            'ID: ${job.jobId ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(job.jobStatus),
                ],
              ),
              const Divider(height: 24, thickness: 1),
              _buildInfoRow(
                  Icons.precision_manufacturing, 'Machine', job.machineName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Location', job.location),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    Color bgColor;
    Color textColor;
    String text = 'Unknown';
    String statusStr = status?.toString() ?? '';

    if (statusStr == 'Active' || statusStr == '1') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      text = 'Active';
    } else if (statusStr == 'Closed' || statusStr == '2') {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      text = 'Closed';
    } else {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      text = statusStr.isEmpty ? 'Unknown' : statusStr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
