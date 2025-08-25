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
  bool _isShowingDialog =
      false; // <<< NEW: Flag to prevent multiple dialogs/snackbars

  // No need to call fetchDeviceInfo in initState anymore.
  // It will be called in the Consumer's builder.
  @override
  void initState() {
    super.initState();
  }

  // Helper method เพื่อสร้างแถวสำหรับแสดงรายละเอียด
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // กำหนดความกว้างของ Label เพื่อจัดแนวให้สวยงาม
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<DeviceInfoViewModel>(
        builder: (context, viewModel, child) {
          // NEW: Show ErrorDialog/SnackBar for sync messages
          if (viewModel.syncMessage != null && !_isShowingDialog) {
            // <<< Check _isShowingDialog
            // Capture the message before async operation
            final String currentSyncMessage = viewModel.syncMessage!;
            print(
                'DeviceInfoScreen: 1.currentSyncMessage (outside callback) is $currentSyncMessage'); // Debugging
            _isShowingDialog = true; // Set flag to true

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // Make callback async
              if (mounted) {
                print(
                    'DeviceInfoScreen: 2.currentSyncMessage (inside callback) is $currentSyncMessage'); // Debugging

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
                    // Await the dialog to close
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return ErrorDialog(
                        title: 'ข้อผิดพลาดในการซิงค์ข้อมูลอุปกรณ์',
                        message: currentSyncMessage, // Use captured message
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(currentSyncMessage)), // Use captured message
                  );
                }
                // CRUCIAL FIX: Clear the message AFTER the dialog/snackbar has been shown and potentially closed.
                // Reset flag after operation
                viewModel.syncMessage = null;
                _isShowingDialog = false; // Reset flag
              }
            });
          }

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Device ID', viewModel.deviceId),
                  _buildDetailRow('Serial No.', viewModel.serialNo),
                  _buildDetailRow('App Version', viewModel.appVersion),
                  _buildDetailRow('IP Address', viewModel.ipAddress),
                  _buildDetailRow('Wi-Fi Strength', viewModel.wifiStrength),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.fetchDeviceInfo(),
                    child: const Text('Refresh Data'),
                  ),
                ],
              ),
            );
          }
        },
      ),
      // NEW: Floating Action Button for Manual Metadata Sync
      floatingActionButton: FloatingActionButton(
        heroTag: "manualSyncFab", // Unique tag for multiple FABs
        onPressed: () {
          Provider.of<DeviceInfoViewModel>(context, listen: false)
              .performManualMetadataSync();
        },
        child: const Icon(Icons.sync), // Sync icon
      ),
    );
  }
}
