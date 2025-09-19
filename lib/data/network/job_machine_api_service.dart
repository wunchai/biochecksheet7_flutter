// lib/data/network/job_machine_api_service.dart
import 'dart:convert';
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart'; // สำหรับ DbDocumentMachine

//const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

final String _baseUrl = AppConfig.baseUrl;

class JobMachineApiService {
  Future<List<DbDocumentMachine>> syncJobMachines() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterMachine_Sync");
    print("Syncing job machines with URL: $uri");
    final headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> parameterObject = {
      "username": "000000"
      // ถ้ามี Password ก็เพิ่ม Password: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterMachine_Sync",
      "Paremeter": jsonEncode(parameterObject) // <<< แก้ไขตรงนี้
    });
    print("Request body: $body");
    try {
      final response = await http.post(uri, headers: headers, body: body);

      final String decodedBody =
          utf8.decode(response.bodyBytes); // <<< แก้ไขตรงนี้
      print(
          "Job Sync API Response 2: $decodedBody"); // Debugging log with decoded body

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> machineList = responseJson['Table'];
          final List<DbDocumentMachine> syncedMachines =
              machineList.map((machineData) {
            return DbDocumentMachine(
              uid: 0,
              id: machineData['id'] ?? 0, // Map 'id' as int
              jobId: machineData['JobId']?.toString() ??
                  '', // Convert int to String
              documentId: machineData['DocumentId']?.toString() ??
                  '', // Convert int to String, or handle null
              machineId: machineData['MachineId']?.toString() ??
                  '', // Convert int to String
              machineName: machineData['MachineName'] ?? '',
              machineType: machineData['MachineType'] ?? '',
              description: machineData['Description'] ?? '',
              specification: machineData['Specification'] ?? '',
              status: int.tryParse(machineData['Status'].toString()) ?? 0,
              uiType: int.tryParse(machineData['UiType'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
              createDate: machineData['CreateDate'] ?? '',
              createBy: machineData['CreateBy'] ?? '',
            );
          }).toList();
          return syncedMachines;
        } else {
          throw Exception("Job Machine Sync API response format invalid.");
        }
      } else {
        throw Exception(
            "Job Machine Sync failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error during job machine sync: ${e}");
      throw Exception("Network error during job machine sync: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred during job machine sync: ${e}");
      throw Exception(
          "An unexpected error occurred during job machine sync: $e");
    }
  }
}
