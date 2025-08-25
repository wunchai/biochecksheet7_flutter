// lib/ui/datasummary/data_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/datasummary/data_summary_viewmodel.dart'; // Import ViewModel
//import 'package:biochecksheet7_flutter/data/models/data_summary.dart'; // Import Model
import 'package:biochecksheet7_flutter/presentation/widgets/error_dialog.dart'; // Import ErrorDialog
import 'package:biochecksheet7_flutter/presentation/screens/home/home_viewmodel.dart'; // <<< NEW: Import HomeViewModel
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // <<< NEW: Import SyncStatus (for _showSyncResultFeedback)

/// หน้าจอสำหรับแสดงข้อมูลสรุปสถานะการซิงค์และจำนวนข้อมูล.
/// จะมาแทนที่ Notifications Screen ใน Bottom Navigation Bar.
class DataSummaryScreen extends StatefulWidget {
  final String title;
  const DataSummaryScreen({super.key, required this.title});

  @override
  State<DataSummaryScreen> createState() => _DataSummaryScreenState();
}

class _DataSummaryScreenState extends State<DataSummaryScreen> {
  bool _isShowingDialog = false; // Flag to prevent multiple dialogs/snackbars

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลสรุปเมื่อหน้าจอเริ่มต้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DataSummaryViewModel>(context, listen: false)
            .fetchSummaryData();
      }
    });
  }

  // Helper method เพื่อสร้างแถวสำหรับแสดงรายละเอียด
  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180, // กำหนดความกว้างของ Label เพื่อจัดแนวให้สวยงาม
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child:
                Text(value, style: valueStyle ?? const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
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
              title: '$titlePrefix ข้อผิดพลาด',
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Refresh Summary Data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DataSummaryViewModel>(context, listen: false)
                  .fetchSummaryData();
            },
          ),
          // NEW: Refresh Jobs Button
          IconButton(
            icon: const Icon(Icons.sync), // Sync icon for Jobs
            onPressed: () async {
              final homeViewModel =
                  Provider.of<HomeViewModel>(context, listen: false);
              final SyncStatus syncResult = await homeViewModel
                  .refreshJobs(); // Call refreshJobs from HomeViewModel
              if (mounted) {
                _showSyncResultFeedback(context, syncResult, 'การซิงค์ Job');
                // After refreshing jobs, also refresh summary data to reflect changes
                Provider.of<DataSummaryViewModel>(context, listen: false)
                    .fetchSummaryData();
              }
            },
          ),
          // NEW: Upload All Documents Button
          IconButton(
            icon: const Icon(
                Icons.cloud_upload), // Cloud upload icon for Documents
            onPressed: () async {
              final homeViewModel =
                  Provider.of<HomeViewModel>(context, listen: false);
              final SyncStatus uploadResult = await homeViewModel
                  .uploadAllDocumentRecords(); // Call uploadAllDocumentRecords
              if (mounted) {
                _showSyncResultFeedback(
                    context, uploadResult, 'การอัปโหลดเอกสาร');
                // After uploading documents, also refresh summary data to reflect changes
                Provider.of<DataSummaryViewModel>(context, listen: false)
                    .fetchSummaryData();
              }
            },
          ),
        ],
      ),
      body: Consumer<DataSummaryViewModel>(
        builder: (context, viewModel, child) {
          // Show ErrorDialog for error messages
          if (viewModel.errorMessage != null && !_isShowingDialog) {
            final String currentErrorMessage = viewModel.errorMessage!;
            _isShowingDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                await showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return ErrorDialog(
                      title: 'ข้อผิดพลาดในการโหลดข้อมูลสรุป',
                      message: currentErrorMessage,
                    );
                  },
                );
                viewModel.errorMessage = null; // Clear message after showing
                _isShowingDialog = false; // Reset flag
              }
            });
          }

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final summary = viewModel.summary;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Last Sync Timestamps (Master Data)
                  Text(
                    'สถานะการซิงค์ข้อมูลหลัก (Last Sync):',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow('ผู้ใช้', summary.formattedLastSyncUser),
                  _buildDetailRow('Job', summary.formattedLastSyncJob),
                  _buildDetailRow(
                      'Machine', summary.formattedLastSyncJobMachine),
                  _buildDetailRow('Tag', summary.formattedLastSyncJobTag),
                  _buildDetailRow('ปัญหา', summary.formattedLastSyncProblem),
                  const SizedBox(height: 20),

                  // Section: Pending Document Records Upload
                  Text(
                    'บันทึกเอกสารรออัปโหลด (Status 2, SyncStatus 0):',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow('จำนวนรวม',
                      summary.pendingDocumentRecordsCount.toString()),
                  _buildDetailRow('Last Sync (สำหรับกลุ่มนี้)',
                      summary.formattedLastSyncPendingDocumentRecords),
                  const SizedBox(height: 20),

                  // Section: Pending Image Upload (Divided)
                  Text(
                    'รูปภาพรออัปโหลด:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  // Images from Document Records
                  _buildDetailRow('ของบันทึกเอกสาร (SyncStatus 0)',
                      summary.pendingDocumentImageUploadCount.toString()),
                  _buildDetailRow('Last Sync (บันทึกเอกสาร)',
                      summary.formattedLastSyncPendingDocumentImageUpload),
                  const SizedBox(height: 10), // Small space between image types
                  // Images from Problems
                  _buildDetailRow('ของปัญหา (SyncStatus 0)',
                      summary.pendingProblemImageUploadCount.toString()),
                  _buildDetailRow('Last Sync (ปัญหา)',
                      summary.formattedLastSyncPendingProblemImageUpload),
                  const SizedBox(height: 20),

                  // You can add more summary sections here
                ],
              ),
            );
          }
        },
      ),
      // NEW: Floating Action Button for Device Info
      // NEW: Floating Action Button for Manual Metadata Sync
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Position it to the right
      floatingActionButton: Column(
        // Use Column to stack multiple FABs
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "deviceInfoFab", // Unique tag for multiple FABs
            onPressed: () {
              Navigator.pushNamed(context, '/device_info');
            },
            child: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
