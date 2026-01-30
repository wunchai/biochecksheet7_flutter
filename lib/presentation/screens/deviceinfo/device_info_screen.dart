// lib/ui/deviceinfo/device_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/deviceinfo/device_info_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/widgets/error_dialog.dart'; // <<< NEW: Import ErrorDialog

/// หน้าจอสำหรับแสดงข้อมูลอุปกรณ์ (Device Info).
class DeviceInfoScreen extends StatefulWidget {
  final String title;
  const DeviceInfoScreen({super.key, required this.title});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  bool _isShowingDialog = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Consumer<DeviceInfoViewModel>(
        builder: (context, viewModel, child) {
          // Sync Result Handling
          if (viewModel.syncMessage != null && !_isShowingDialog) {
            final String currentSyncMessage = viewModel.syncMessage!;
            _isShowingDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                bool isError = currentSyncMessage
                        .toLowerCase()
                        .contains('ล้มเหลว') ||
                    currentSyncMessage.toLowerCase().contains('ข้อผิดพลาด') ||
                    currentSyncMessage.toLowerCase().contains('failed') ||
                    currentSyncMessage.toLowerCase().contains('error') ||
                    currentSyncMessage.toLowerCase().contains('exception') ||
                    currentSyncMessage.toLowerCase().contains('timed out') ||
                    currentSyncMessage
                        .toLowerCase()
                        .contains('ไม่สามารถเชื่อมต่อ');

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
                viewModel.syncMessage = null;
                _isShowingDialog = false;
              }
            });
          }

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchDeviceInfo(),
                    child: const Text('ลองใหม่อีกครั้ง'),
                  )
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Version Card
                  _buildHeaderCard(context, viewModel),
                  const SizedBox(height: 16),
                  // Device Specs Card
                  _buildInfoCard(
                    context,
                    title: 'ข้อมูลเครื่อง (Device Specs)',
                    children: [
                      _buildInfoRow(Icons.perm_device_information, 'Device ID',
                          viewModel.deviceId),
                      const Divider(),
                      _buildInfoRow(
                          Icons.qr_code, 'Serial No.', viewModel.serialNo),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Network Info Card
                  _buildInfoCard(
                    context,
                    title: 'เครือข่าย (Network)',
                    children: [
                      _buildInfoRow(
                          Icons.wifi, 'IP Address', viewModel.ipAddress),
                      const Divider(),
                      _buildInfoRow(Icons.signal_wifi_4_bar, 'Wi-Fi Strength',
                          viewModel.wifiStrength),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Refresh Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => viewModel.fetchDeviceInfo(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('รีเฟรชข้อมูล'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "manualSyncFab",
        onPressed: () {
          Provider.of<DeviceInfoViewModel>(context, listen: false)
              .performManualMetadataSync();
        },
        icon: const Icon(Icons.sync),
        label: const Text('ซิงค์ข้อมูล'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, DeviceInfoViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.blue.shade500],
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_user, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Application Version',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              viewModel.appVersion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required List<Widget> children}) {
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          const SizedBox(width: 16),
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
                    fontSize: 16,
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
}
