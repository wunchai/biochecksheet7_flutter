// lib/ui/deviceinfo/device_info_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart'; // Import DeviceInfoService

class DeviceInfoViewModel extends ChangeNotifier {
  final DeviceInfoService _deviceInfoService;

  String _deviceId = 'กำลังโหลด...';
  String get deviceId => _deviceId;

  String _serialNo = 'กำลังโหลด...';
  String get serialNo => _serialNo;

  String _appVersion = 'กำลังโหลด...';
  String get appVersion => _appVersion;

  String _ipAddress = 'กำลังโหลด...';
  String get ipAddress => _ipAddress;

  String _wifiStrength = 'กำลังโหลด...';
  String get wifiStrength => _wifiStrength;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DeviceInfoViewModel({required DeviceInfoService deviceInfoService})
      : _deviceInfoService = deviceInfoService;

  /// Fetches all device information.
  Future<void> fetchDeviceInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _deviceId = await _deviceInfoService.getDeviceId();
      _serialNo = await _deviceInfoService.getSerialNo();
      _appVersion = await _deviceInfoService.getAppVersion();
      _ipAddress = await _deviceInfoService.getIpAddress();
      _wifiStrength = await _deviceInfoService.getWifiStrength();
    } catch (e) {
      _errorMessage = 'ข้อผิดพลาดในการโหลดข้อมูลอุปกรณ์: $e';
      print('Error fetching device info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}