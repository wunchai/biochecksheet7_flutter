// lib/ui/datasummary/data_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/datasummary/data_summary_viewmodel.dart'; // Import ViewModel
import 'package:biochecksheet7_flutter/presentation/screens/deviceinfo/device_info_viewmodel.dart';
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
        Provider.of<DeviceInfoViewModel>(context, listen: false)
            .fetchDeviceInfo(silent: true);
      }
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      Provider.of<DataSummaryViewModel>(context, listen: false)
          .fetchSummaryData(),
      Provider.of<DeviceInfoViewModel>(context, listen: false)
          .fetchDeviceInfo(silent: true),
    ]);
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
            onPressed: _handleRefresh,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: Consumer2<DataSummaryViewModel, DeviceInfoViewModel>(
        builder: (context, viewModel, deviceViewModel, child) {
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
          } else if (deviceViewModel.syncMessage != null && !_isShowingDialog) {
            final String currentSyncMessage = deviceViewModel.syncMessage!;
            _isShowingDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                final lower = currentSyncMessage.toLowerCase();
                final bool isError = lower.contains('ล้มเหลว') ||
                    lower.contains('ข้อผิดพลาด') ||
                    lower.contains('ไม่สำเร็จ') ||
                    lower.contains('failed') ||
                    lower.contains('error') ||
                    lower.contains('exception') ||
                    lower.contains('timed out') ||
                    lower.contains('ไม่สามารถเชื่อมต่อ');

                if (isError) {
                  await showDialog(
                    context: context,
                    builder: (context) => ErrorDialog(
                      title: 'ข้อผิดพลาดในการซิงค์ข้อมูลอุปกรณ์',
                      message: currentSyncMessage,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(currentSyncMessage),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                deviceViewModel.syncMessage = null;
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
              summary.pendingProblemImageUploadCount +
              summary.pendingProblemsCount;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPendingActionCard(totalPending, context),
                  const SizedBox(height: 12),
                  _buildCustomJobsSummary(summary, context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'สถานะข้อมูลในระบบ (Sync Status)',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _triggerSyncJobs(context),
                        icon: const Icon(Icons.sync, size: 18),
                        label: const Text('อัปเดตข้อมูลหลัก'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMasterDataGrid(summary),
                  const SizedBox(height: 28),
                  _buildDeviceInfoSection(context, deviceViewModel),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
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
                            'มีข้อมูลเอกสาร ปัญหา และรูปภาพจำนวน $totalPending รายการ ที่ยังไม่ได้ส่งขึ้นระบบ',
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

  Widget _buildCustomJobsSummary(DataSummary summary, BuildContext context) {
    if (summary.pendingDraftJobsCount == 0 && summary.submittedDraftJobsCount == 0) {
      return const SizedBox.shrink(); // ซ่อนถ้าไม่มีเลย หรืออาจจะโชว์ว่า "ไม่มี Custom Job" แทนก็ได้
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_document, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom Jobs / งานที่สร้างเอง',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountItem(summary.pendingDraftJobsCount.toString(), 'รออัปโหลด (Draft)', Colors.orange),
                Container(width: 1, height: 40, color: Colors.blue.shade200),
                _buildCountItem(summary.submittedDraftJobsCount.toString(), 'อัปโหลดแล้ว', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        )
      ],
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

  Widget _buildDeviceInfoSection(
      BuildContext context, DeviceInfoViewModel deviceViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'ข้อมูลอุปกรณ์ (Device Info)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: deviceViewModel.isLoading
                  ? null
                  : () => deviceViewModel.performManualMetadataSync(),
              icon: deviceViewModel.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: const Text('ซิงค์ข้อมูลอุปกรณ์'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (deviceViewModel.errorMessage != null)
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 36, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    deviceViewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        deviceViewModel.fetchDeviceInfo(silent: true),
                    child: const Text('ลองใหม่อีกครั้ง'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // App Version Banner Card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user,
                      size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Application Version',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deviceViewModel.appVersion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Device Specs Card
          _buildDeviceCard(
            title: 'ข้อมูลเครื่อง (Device Specs)',
            children: [
              _buildDeviceInfoRow(Icons.perm_device_information, 'Device ID',
                  deviceViewModel.deviceId),
              const Divider(height: 12),
              _buildDeviceInfoRow(
                  Icons.qr_code, 'Serial No.', deviceViewModel.serialNo),
            ],
          ),
          const SizedBox(height: 12),
          // Network Info Card
          _buildDeviceCard(
            title: 'เครือข่าย (Network)',
            children: [
              _buildDeviceInfoRow(
                  Icons.wifi, 'IP Address', deviceViewModel.ipAddress),
              const Divider(height: 12),
              _buildDeviceInfoRow(Icons.signal_wifi_4_bar, 'Wi-Fi Strength',
                  deviceViewModel.wifiStrength),
            ],
          ),
          const SizedBox(height: 12),
          // Storage / Master Images Card
          _buildDeviceCard(
            title: 'พื้นที่จัดเก็บ (Storage)',
            children: [
              _buildDeviceInfoRow(Icons.image, 'Master Images',
                  '${deviceViewModel.masterImageCount} รูป'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: deviceViewModel.masterImageCount > 0 &&
                          !deviceViewModel.isLoading
                      ? () =>
                          _confirmDeleteMasterImages(context, deviceViewModel)
                      : null,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text(
                    'ลบรูปภาพ Master ทั้งหมด',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMasterImages(
      BuildContext context, DeviceInfoViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text(
            'คุณต้องการลบรูปภาพ Master ทั้งหมดออกจากเครื่องใช่หรือไม่?\n(รูปภาพจะถูกดาวน์โหลดใหม่เมื่อทำการ Sync)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteMasterImages();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('ลบข้อมูล', style: TextStyle(color: Colors.white)),
          ),
        ],
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
