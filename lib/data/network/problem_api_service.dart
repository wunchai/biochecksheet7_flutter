// lib/data/network/problem_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import api_response_models.dart
import 'dart:async';

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class ProblemApiService {
  /// Syncs problem data from API.
  Future<List<DbProblem>> syncProblems() async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_PROBLEM_SYNC"); // Assumed API Endpoint
    print("Syncing problems with URL: $uri");
    final headers = {"Content-Type": "application/json"};
      final Map<String, dynamic> parameterObject = {
      "username": "000000"
      // ถ้ามี Password ก็เพิ่ม Password: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_PROBLEM_SYNC",
      "Paremeter": jsonEncode(parameterObject) // <<< แก้ไขตรงนี้
    });
    print("Request body: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body) .timeout(const Duration(seconds: 15)); // <<< CRUCIAL FIX: กำหนด Timeout ที่นี่ (15 วินาที)
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Problem Sync API Response status: ${response.statusCode}");
      print("Problem Sync API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> problemList = responseJson['Table'];
          final List<DbProblem> syncedProblems = problemList.map((problemData) {
             print('ProblemApiService: Mapping API problemData for problemId: "${problemData['problemId']}", documentId: "${problemData['documentId']}"'); // <<< Debugging
            return DbProblem(
              uid: 0, // Auto-increment
              problemId: problemData['problemId']?.toString(),
              problemName: problemData['problemName'],
              problemDescription: problemData['problemDescription'], // <<< Corrected: Use ProblemDescription
              problemStatus: int.tryParse(problemData['problemStatus']?.toString() ?? '0') ?? 0,
              problemSolvingDescription: problemData['problemSolvingDescription'],
              documentId: problemData['documentId']?.toString(), // <<< NEW: Map documentId              
              machineId: problemData['machineId']?.toString(), // <<< NEW: Map machineId
              machineName: problemData['machineName'], // <<< NEW: Map machineName
              jobId: problemData['jobId']?.toString(), // <<< NEW: Map jobId
              tagId: problemData['tagId']?.toString(),
              tagName: problemData['tagName'],
              tagType: problemData['tagType'],
              description: problemData['description'], // <<< Corrected: Use TagDescription
              note: problemData['note'],
              specification: problemData['specification'],
              specMin: problemData['specMin']?.toString(),
              specMax: problemData['specMax']?.toString(),
              unit: problemData['unit'],
              value: problemData['value']?.toString(),
              remark: problemData['remark'],
              unReadable: problemData['unReadable']?.toString() ?? 'false',
              lastSync: DateTime.now().toIso8601String(),
              problemSolvingBy: problemData['solvingBy'],
              syncStatus: int.tryParse(problemData['syncStatus']?.toString() ?? '0') ?? 0,
            );
          }).toList();
          return syncedProblems;
        } else {
          throw Exception("Problem Sync API response format invalid.");
        }
      } else {
        throw Exception("Problem Sync failed: Status code ${response.statusCode}");
      }
     } on TimeoutException { // <<< CRUCIAL FIX: Re-throw TimeoutException
      print("Network timeout during problem sync.");
      rethrow; // Re-throw the original TimeoutException
    } on http.ClientException catch (e) { // <<< CRUCIAL FIX: Re-throw ClientException
      print("Network error during problem sync: ${e.message}");
      rethrow; // Re-throw the original ClientException
    } catch (e) {
      print("An unexpected error occurred during problem sync: $e");
      throw Exception("เกิดข้อผิดพลาดที่ไม่คาดคิดในการซิงค์ปัญหา: $e");
    }
  }

  /// Uploads a list of DbProblem to the API (e.g., after solving).
  /// Returns a list of UploadRecordResult indicating success/failure for each problem.
  Future<List<UploadRecordResult>> uploadProblems(List<DbProblem> problemsToUpload) async { // <<< Corrected Return Type
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_PROBLEMRECORD_SYNC"); // Assumed API Endpoint
    print("Uploading problems to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonProblems = problemsToUpload.map((problem) {
      return {
        "uid": problem.uid,
        "problemId": problem.problemId,
        "problemName": problem.problemName,
        "problemDescription": problem.problemDescription,
        "problemStatus": problem.problemStatus,
        "solvingDescription": problem.problemSolvingDescription,
        "machineId": problem.machineId,
        "machineName": problem.machineName,
        "jobId": problem.jobId,
        "documentId": problem.documentId,
        "tagId": problem.tagId,
        "tagName": problem.tagName,
        "tagType": problem.tagType,
        "tagDescription": problem.description,
        "note": problem.note,
        "specification": problem.specification,
        "specMin": problem.specMin,
        "specMax": problem.specMax,
        "unit": problem.unit,
        "value": problem.value,
        "remark": problem.remark,
        "unReadable": problem.unReadable,
        "lastSync": problem.lastSync,
        "solvingBy": problem.problemSolvingBy,
      
      };
    }).toList();

   final Map<String, dynamic> parameterObject = {      
      "record": jsonEncode(jsonProblems),
      "username": "000000" // Assuming username parameter is still required for auth/context
      // ถ้ามี Password ก็เพิ่ม Passw
      //ord: "your_password"
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_PROBLEMRECORD_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });
    print("Request body for problem upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Problem Upload API Response status: ${response.statusCode}");
      print("Problem Upload API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        // Assuming server returns a 'Table' key with a list of results
        if (responseJson['Table1'] != null && responseJson['Table1'] is List) {
          final List<dynamic> resultsList = responseJson['Table1'];
          return resultsList.map((item) => UploadRecordResult.fromJson(item)).toList(); // Map to UploadRecordResult
        } else {
          throw Exception("Problem Upload API response format invalid (missing 'Table1' key or not a list).");
        }
      } else {
        throw Exception("Problem Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading problems: ${e.message}");
      throw Exception("Network error uploading problems: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading problems: $e");
      throw Exception("An unexpected error occurred uploading problems: $e");
    }
  }
}