// lib/data/network/api_request_models.dart
/// Request model for SyncMetadata API.
class SyncMetadataRequest {
  final String username;
  final String deviceId;
  final String serialNo;
  final String version;
  final String ipAddress;
  final String wifiStrength;

  SyncMetadataRequest({
    required this.username,
    required this.deviceId,
    required this.serialNo,
    required this.version,
    required this.ipAddress,
    required this.wifiStrength,
  });

  Map<String, dynamic> toJson() {
    return {
      "UserName": username, // Assuming PascalCase for API
      "DeviceID": deviceId,
      "SerialNo": serialNo,
      "Version": version,
      "IPAddress": ipAddress,
      "WifiStrength": wifiStrength,
    };
  }
}