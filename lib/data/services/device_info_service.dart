// lib/data/services/device_info_service.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin;
  final NetworkInfo _networkInfo;

  // CRUCIAL FIX: Make constructor simple, initialize plugins here.
  DeviceInfoService()
      : _deviceInfoPlugin = DeviceInfoPlugin(),
        _networkInfo = NetworkInfo();

  /// Gets unique device ID (Android ID, iOS identifierForVendor, etc.).
  Future<String> getDeviceId() async {
    if (kIsWeb) {
      return 'web_device_id';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_id';
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await _deviceInfoPlugin.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await _deviceInfoPlugin.linuxInfo;
      return linuxInfo.id;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macOsInfo = await _deviceInfoPlugin.macOsInfo;
      return macOsInfo.systemGUID ?? 'unknown_macos_id';
    }
    return 'unknown_device_id';
  }

  /// Gets device serial number (often restricted, may return device ID).
  Future<String> getSerialNo() async {
    if (kIsWeb) {
      return 'web_serial_no';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.serialNumber;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_serial';
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await _deviceInfoPlugin.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await _deviceInfoPlugin.linuxInfo;
      return linuxInfo.id ?? 'unknown_linux_serial';
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macOsInfo = await _deviceInfoPlugin.macOsInfo;
      return macOsInfo.systemGUID ?? 'unknown_macos_serial';
    }
    return 'unknown_serial_no';
  }

  /// Gets the application version (e.g., 1.0.0).
  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Gets the local IP address.
  Future<String> getIpAddress() async {
    if (kIsWeb) {
      return 'web_ip_address';
    }
    try {
      String? ip = await _networkInfo.getWifiIP();
      return ip ?? 'unknown_ip';
    } catch (e) {
      print('Error getting IP address: $e');
      return 'error_ip';
    }
  }

  /// Gets Wi-Fi strength (often requires location permission).
  Future<String> getWifiStrength() async {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'n/a_for_platform';
    }
    try {
      String? wifiBSSID = await _networkInfo.getWifiBSSID();
      String? wifiName = await _networkInfo.getWifiName();
      return 'SSID: ${wifiName ?? 'N/A'}, BSSID: ${wifiBSSID ?? 'N/A'}';
    } catch (e) {
      print('Error getting Wi-Fi info: $e');
      return 'error_wifi_strength';
    }
  }
}
