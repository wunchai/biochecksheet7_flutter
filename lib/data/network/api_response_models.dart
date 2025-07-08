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
/// NEW: Response model for SyncMetadata API.
/// Represents an action/command received from the server.
class SyncMetadataResponse {
  final String actionId;
  final String actionType; // e.g., "transferDB", "update", "cleanEndData"
  final String? actionSql; // SQL query for "update" action (optional)

  SyncMetadataResponse({
    required this.actionId,
    required this.actionType,
    this.actionSql,
  });

  factory SyncMetadataResponse.fromJson(Map<String, dynamic> json) {
    return SyncMetadataResponse(
      actionId: json['ActionId']?.toString() ?? '', // Assuming PascalCase from API
      actionType: json['ActionType']?.toString() ?? '',
      actionSql: json['ActionSql']?.toString(), // Optional SQL string
    );
  }
}