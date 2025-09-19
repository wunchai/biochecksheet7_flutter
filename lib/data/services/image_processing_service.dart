import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service ที่จัดการ Logic ที่ซับซ้อนเกี่ยวกับการเลือก, ประมวลผล, และบันทึกรูปภาพ
class ImageProcessingService {
  final ImagePicker _picker = ImagePicker();

  /// เปิดกล้องให้ผู้ใช้ถ่ายรูป, ลดขนาด, บีบอัด, และบันทึกลงเครื่อง
  ///
  /// คืนค่าเป็น `String` ซึ่งอาจจะเป็น
  /// - File path (สำหรับ Native)
  /// - Base64 string (สำหรับ Web)
  /// - `null` หากผู้ใช้ยกเลิก
  Future<String?> pickAndProcessImage(
      {ImageSource source = ImageSource.camera}) async {
    XFile? pickedFile; // ประกาศตัวแปรไว้นอก try
    try {
      // 1. เปิดกล้อง (หรือคลังภาพ) เพื่อให้ผู้ใช้เลือกรูป
      pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // ลดคุณภาพเบื้องต้นก่อน
        maxWidth: 1920, // กำหนดขนาดสูงสุดเพื่อลดการใช้หน่วยความจำ
      );

      if (pickedFile == null) {
        debugPrint('User cancelled image picking.');
        return null; // ผู้ใช้กดยกเลิก
      }

      // 2. อ่านข้อมูลรูปภาพเป็น bytes
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      // 3. ลดขนาดและบีบอัดรูปภาพโดยใช้ package 'image'
      // ใช้ compute เพื่อย้ายการประมวลผลหนักๆ ไปที่ Isolate อื่น ป้องกัน UI ค้าง
      final Uint8List processedBytes =
          await compute(_resizeAndCompressImage, imageBytes);

      // --- <<< จุดที่แก้ไขสำคัญ >>> ---
      // บน Web, เราไม่สามารถบันทึกไฟล์และรับ path กลับมาได้
      // เราจะข้ามขั้นตอนนี้ไป และปล่อยให้ ViewModel จัดการกับข้อมูลที่ไม่มี path
      if (kIsWeb) {
        // สำหรับ Web, เราจะคืนค่าเป็น Base64 string กลับไปโดยตรง
        debugPrint(
            "Web platform detected: Returning processed image as Base64 string.");
        return base64Encode(processedBytes);
      } else {
        // สำหรับ Native, บันทึกเป็นไฟล์และคืนค่า path กลับไปเหมือนเดิม
        final String filePath = await _saveImageToLocalFile(processedBytes);
        debugPrint('Image processed and saved to: $filePath');
        return filePath;
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      rethrow; // ส่งต่อ error ให้ ViewModel จัดการ
    } finally {
      // --- <<< จุดที่แก้ไขสำคัญ >>> ---
      // 5. ลบไฟล์ชั่วคราวใน /cache ทิ้งเสมอ ไม่ว่าจะสำเร็จหรือไม่
      // --- <<< จุดที่แก้ไขสำคัญ >>> ---
      // จะทำการลบไฟล์ชั่วคราว ก็ต่อเมื่อเป็น Native Platform และแหล่งที่มาคือกล้องเท่านั้น
      if (!kIsWeb && pickedFile != null && source == ImageSource.camera) {
        try {
          final tempFile = File(pickedFile.path);
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint(
                'Successfully deleted temporary camera file from cache: ${pickedFile.path}');
          }
        } catch (e) {
          debugPrint('Could not delete temporary camera file. Error: $e');
        }
      }
    }
  }

  /// Helper: บันทึก Binary data เป็นไฟล์รูปภาพในเครื่อง
  Future<String> _saveImageToLocalFile(Uint8List imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/new_master_images');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    // สร้างชื่อไฟล์ที่ไม่ซ้ำกันโดยใช้ timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final filePath = '${imageDir.path}/new_master_$timestamp.jpg';
    final file = File(filePath);

    await file.writeAsBytes(imageBytes);
    return filePath;
  }
}

/// ฟังก์ชัน Top-level สำหรับใช้กับ `compute` เพื่อย้ายการประมวลผลไป Isolate อื่น
/// รับข้อมูลรูปภาพดิบ, ลดขนาด, และบีบอัดเป็น Jpeg
Uint8List _resizeAndCompressImage(Uint8List originalBytes) {
  // Decode a JPEG image from the raw bytes
  final img.Image? originalImage = img.decodeImage(originalBytes);

  if (originalImage == null) {
    // ไม่สามารถ decode รูปได้, คืนค่าเดิมกลับไป
    return originalBytes;
  }

  // ลดขนาดรูปภาพให้มีความกว้างสูงสุด 1024px (สัดส่วนจะถูกรักษาไว้)
  final img.Image resizedImage = img.copyResize(
    originalImage,
    width: 1024,
  );

  // Encode the resized image back to a JPEG format with a specific quality
  // คุณภาพ 75 เป็นค่าที่สมดุลระหว่างขนาดและคุณภาพ
  return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 75));
}
