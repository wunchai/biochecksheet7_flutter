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
    List<DbJobTag> allSyncedTags = [];
    int pageIndex = 1;
    const int pageSize = 10;
    bool hasMoreData = true;

    print("Starting batched job tag sync...");

    while (hasMoreData) {
      final uri = Uri.parse("$_baseUrl/CHECKSHEET_MASTERTAG_PAGED_SYNC");
      print("Syncing job tags page $pageIndex");

      final body = jsonEncode({
        'userId': '000000',
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
      });

      try {
        final response = await http.post(uri,
            headers: {'Content-Type': 'application/json'}, body: body);

        final String decodedBody = utf8.decode(response.bodyBytes);
        // print("Job Sync API Response (Page $pageIndex): $decodedBody");

        if (response.statusCode == 200) {
          // print("#################################");
          // print(decodedBody);

          final Map<String, dynamic> responseJson = jsonDecode(decodedBody);

          if (responseJson['Jobs'] != null) {
            final String jobsJsonString = responseJson['Jobs'];
            final dynamic decodedJobs = jsonDecode(jobsJsonString);

            if (decodedJobs is List) {
              final List<dynamic> tagList = decodedJobs;

              if (tagList.isEmpty) {
                hasMoreData = false;
                break;
              }

              final List<DbJobTag> syncedTags = tagList.map((tagData) {
                final String? originalQueryStr = tagData['QueryStr'];
                final String? driftCompatibleQueryStr = originalQueryStr != null
                    ? _convertToDriftSql(originalQueryStr)
                    : null;

                return DbJobTag(
                  uid: 0,
                  machineId: tagData['MachineId']?.toString() ?? '',
                  jobId: tagData['JobId']?.toString() ?? '',
                  tagId: tagData['TagId']?.toString() ?? '',
                  tagName: tagData['TagName'] ?? '',
                  tagType: tagData['TagType'] ?? '',
                  tagGroupId: tagData['TagGroupId']?.toString() ?? '',
                  tagGroupName: tagData['TagGroupName'] ?? '',
                  description: tagData['Description'] ?? '',
                  specification: tagData['Specification'] ?? '',
                  specMin: tagData['SpecMin']?.toString() ?? '',
                  specMax: tagData['SpecMax']?.toString() ?? '',
                  unit: tagData['Unit'] ?? '',
                  queryStr: originalQueryStr,
                  status: int.tryParse(tagData['Status'].toString()) ?? 0,
                  lastSync: DateTime.now().toIso8601String(),
                  note: tagData['Note'] ?? '',
                  value: tagData['Value']?.toString() ?? '',
                  remark: tagData['Remark'] ?? '',
                  createDate: tagData['CreateDate'] ?? '',
                  createBy: tagData['CreateBy'] ?? '',
                  valueType: tagData['ValueType'] ?? '',
                  tagSelectionValue: tagData['TagSelectionValue'] ?? '',
                  orderId: tagData['OrderId']?.toString(), // NEW: Map OrderId
                  driftQueryStr: driftCompatibleQueryStr,
                );
              }).toList();

              allSyncedTags.addAll(syncedTags);
              print("Fetched ${syncedTags.length} tags from page $pageIndex");

              if (syncedTags.length < pageSize) {
                hasMoreData = false;
              } else {
                pageIndex++;
              }
            } else {
              hasMoreData = false;
            }
          } else {
            // Handle case where Jobs is null
            hasMoreData = false;
          }
        } else {
          throw Exception(
              "Job Tag Sync failed: Status code ${response.statusCode}");
        }
      } on http.ClientException catch (e) {
        print("Network error during job tag sync page $pageIndex: ${e}");
        throw Exception("Network error during job tag sync: ${e.message}");
      } catch (e) {
        print(
            "An unexpected error occurred during job tag sync page $pageIndex: $e");
        throw Exception("An unexpected error occurred during job tag sync: $e");
      }
    }

    print("Total job tags fetched: ${allSyncedTags.length}");
    return allSyncedTags;
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
