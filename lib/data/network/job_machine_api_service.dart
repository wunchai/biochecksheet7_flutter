// lib/data/network/job_machine_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart'; // สำหรับ DbDocumentMachine

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class JobMachineApiService {
  Future<List<DbDocumentMachine>> syncJobMachines() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterMachine_Sync");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterMachine_Sync",
      "Paremeter": {} // Assuming no parameters
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> machineList = responseJson['Table'];
          final List<DbDocumentMachine> syncedMachines = machineList.map((machineData) {
            return DbDocumentMachine(
              uid: 0,
              jobId: machineData['JobId'] ?? '',
              documentId: machineData['DocumentId'] ?? '',
              machineId: machineData['MachineId'] ?? '',
              machineName: machineData['MachineName'] ?? '',
              machineType: machineData['MachineType'] ?? '',
              description: machineData['Description'] ?? '',
              specification: machineData['Specification'] ?? '',
              status: int.tryParse(machineData['Status'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
            );
          }).toList();
          return syncedMachines;
        } else {
          throw Exception("Job Machine Sync API response format invalid.");
        }
      } else {
        throw Exception("Job Machine Sync failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error during job machine sync: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred during job machine sync: $e");
    }
  }
}