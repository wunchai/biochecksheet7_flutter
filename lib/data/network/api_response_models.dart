// lib/data/network/api_response_models.dart
/// Data class for API upload response for a single record.
/// Used when API returns a list of results for each uploaded item.
class UploadRecordResult {
  final int uid; // Local UID of the record
  final int result; // API result code (e.g., 3 for success, others for failure)
  final String? message; // Optional: API message for the record

  UploadRecordResult({required this.uid, required this.result, this.message});

  factory UploadRecordResult.fromJson(Map<String, dynamic> json) {
    return UploadRecordResult(
      uid: int.tryParse(json['uid']?.toString() ?? '0') ?? 0, // Ensure UID is parsed as int
      result: int.tryParse(json['result']?.toString() ?? '0') ?? 0, // Ensure result is parsed as int
      message: json['message']?.toString(), // Optional message from API
    );
  }

  
}
/// Response model for SyncMetadata API.
/// Represents an action/command received from the server.
class SyncMetadataResponse {
  final String? deviceId; // <<< NEW: Add deviceId (from API Response)
  final String actionId;
  final String actionType;
  final String? actionSql;
  final String? actionValue; // <<< NEW: Add actionValue (from API Response)

  SyncMetadataResponse({
    this.deviceId, // <<< Add to constructor
    required this.actionId,
    required this.actionType,
    this.actionSql,
    this.actionValue, // <<< Add to constructor
  });

  factory SyncMetadataResponse.fromJson(Map<String, dynamic> json) {
    return SyncMetadataResponse(
      deviceId: json['deviceId']?.toString(), // <<< CRUCIAL FIX: Map deviceId (camelCase)
      actionId: json['actionId']?.toString() ?? '', // <<< CRUCIAL FIX: Map actionId (camelCase)
      actionType: json['actionType']?.toString() ?? '', // <<< CRUCIAL FIX: Map actionType (camelCase)
      actionSql: json['actionSql']?.toString(), // <<< CRUCIAL FIX: Map actionSql (camelCase)
      actionValue: json['actionValue']?.toString(), // <<< CRUCIAL FIX: Map actionValue (camelCase)
    );
  }

  
}

/// NEW: Response model for Image Upload API.
/// Assumed API returns { "Table": [ { "guid": "...", "result": 3, "message": "..." } ] }
class ImageUploadResult {
  final String guid; // GUID of the uploaded image (from API)
  final int result; // API result code (e.g., 3 for success, others for failure)
  final String? message; // Optional: API message

  ImageUploadResult({required this.guid, required this.result, this.message});

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageUploadResult(
      guid: json['guid']?.toString() ?? '', // Assuming 'guid' key from API response
      result: int.tryParse(json['result']?.toString() ?? '0') ?? 0, // Assuming 'result' key from API response
      message: json['message']?.toString(), // Optional 'message' key
    );
  }
}