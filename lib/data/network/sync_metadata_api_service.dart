// lib/data/network/sync_metadata_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // For SyncStatus (though not directly used here)
import 'package:biochecksheet7_flutter/data/network/api_request_models.dart'; // <<< NEW: Import API Request Models
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import API Response Models (for SyncMetadataResponse)

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class SyncMetadataApiService {
  /// Checks the synchronization status and retrieves metadata actions from the API.
  /// Now sends device-specific information.
  /// Returns a list of SyncMetadataResponse objects.
  Future<List<SyncMetadataResponse>> checkSyncStatus({ // <<< Changed return type
    required String username,
    required String deviceId,
    required String serialNo,
    required String version,
    required String ipAddress,
    required String wifiStrength,
  }) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DEVICE_INFO_SYNC"); // Assumed API Endpoint
    print("Checking sync status with URL: $uri");
    final headers = {"Content-Type": "application/json"};


    // Create the request body using the new model
    final requestBody = SyncMetadataRequest(
      username: username,
      deviceId: deviceId,
      serialNo: serialNo,
      version: version,
      ipAddress: ipAddress,
      wifiStrength: wifiStrength,
    );

    final Map<String, dynamic> parameterObject = {      
      "record": jsonEncode(requestBody.toJson()),
      "username": "000000" // Assuming username parameter is still required for auth/context
      // ถ้ามี Password ก็เพิ่ม Passw
      //ord: "your_password"
    };


  

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DEVICE_INFO_SYNC",
      "Paremeter": jsonEncode(parameterObject), // Convert request model to JSON string
    });
    print("Request body for sync metadata: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Sync Metadata API Response status: ${response.statusCode}");
      print("Sync Metadata API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        // Assuming API returns a 'Table' key with a list of actions
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> actionsList = responseJson['Table'];
          return actionsList.map((item) => SyncMetadataResponse.fromJson(item)).toList(); // Map to SyncMetadataResponse
        } else {
          throw Exception("Sync Metadata API response format invalid (missing 'Table1' key or not a list).");
        }
      } else {
        throw Exception("Sync Metadata API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error during sync metadata: ${e.message}");
      throw Exception("Network error during sync metadata: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred during sync metadata: $e");
      throw Exception("An unexpected error occurred during sync metadata: $e");
    }
  }
}