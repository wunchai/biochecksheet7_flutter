// lib/data/network/draft_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';

class DraftApiService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<List<UploadRecordResult>> uploadDraftJobs(
      List<DbDraftJob> jobs) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTJOB_SYNC");
    print("Uploading draft jobs to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords = jobs.map((record) {
      return {
        "uid": record.uid,
        "jobName": record.jobName,
        "location": record.location,
        "machineName": record.machineName,
        "documentId": record.documentId,
        "status": record.status,
        "createDate": record.createDate,
        "updatedAt": record.updatedAt
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username": "000000" // Assuming username parameter is still required
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DRAFTJOB_SYNC",
      "Paremeter":
          jsonEncode(parameterObject) // Typo 'Paremeter' matches API convention
    });

    print("Request body for draft job upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Draft Job Upload API Response status: ${response.statusCode}");
      print("Draft Job Upload API Response body: $decodedBody");

      return _parseUploadResponse(
          response.statusCode, decodedBody, jobs.map((e) => e.uid).toList());
    } on http.ClientException catch (e) {
      print("Network error uploading draft jobs: ${e.message}");
      throw Exception("Network error uploading draft jobs: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading draft jobs: $e");
      throw Exception("An unexpected error occurred uploading draft jobs: $e");
    }
  }

  Future<List<UploadRecordResult>> uploadDraftMachines(
      List<DbDraftMachine> machines) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTMACHINE_SYNC");
    print("Uploading draft machines to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords = machines.map((record) {
      return {
        "uid": record.uid,
        "draftJobId": record.draftJobId,
        "machineId": record.machineId,
        "machineName": record.machineName,
        "machineType": record.machineType
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username": "000000"
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DRAFTMACHINE_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });

    print("Request body for draft machine upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Draft Machine Upload API Response status: ${response.statusCode}");
      print("Draft Machine Upload API Response body: $decodedBody");

      return _parseUploadResponse(response.statusCode, decodedBody,
          machines.map((e) => e.uid).toList());
    } on http.ClientException catch (e) {
      print("Network error uploading draft machines: ${e.message}");
      throw Exception("Network error uploading draft machines: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading draft machines: $e");
      throw Exception(
          "An unexpected error occurred uploading draft machines: $e");
    }
  }

  Future<List<UploadRecordResult>> uploadDraftTags(
      List<DbDraftTag> tags) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTTAG_SYNC");
    print("Uploading draft tags to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords = tags.map((record) {
      return {
        "uid": record.uid,
        "draftJobId": record.draftJobId,
        "draftMachineId": record.draftMachineId,
        "tagGroupId": record.tagGroupId,
        "tagGroupName": record.tagGroupName,
        "tagName": record.tagName,
        "tagType": record.tagType,
        "tagSelectionValue": record.tagSelectionValue,
        "specMin": record.specMin,
        "specMax": record.specMax,
        "unit": record.unit,
        "description": record.description
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username": "000000"
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DRAFTTAG_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });

    print("Request body for draft tag upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Draft Tag Upload API Response status: ${response.statusCode}");
      print("Draft Tag Upload API Response body: $decodedBody");

      return _parseUploadResponse(
          response.statusCode, decodedBody, tags.map((e) => e.uid).toList());
    } on http.ClientException catch (e) {
      print("Network error uploading draft tags: ${e.message}");
      throw Exception("Network error uploading draft tags: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading draft tags: $e");
      throw Exception("An unexpected error occurred uploading draft tags: $e");
    }
  }

  List<UploadRecordResult> _parseUploadResponse(int statusCode, String decodedBody, List<int> originalUids) {
    if (statusCode == 200) {
      // ตามที่ User ต้องการ: ไม่สนใจ JSON รูปแบบข้างใน หากส่งผ่าน 200 แล้วได้ Response Body ปกติถือว่าสำเร็จทั้งหมด
      return originalUids.map((uid) => UploadRecordResult(uid: uid, result: 3)).toList();
    } else {
      throw Exception("Upload API failed: Status code $statusCode");
    }
  }
}
