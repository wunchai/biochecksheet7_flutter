// lib/data/network/job_api_service.dart
import 'dart:convert';
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart'; // สำหรับ DbJob

//const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc"; // URL เดียวกันกับ UserApiService

final String _baseUrl = AppConfig.baseUrl;

class JobApiService {
  Future<List<DbJob>> syncJobs() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterJob_Sync");
    print("Syncing jobs with API: $uri"); // Debugging log
    final headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> parameterObject = {
      "username": "000000"
      // ถ้ามี Password ก็เพิ่ม Password: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterJob_Sync",
      // CRUCIAL CHANGE: Encode the 'parameterObject' into a JSON string
      "Paremeter": jsonEncode(parameterObject) // <<< แก้ไขตรงนี้
    });

    print("Request Body: $body"); // Debugging log
    try {
      final response = await http.post(uri, headers: headers, body: body);

      final String decodedBody =
          utf8.decode(response.bodyBytes); // <<< แก้ไขตรงนี้
      print(
          "Job Sync API Response 1: $decodedBody"); // Debugging log with decoded body

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> jobList = responseJson['Table'];
          final List<DbJob> syncedJobs = jobList.map((jobData) {
            return DbJob(
              // ใช้ DbJob ที่ generate โดย drift
              uid: 0, // uid จะถูกกำหนดโดย DB เมื่อ insert
              jobId: jobData['JobId']?.toString() ?? '', // <<< แก้ไขตรงนี้
              jobName: jobData['JobName'] ?? '',
              machineName: jobData['MachineName'] ?? '',
              documentId: jobData['DocumentId'] ?? '',
              location: jobData['Location'] ?? '',
              jobStatus: int.tryParse(jobData['Status'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
              // NEW: Add CreateDate and CreateBy mappings
              createDate: jobData['CreateDate'] ?? '', // <<< เพิ่มตรงนี้
              createBy: jobData['CreateBy'] ?? '', // <<< เพิ่มตรงนี้
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
      print("Network error during job sync: ${e.message}"); // Debugging log
      throw Exception("Network error during job sync: ${e.message}");
    } catch (e) {
      print(
          "An unexpected error occurred during job sync: $e"); // Debugging log
      throw Exception("An unexpected error occurred during job sync: $e");
    }
  }
}
