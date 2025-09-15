import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';

class ChecksheetImageApiService {
  // ไม่ต้องมี http.Client ใน Constructor แล้ว
  ChecksheetImageApiService();

  final String _baseUrl = AppConfig.baseUrl;

  /// 1. ดึงข้อมูล Metadata ของรูปภาพทั้งหมด
  Future<List<CheckSheetMasterImageResponse>>
      getChecksheetImageMetadata() async {
    final uri = Uri.parse('$_baseUrl/CheckSheet_MasterImage_Sync');
    debugPrint("Syncing Master Image with URL: $uri");

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterImage_Sync",
      "Paremeter": jsonEncode({"username": "000000"})
    });

    try {
      // เรียกใช้ http.post โดยตรง
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final bodyJson = json.decode(decodedBody);

        if (bodyJson['Table'] != null && bodyJson['Table'] is List) {
          final List<dynamic> data = bodyJson['Table'];
          return data
              .map((jsonItem) =>
                  CheckSheetMasterImageResponse.fromJson(jsonItem))
              .toList();
        } else {
          return []; // คืนค่า List ว่างหากไม่มี Key "Table"
        }
      } else {
        throw Exception(
            'Failed to load image metadata: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching image metadata: $e');
      rethrow;
    }
  }

  /// 2. ขอข้อมูลรูปภาพ 1 รูปเป็น Base64 String
  Future<String> fetchImageAsBase64(int imageId) async {
    final uri = Uri.parse('$_baseUrl/CheckSheet_MasterImage_Base64_Sync');

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterImage_Base64_Sync",
      "Paremeter":
          jsonEncode({"username": "000000", "id": imageId}) // ส่ง id ไปด้วย
    });

    try {
      // เรียกใช้ http.post โดยตรง
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final bodyJson = json.decode(decodedBody);

        if (bodyJson['Table'] != null &&
            bodyJson['Table'] is List &&
            (bodyJson['Table'] as List).isNotEmpty) {
          // ดึงค่า Base64 จาก Key 'Base64' (อาจจะต้องแก้ชื่อ Key ให้ตรงกับ API)
          final String? base64Image = bodyJson['Table'][0]['Base64'];
          if (base64Image != null && base64Image.isNotEmpty) {
            return base64Image;
          } else {
            throw Exception(
                'API returned empty or null base64 string for image ID: $imageId');
          }
        } else {
          throw Exception('No data returned from API for image ID: $imageId');
        }
      } else {
        throw Exception(
            'Failed to fetch image (ID: $imageId): ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching base64 image: $e');
      rethrow;
    }
  }
}
