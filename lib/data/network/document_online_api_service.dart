// lib/data/network/document_online_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For DbDocumentOnline

class DocumentOnlineApiService {
  Future<List<DbDocumentOnline>> fetchDocumentOnline({
    required String userId,
    required String jobId,
    required String start,
    required String stop,
    String pageIndex = "1",
    String pageSize = "20",
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_DOCUMENONLINE_SYNC');

    final body = {
      "userId": userId,
      "jobId": jobId,
      "start": start,
      "stop": stop,
      "pageIndex": pageIndex,
      "pageSize": pageSize,
    };

    try {
      print('DocumentOnlineApiService: Fetching from $url');
      print('Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('DocumentOnlineApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extracted nested JSON array string
        final String jobsString = responseData['Jobs'] ?? '[]';
        final List<dynamic> jsonList = jsonDecode(jobsString);
        
        print('DocumentOnlineApiService: Fetched ${jsonList.length} records.');

        // Map the JSON response to proper DbDocumentOnline (using DocumentOnlinesCompanion for mapping intermediate or manual mapping)
        return jsonList.map((json) {
          return DbDocumentOnline(
            uid: 0, // auto generated
            documentId: json['DocumentId']?.toString(),
            jobId: json['JobId']?.toString(),
            documentName: json['DocumentName']?.toString(),
            userId: json['CreateBy']?.toString(),
            createDate: json['CreateDate']?.toString(),
            status: json['Status'] is int
                ? json['Status']
                : int.tryParse(json['Status']?.toString() ?? '0') ?? 0,
            lastSync: json['SyncDate']?.toString() ?? DateTime.now().toIso8601String(),
            updatedAt: null,
          );
        }).toList();
      } else {
        print('Failed to fetch DocumentOnline sync. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
        // Or throw Exception('Failed to load online documents');
      }
    } catch (e) {
      print('Exception during fetch DocumentOnline sync: $e');
      throw Exception('Exception during fetch DocumentOnline sync: $e');
    }
  }
}
