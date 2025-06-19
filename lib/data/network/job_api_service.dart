// lib/data/network/job_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart'; // สำหรับ DbJob

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc"; // URL เดียวกันกับ UserApiService

class JobApiService {
  Future<List<DbJob>> syncJobs() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterJob_Sync");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterJob_Sync",
      "Paremeter": {"username": "000000"} // ตามที่เห็นใน DbJobCode.kt
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> jobList = responseJson['Table'];
          final List<DbJob> syncedJobs = jobList.map((jobData) {
            return DbJob( // ใช้ DbJob ที่ generate โดย drift
              uid: 0, // uid จะถูกกำหนดโดย DB เมื่อ insert
              jobId: jobData['JobId'] ?? '',
              jobName: jobData['JobName'] ?? '',
              machineName: jobData['MachineName'] ?? '',
              documentId: jobData['DocumentId'] ?? '',
              location: jobData['Location'] ?? '',
              jobStatus: int.tryParse(jobData['Status'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
            );
          }).toList();
          return syncedJobs;
        } else {
          throw Exception("Job Sync API response format invalid.");
        }
      } else {
        throw Exception("Job Sync failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error during job sync: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred during job sync: $e");
    }
  }
}