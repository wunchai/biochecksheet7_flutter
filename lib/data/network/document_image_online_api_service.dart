import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';

class DocumentImageOnlineApiService {
  final String _baseUrl = AppConfig.baseUrl;

  /// 1. Fetch metadata for all images in a document
  Future<List<CheckSheetDocumentImageResponse>> fetchDocumentImageMetadata(String documentId) async {
    final uri = Uri.parse('$_baseUrl/CheckSheet_DocumentImage_Sync');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_DocumentImage_Sync",
      "Paremeter": jsonEncode({"documentid": documentId})
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final bodyJson = json.decode(decodedBody);

        if (bodyJson['Table'] != null && bodyJson['Table'] is List) {
          final List<dynamic> tableList = bodyJson['Table'];
          return tableList
              .map((jsonItem) => CheckSheetDocumentImageResponse.fromJson(jsonItem))
              .toList();
        } else {
          return []; 
        }
      } else {
        throw Exception('Failed to load document image metadata: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching document image metadata: $e');
      rethrow;
    }
  }

  /// 2. Fetch Base64 data for a specific image ID
  Future<String> fetchDocumentImageBase64(int id, String username) async {
    final uri = Uri.parse('$_baseUrl/CheckSheet_DocumentImage_Base64_Sync');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_DocumentImage_Base64_Sync",
      "Paremeter": jsonEncode({"username": username, "id": id})
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final bodyJson = json.decode(decodedBody);

        if (bodyJson['Table'] != null && bodyJson['Table'] is List && bodyJson['Table'].isNotEmpty) {
          final firstRow = bodyJson['Table'][0];
          if (firstRow.containsKey('Picture')) {
            return firstRow['Picture'].toString();
          } else if (firstRow.containsKey('Base64')) {
            return firstRow['Base64'].toString();
          } else {
            for (var key in firstRow.keys) {
              if (firstRow[key] is String && (firstRow[key] as String).length > 100) {
                return firstRow[key] as String;
              }
            }
          }
          return "";
        } else {
          return "";
        }
      } else {
        throw Exception('Failed to load document image base64: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching document image base64: $e');
      rethrow;
    }
  }
}
