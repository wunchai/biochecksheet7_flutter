// lib/ui/datasummary/data_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/datasummary/data_summary_viewmodel.dart'; // Import ViewModel
import 'package:biochecksheet7_flutter/data/models/data_summary.dart'; // Import Model
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
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DataSummaryViewModel>(context, listen: false)
            .fetchSummaryData();
      }
    });
  }

  Future<void> _handleRefresh() async {
    await Provider.of<DataSummaryViewModel>(context, listen: false)
        .fetchSummaryData();
  }

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
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _triggerUpload(BuildContext context) async {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    // Show loading indicator or simple feedback that it started?
    // For now, relying on the await and result feedback
    final SyncStatus uploadResult =
        await homeViewModel.uploadAllDocumentRecords();
    if (mounted) {
      _showSyncResultFeedback(context, uploadResult, 'การอัปโหลดเอกสาร');
      Provider.of<DataSummaryViewModel>(context, listen: false)
          .fetchSummaryData();
    }
  }

  Future<void> _triggerSyncJobs(BuildContext context) async {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final SyncStatus syncResult = await homeViewModel.refreshJobs();
    if (mounted) {
      _showSyncResultFeedback(context, syncResult, 'การซิงค์ Job');
      Provider.of<DataSummaryViewModel>(context, listen: false)
          .fetchSummaryData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for dashboard feel
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<DataSummaryViewModel>(context, listen: false)
                    .fetchSummaryData(),
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: Consumer<DataSummaryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.errorMessage != null && !_isShowingDialog) {
            final String currentErrorMessage = viewModel.errorMessage!;
            _isShowingDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                await showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    title: 'ข้อผิดพลาด',
                    message: currentErrorMessage,
                  ),
                );
                viewModel.errorMessage = null;
                _isShowingDialog = false;
              }
            });
          }

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = viewModel.summary;
          final int totalPending = summary.pendingDocumentRecordsCount +
              summary.pendingDocumentImageUploadCount +
              summary.pendingProblemImageUploadCount;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPendingActionCard(totalPending, context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'สถานะข้อมูลในระบบ (Sync Status)',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                      ),
                      TextButton.icon(
                        onPressed: () => _triggerSyncJobs(context),
                        icon: const Icon(Icons.sync, size: 18),
                        label: const Text('อัปเดตข้อมูลหลัก'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMasterDataGrid(summary),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/device_info');
        },
        icon: const Icon(Icons.perm_device_information),
        label: const Text('ข้อมูลอุปกรณ์'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Widget _buildPendingActionCard(int totalPending, BuildContext context) {
    bool hasPending = totalPending > 0;
    Color cardColor = hasPending ? Colors.orange.shade50 : Colors.green.shade50;
    Color iconColor = hasPending ? Colors.orange : Colors.green;
    Color textColor =
        hasPending ? Colors.orange.shade900 : Colors.green.shade900;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              Colors.white,
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      hasPending ? Icons.cloud_upload : Icons.cloud_done,
                      color: iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPending ? 'รอการอัปโหลด' : 'ข้อมูลเป็นปัจจุบัน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasPending)
                          Text(
                            'มีข้อมูลเอกสารและรูปภาพจำนวน $totalPending รายการ ที่ยังไม่ได้ส่งขึ้นระบบ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          )
                        else
                          Text(
                            'ไม่มีข้อมูลค้างในเครื่อง ข้อมูลทั้งหมดถูกส่งขึ้นระบบแล้ว',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasPending) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerUpload(context),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('อัปโหลดข้อมูลเดี๋ยวนี้'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterDataGrid(DataSummary summary) {
    final items = [
      _MasterDataItem('ผู้ใช้งาน', Icons.person, summary.formattedLastSyncUser,
          Colors.blue),
      _MasterDataItem('งาน (Job)', Icons.assignment,
          summary.formattedLastSyncJob, Colors.indigo),
      _MasterDataItem('เครื่องจักร', Icons.precision_manufacturing,
          summary.formattedLastSyncJobMachine, Colors.teal),
      _MasterDataItem('Tags / จุดตรวจ', Icons.qr_code,
          summary.formattedLastSyncJobTag, Colors.purple),
      _MasterDataItem('ปัญหา (Problem)', Icons.warning,
          summary.formattedLastSyncProblem, Colors.red),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple responsive grid logic
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4, // Adjusted for card shape
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildMasterDataCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildMasterDataCard(_MasterDataItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const Spacer(),
                // Could add a small 'check' icon if synced recently, but for now just simple
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'ล่าสุด: ${item.lastSync}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterDataItem {
  final String title;
  final IconData icon;
  final String lastSync;
  final Color color;

  _MasterDataItem(this.title, this.icon, this.lastSync, this.color);
}
