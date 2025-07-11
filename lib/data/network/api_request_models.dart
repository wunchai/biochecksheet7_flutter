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

/// NEW: Request model for User Registration API.
class RegisterUserRequest {
  final String userId;
  final String password;
  final String
      userCode; // Assuming userCode is the same as userId for registration
  final String
      displayName; // Assuming displayName is the same as userId for registration
  final String position; // Default position for new users
  final int status; // Default status for new users

  RegisterUserRequest({
    required this.userId,
    required this.password,
    this.userCode = '', // Default to empty, or same as userId
    this.displayName = '', // Default to empty, or same as userId
    this.position = 'User', // Default position
    this.status =
        0, // Default status for new user (e.g., 0 for pending, 1 for active)
  });

  Map<String, dynamic> toJson() {
    return {
      "UserId": userId,
      "Password": password,
      "UserCode": userCode.isEmpty
          ? userId
          : userCode, // If userCode is empty, use userId
      "DisplayName": displayName.isEmpty
          ? userId
          : displayName, // If displayName is empty, use userId
      "Position": position,
      "Status": status,
    };
  }
}
