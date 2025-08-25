// lib/data/network/document_record_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // สำหรับ DbDocumentRecord
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
// TODO: อาจจะต้องสร้าง Data Model สำหรับ Historical Record ถ้ามี Field ที่แตกต่างจาก DbDocumentRecord
// import 'package:biochecksheet7_flutter/data/models/historical_record_data.dart';

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

/*
// NEW: Define a data class for API upload response (if API returns specific format)
class UploadRecordResult {
  final int uid;
  final int result; // Assuming 3 for success, other for failure

  UploadRecordResult({required this.uid, required this.result});

  factory UploadRecordResult.fromJson(Map<String, dynamic> json) {
    return UploadRecordResult(
      uid: json['uid'] as int, // Assuming 'uid' is the key for local UID
      result: int.tryParse(json['result']?.toString() ?? '0') ?? 0, // <<< แก้ไขตรงนี้
    );
  }
}
*/

class DocumentRecordApiService {
  /// Fetches historical record data from API for charting.
  /// Assumes API returns a List of objects with 'Value' and 'CreateDate' (or 'LastSync').
  Future<List<Map<String, dynamic>>> fetchHistoricalRecords({
    required String jobId,
    required String machineId,
    required String tagId,
  }) async {
    final uri = Uri.parse(
        "$_baseUrl/CHECKSHEET_HISTORYTAG_SYNC"); // Assumed API Endpoint
    print("Fetching historical records from API: $uri");
    final headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> parameterObject = {
      "JobId": jobId,
      "MachineId": machineId,
      "TagId": tagId,
      "username":
          "000000" // Assuming username parameter is still required for auth/context
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
        throw Exception(
            "Historical Record API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error fetching historical records: ${e.message}");
      throw Exception(
          "Network error fetching historical records: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred fetching historical records: $e");
      throw Exception(
          "An unexpected error occurred fetching historical records: $e");
    }
  }

  /// NEW: Uploads a list of DbDocumentRecord to the API.
  /// Uploads a list of DbDocumentRecord to the API.
  /// Converts DbDocumentRecord to server-expected JSON format (e.g., PascalCase keys).
  Future<List<UploadRecordResult>> uploadRecords(
      // <<< CRUCIAL FIX: Change return type from Future<bool> to Future<List<UploadRecordResult>>
      List<DbDocumentRecord> recordsToUpload,
      {String? documentCreateDate,
      String? documentUserId}) async {
    final uri = Uri.parse(
        "$_baseUrl/CHECKSHEET_DOCUMENTRECORD_SYNC"); // Assumed API Endpoint
    print("Uploading records to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords =
        recordsToUpload.map((record) {
      return {
        "createDate": documentCreateDate,
        "userId": documentUserId,
        "uid": record.uid,
        "documentId": record.documentId,
        "machineId": record.machineId,
        "jobId": record.jobId,
        "tagId": record.tagId,
        "tagName": record.tagName,
        "tagType": record.tagType,
        "tagSelectionValue": record.tagSelectionValue,
        "queryStr": record.queryStr,
        "description": record.description,
        "specification": record.specification,
        "specMin": record.specMin,
        "specMax": record.specMax,
        "unit": record.unit,
        "value": record.value,
        "ValueType": record.valueType,
        "Status": record.status,
        "UnReadable": record.unReadable,
        "Remark": record.remark
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username":
          "000000" // Assuming username parameter is still required for auth/context
      // ถ้ามี Password ก็เพิ่ม Passw
      //ord: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DOCUMENTRECORD_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });
    print("Request body for record upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Record Upload API Response status: ${response.statusCode}");
      print("Record Upload API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table1'] != null && responseJson['Table1'] is List) {
          final List<dynamic> resultsList = responseJson['Table1'];
          return resultsList
              .map((item) => UploadRecordResult.fromJson(item))
              .toList();
        } else {
          throw Exception(
              "Record Upload API response format invalid (missing 'Table' key or not a list).");
        }
      } else {
        throw Exception(
            "Record Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading records: ${e.message}");
      throw Exception("Network error uploading records: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading records: $e");
      throw Exception("An unexpected error occurred uploading records: $e");
    }
  }

  /// Uploads a list of DbDocumentRecord to the API.
  /// Returns a list of UploadRecordResult indicating success/failure for each record.
  Future<List<UploadRecordResult>> uploadDocumentRecords(
      List<DbDocumentRecord> recordsToUpload,
      {String? documentCreateDate,
      String? documentUserId} // <<< CRUCIAL FIX: Add these parameters
      ) async {
    final uri = Uri.parse(
        "$_baseUrl/CHECKSHEET_DOCUMENTRECORD_SYNC"); // Assumed API Endpoint
    print("Uploading document records to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords =
        recordsToUpload.map((record) {
      return {
        "createDate": documentCreateDate,
        "userId": documentUserId,
        "uid": record.uid,
        "documentId": record.documentId,
        "machineId": record.machineId,
        "jobId": record.jobId,
        "tagId": record.tagId,
        "tagName": record.tagName,
        "tagType": record.tagType,
        "tagSelectionValue": record.tagSelectionValue,
        "queryStr": record.queryStr,
        "description": record.description,
        "specification": record.specification,
        "specMin": record.specMin,
        "specMax": record.specMax,
        "unit": record.unit,
        "value": record.value,
        "ValueType": record.valueType,
        "Status": record.status,
        "UnReadable": record.unReadable,
        "Remark": record.remark
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username":
          "000000" // Assuming username parameter is still required for auth/context
      // ถ้ามี Password ก็เพิ่ม Passw
      //ord: "your_password"
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DOCUMENTRECORD_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });
    print("Request body for document record upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print(
          "Document Record Upload API Response status: ${response.statusCode}");
      print("Document Record Upload API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table1'] != null && responseJson['Table1'] is List) {
          final List<dynamic> resultsList = responseJson['Table1'];
          return resultsList
              .map((item) => UploadRecordResult.fromJson(item))
              .toList();
        } else {
          throw Exception(
              "Document Record Upload API response format invalid (missing 'Table' key or not a list).");
        }
      } else {
        throw Exception(
            "Document Record Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading document records: ${e.message}");
      throw Exception("Network error uploading document records: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading document records: $e");
      throw Exception(
          "An unexpected error occurred uploading document records: $e");
    }
  }
}
