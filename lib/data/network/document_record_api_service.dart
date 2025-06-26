// lib/data/network/document_record_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// TODO: อาจจะต้องสร้าง Data Model สำหรับ Historical Record ถ้ามี Field ที่แตกต่างจาก DbDocumentRecord
// import 'package:biochecksheet7_flutter/data/models/historical_record_data.dart';

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class DocumentRecordApiService {
  /// Fetches historical record data from API for charting.
  /// Assumes API returns a List of objects with 'Value' and 'CreateDate' (or 'LastSync').
  Future<List<Map<String, dynamic>>> fetchHistoricalRecords({
    required String jobId,
    required String machineId,
    required String tagId,
  }) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_HISTORYTAG_SYNC"); // Assumed API Endpoint
    print("Fetching historical records from API: $uri");
    final headers = {"Content-Type": "application/json"};
      final Map<String, dynamic> parameterObject = {
       "JobId": jobId,
        "MachineId": machineId,
        "TagId": tagId,
        "username": "000000" // Assuming username parameter is still required for auth/context
      // ถ้ามี Password ก็เพิ่ม Password: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_HISTORYTAG_SYNC",
      "Paremeter": jsonEncode(parameterObject) // <<< แก้ไขตรงนี้
    });
    print("Request body for historical records: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Historical Record API Response status: ${response.statusCode}");
      print("Historical Record API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> historicalData = responseJson['Table'];
          // Return as List<Map<String, dynamic>> for flexible parsing in Repository
          return historicalData.cast<Map<String, dynamic>>();
        } else {
          throw Exception("Historical Record API response format invalid.");
        }
      } else {
        throw Exception("Historical Record API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error fetching historical records: ${e.message}");
      throw Exception("Network error fetching historical records: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred fetching historical records: $e");
      throw Exception("An unexpected error occurred fetching historical records: $e");
    }
  }
}