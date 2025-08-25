// lib/data/network/document_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // สำหรับ DbDocument

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class DocumentApiService {
  Future<List<DbDocument>> syncDocuments() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterDocument_Sync");
    print("Syncing documents with URL: $uri");
    final headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> parameterObject = {
      "username": "000000"
      // ถ้ามี Password ก็เพิ่ม Password: "your_password"
    };
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterDocument_Sync",
      "Paremeter":
          jsonEncode(parameterObject) // Assuming this parameter is used
    });
    print("Request body: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Response status code: ${response.statusCode}");
      print("Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> documentList = responseJson['Table'];
          final List<DbDocument> syncedDocuments = documentList.map((docData) {
            return DbDocument(
              uid: 0,
              documentId:
                  docData['DocumentId']?.toString() ?? '', // Convert to String
              jobId: docData['JobId']?.toString() ?? '', // Convert to String
              documentName: docData['DocumentName'] ?? '',
              userId: docData['UserId'] ?? '',
              createDate: docData['CreateDate'] ?? '',
              status: int.tryParse(docData['Status'].toString()) ?? 0,
              lastSync: DateTime.now().toIso8601String(),
            );
          }).toList();
          return syncedDocuments;
        } else {
          throw Exception("Document Sync API response format invalid.");
        }
      } else {
        throw Exception(
            "Document Sync failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error during document sync: ${e.message}");
      throw Exception("Network error during document sync: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred during document sync: $e");
      throw Exception("An unexpected error occurred during document sync: $e");
    }
  }
}
