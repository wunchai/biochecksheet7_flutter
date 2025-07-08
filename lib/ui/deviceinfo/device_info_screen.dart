// lib/ui/deviceinfo/device_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_viewmodel.dart';

/// หน้าจอสำหรับแสดงข้อมูลอุปกรณ์ (Device Info).
class DeviceInfoScreen extends StatefulWidget {
  final String title;
  const DeviceInfoScreen({super.key, required this.title});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
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
          // CRUCIAL FIX: Call fetchDeviceInfo here, after the ViewModel is available in context.
          // This ensures it's called only once after the first build, or when data needs refresh.
          // Use a flag to ensure it's only fetched once initially.
          if (!viewModel.isLoading && viewModel.deviceId == 'กำลังโหลด...' && viewModel.errorMessage == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Ensure widget is still mounted
                viewModel.fetchDeviceInfo();
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
                    onPressed: viewModel.isLoading ? null : () => viewModel.fetchDeviceInfo(),
                    child: const Text('Refresh Data'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}