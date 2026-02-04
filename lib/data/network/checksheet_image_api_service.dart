import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbCheckSheetMasterImage

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

  /// === ฟังก์ชันใหม่: อัปโหลดรูปภาพใหม่ขึ้น Server ===
  /// ใช้ multipart/form-data เพื่อส่งไฟล์ Binary และข้อมูล Text
  Future<bool> uploadNewMasterImage(
    DbCheckSheetMasterImage imageRecord, {
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/api/CheckSheet_MasterImage_Upload'); // <<< Endpoint ใหม่สำหรับ Upload
    debugPrint("Uploading new master image for TagId: ${imageRecord.tagId}");

    try {
      // 1. สร้าง Multipart Request
      var request = http.MultipartRequest('POST', uri);

      // 2. เพิ่มข้อมูล Text Fields
      request.fields['JobId'] = imageRecord.jobId.toString();
      request.fields['MachineId'] = imageRecord.machineId.toString();
      request.fields['TagId'] = imageRecord.tagId.toString();
      request.fields['CreateBy'] = imageRecord.createBy ?? 'unknown';
      // Server สามารถใช้ CreateDate จากตอนที่ได้รับข้อมูลได้เลย หรือจะส่งจาก Client ก็ได้
      request.fields['CreateDate'] =
          imageRecord.createDate?.toIso8601String() ??
              DateTime.now().toIso8601String();

      // 3. เพิ่มไฟล์รูปภาพ
      if (kIsWeb) {
        // กรณี Web: ใช้ imageBytes
        if (imageBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: 'upload_image.jpg', // ตั้งชื่อไฟล์หลอกๆ
            ),
          );
        } else {
          throw Exception("Image bytes are required for Web upload");
        }
      } else {
        // กรณี Native: ใช้ imageFile หรือ imageBytes ก็ได้
        if (imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image', // ชื่อ field ของไฟล์ (คุยกับฝั่ง Server)
              imageFile.path,
            ),
          );
        } else if (imageBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: 'upload_image.jpg',
            ),
          );
        } else {
          throw Exception("Image file or bytes are required for upload");
        }
      }

      // 4. ส่ง Request
      var response = await request.send();

      // 5. ตรวจสอบผลลัพธ์
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Image upload successful for TagId: ${imageRecord.tagId}');
        // final responseBody = await response.stream.bytesToString();
        // debugPrint('Server response: $responseBody');
        return true;
      } else {
        debugPrint('Image upload failed with status: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        debugPrint('Error response: $responseBody');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading new master image: $e');
      rethrow;
    }
  }
}
