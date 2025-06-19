// lib/data/network/job_tag_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // สำหรับ DbJobTag

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class JobTagApiService {
  Future<List<DbJobTag>> syncJobTags() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterJobTag_Sync");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterJobTag_Sync",
      "Paremeter": {} // Assuming no parameters
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> tagList = responseJson['Table'];
          final List<DbJobTag> syncedTags = tagList.map((tagData) {
            return DbJobTag(
              uid: 0,
              tagId: tagData['TagId'] ?? '',
              jobId: tagData['JobId'] ?? '',
              tagName: tagData['TagName'] ?? '',
              tagType: tagData['TagType'] ?? '',
              tagGroupId: tagData['TagGroupId'] ?? '',
              tagGroupName: tagData['TagGroupName'] ?? '',
              description: tagData['Description'] ?? '',
              specification: tagData['Specification'] ?? '',
              specMin: tagData['SpecMin'] ?? '',
              specMax: tagData['SpecMax'] ?? '',
              unit: tagData['Unit'] ?? '',
              queryStr: tagData['QueryStr'] ?? '',
              status: int.tryParse(tagData['Status'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
            );
          }).toList();
          return syncedTags;
        } else {
          throw Exception("Job Tag Sync API response format invalid.");
        }
      } else {
        throw Exception("Job Tag Sync failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error during job tag sync: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred during job tag sync: $e");
    }
  }
}