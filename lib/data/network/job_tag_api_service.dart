// lib/data/network/job_tag_api_service.dart
import 'dart:convert';
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // สำหรับ DbJobTag

//const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";
final String _baseUrl = AppConfig.baseUrl;

class JobTagApiService {
  Future<List<DbJobTag>> syncJobTags() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterTag_Sync");
    print("Syncing job tags with URL: $uri");
    final headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> parameterObject = {
      "username": "000000"
      // ถ้ามี Password ก็เพิ่ม Password: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterTag_Sync",
      "Paremeter": jsonEncode(parameterObject) // <<< แก้ไขตรงนี้
    });
    print("Request body: $body");
    try {
      final response = await http.post(uri, headers: headers, body: body);

      final String decodedBody =
          utf8.decode(response.bodyBytes); // <<< แก้ไขตรงนี้
      print(
          "Job Sync API Response: $decodedBody"); // Debugging log with decoded body

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> tagList = responseJson['Table'];
          final List<DbJobTag> syncedTags = tagList.map((tagData) {
            // Original query string from API
            final String? originalQueryStr = tagData['QueryStr'];
            // Convert original query string to drift-compatible snake_case SQL
            final String? driftCompatibleQueryStr = originalQueryStr != null
                ? _convertToDriftSql(originalQueryStr) // Call helper function
                : null;

            return DbJobTag(
              uid: 0,
              machineId: tagData['MachineId']?.toString() ??
                  '', // Convert int to String
              jobId:
                  tagData['JobId']?.toString() ?? '', // Convert int to String
              tagId:
                  tagData['TagId']?.toString() ?? '', // Convert int to String
              tagName: tagData['TagName'] ?? '',
              tagType: tagData['TagType'] ?? '',
              tagGroupId: tagData['TagGroupId']?.toString() ??
                  '', // Convert int to String
              tagGroupName: tagData['TagGroupName'] ?? '',
              description: tagData['Description'] ?? '',
              specification: tagData['Specification'] ?? '',
              specMin: tagData['SpecMin']?.toString() ??
                  '', // Convert double to String
              specMax: tagData['SpecMax']?.toString() ??
                  '', // Convert double to String
              unit: tagData['Unit'] ?? '',
              //queryStr: tagData['QueryStr'] ?? '',
              queryStr: originalQueryStr, // Store original query string
              status: int.tryParse(tagData['Status'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
              note: tagData['Note'] ?? '',
              value: tagData['Value']?.toString() ??
                  '', // Convert to String, handle null
              remark: tagData['Remark'] ?? '',
              createDate: tagData['CreateDate'] ?? '',
              createBy: tagData['CreateBy'] ?? '',
              valueType: tagData['ValueType'] ?? '',
              tagSelectionValue: tagData['TagSelectionValue'] ?? '',
              driftQueryStr:
                  driftCompatibleQueryStr, // <<< NEW: Store drift-compatible SQL
            );
          }).toList();
          return syncedTags;
        } else {
          throw Exception("Job Tag Sync API response format invalid.");
        }
      } else {
        throw Exception(
            "Job Tag Sync failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error during job tag sync: ${e}");
      throw Exception("Network error during job tag sync: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred during job tag sync: $e");
      throw Exception("An unexpected error occurred during job tag sync: $e");
    }
  }

  // Helper function to convert SQL from camelCase to snake_case for drift
  // This is a simplified conversion. For complex SQL, a robust parser might be needed.
  String _convertToDriftSql(String sql) {
    // Example: Replace table names
    sql = sql.replaceAll('documentRecord', 'document_records');
    sql =
        sql.replaceAll('jobTag', 'job_tags'); // if jobTag table is used in SQL

    // Example: If original SQL had 'a.DocumentId' and Db has 'documentId'
    sql = sql.replaceAll('a.DocumentId', 'a.documentId');
    sql = sql.replaceAll('b.DocumentId', 'b.documentId');
    sql = sql.replaceAll('a.MachineId', 'a.machineId');
    sql = sql.replaceAll('b.MachineId', 'b.machineId');
    sql = sql.replaceAll('a.TagName', 'a.tagName');
    sql = sql.replaceAll('b.TagName', 'b.tagName');
    sql = sql.replaceAll('a.Value', 'a.value'); // Also for 'Value' column
    sql = sql.replaceAll('b.Value', 'b.value');

    // Add more replacements as needed for other tables/columns used in your SQL queries
    // e.g., 'JobId' -> 'job_id', 'MachineId' -> 'machine_id', etc.
    return sql;
  }
}
