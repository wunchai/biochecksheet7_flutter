// lib/data/network/problem_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem

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
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Problem Sync API Response status: ${response.statusCode}");
      print("Problem Sync API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> problemList = responseJson['Table'];
          final List<DbProblem> syncedProblems = problemList.map((problemData) {
            return DbProblem(
              uid: 0, // Auto-increment
              problemId: problemData['problemId']?.toString(),
              problemName: problemData['problemName'],
              problemDescription: problemData['problemDescription'], // <<< Corrected: Use ProblemDescription
              problemStatus: int.tryParse(problemData['problemStatus']?.toString() ?? '0') ?? 0,
              problemSolvingDescription: problemData['problemSolvingDescription'],
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
    } on http.ClientException catch (e) {
      print("Network error during problem sync: ${e.message}");
      throw Exception("Network error during problem sync: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred during problem sync: $e");
      throw Exception("An unexpected error occurred during problem sync: $e");
    }
  }

  /// Uploads a list of DbProblem to the API (e.g., after solving).
  Future<bool> uploadProblems(List<DbProblem> problemsToUpload) async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_Problem_Upload"); // Assumed API Endpoint
    print("Uploading problems to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonProblems = problemsToUpload.map((problem) {
      return {
        "ProblemId": problem.problemId,
        "ProblemName": problem.problemName,
        "ProblemDescription": problem.problemDescription, // <<< Corrected: Use ProblemDescription
        "ProblemStatus": problem.problemStatus,
        "SolvingDescription": problem.problemSolvingDescription,
        "machineId": problem.machineId, // <<< NEW: Map machineId
        "machineName": problem.machineName, // <<< NEW: Map machineName
        "jobId": problem.jobId, // <<< NEW: Map jobId
        "tagId": problem.tagId,
        "tagName": problem.tagName,
        "tagType": problem.tagType,
        "TagDescription": problem.description, // <<< Corrected: Use TagDescription
        "Note": problem.note,
        "specification": problem.specification,
        "specMin": problem.specMin,
        "specMax": problem.specMax,
        "unit": problem.unit,
        "value": problem.value,
        "remark": problem.remark,
        "unReadable": problem.unReadable,
        "lastSync": problem.lastSync,
        "SolvingBy": problem.problemSolvingBy,
        "syncStatus": problem.syncStatus,
      };
    }).toList();

    final body = jsonEncode({
      "ServiceName": "CheckSheet_Problem_Upload",
      "Paremeter": jsonEncode(jsonProblems)
    });
    print("Request body for problem upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Problem Upload API Response status: ${response.statusCode}");
      print("Problem Upload API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        return responseJson['Success'] == true; // Adjust based on your server's success indicator
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