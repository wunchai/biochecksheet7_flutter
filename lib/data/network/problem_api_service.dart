// lib/data/network/problem_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // สำหรับ DbProblem

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class ProblemApiService {
  Future<List<DbProblem>> syncProblems() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterProblem_Sync");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterProblem_Sync",
      "Paremeter": {} // Assuming no parameters
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> problemList = responseJson['Table'];
          final List<DbProblem> syncedProblems = problemList.map((problemData) {
            return DbProblem(
              uid: 0,
              problemId: problemData['ProblemId'] ?? '',
              problemName: problemData['ProblemName'] ?? '',
              description: problemData['Description'] ?? '',
              problemStatus: int.tryParse(problemData['ProblemStatus'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
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
      throw Exception("Network error during problem sync: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred during problem sync: $e");
    }
  }
}