import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/checksheet_image_api_service.dart';

class ChecksheetImageRepository {
  final AppDatabase _appDatabase;
  final ChecksheetImageApiService _apiService;

  ChecksheetImageRepository({
    required AppDatabase appDatabase,
    required ChecksheetImageApiService apiService,
  })  : _appDatabase = appDatabase,
        _apiService = apiService;

  /// === ขั้นตอนที่ 1: Sync ข้อมูล Metadata ===
  /// ดึงข้อมูล Text (Metadata) ของรูปภาพจาก Server แล้วบันทึกลง Local DB
  Future<void> syncImageMetadata() async {
    try {
      debugPrint('Starting image metadata sync...');
      final metadataFromApi = await _apiService.getChecksheetImageMetadata();
      debugPrint(
          'Fetched ${metadataFromApi.length} metadata records from API.');

      if (metadataFromApi.isNotEmpty) {
        final companions = metadataFromApi.map((dto) {
          final createDateTime = dto.createDate != null
              ? DateTime.tryParse(dto.createDate!)
              : null;

          return CheckSheetMasterImagesCompanion(
            id: drift.Value(dto.id),
            machineId: drift.Value(dto.machineId),
            jobId: drift.Value(dto.jobId),
            tagId: drift.Value(dto.tagId),
            // PATH จะยังไม่ถูกกำหนดค่าในขั้นตอนนี้
            status: drift.Value(dto.status),
            createDate: drift.Value(createDateTime), // <<< ใช้ค่าที่แปลงแล้ว
            createBy: drift.Value(dto.createBy),
            syncStatus: const drift.Value(1), // 1 = Synced
          );
        }).toList();

        await _appDatabase.checksheetMasterImageDao
            .insertOrUpdateAll(companions);
        debugPrint(
            'Successfully inserted/updated ${companions.length} metadata records into local DB.');
      }
    } catch (e) {
      debugPrint('Error during image metadata sync: $e');
      rethrow;
    }
  }

  /// === ขั้นตอนที่ 2: ดาวน์โหลดรูปภาพที่ยังขาดหายไป ===
  /// ค้นหารูปที่ยังไม่มี Path ใน Local DB แล้วดาวน์โหลดทีละรูป
  Future<void> downloadMissingImages() async {
    try {
      debugPrint('Searching for missing local images...');
      final missingImages =
          await _appDatabase.checksheetMasterImageDao.getRecordsWithNullPath();
      debugPrint('Found ${missingImages.length} images to download.');

      if (missingImages.isEmpty) {
        debugPrint('No missing images to download. Process complete.');
        return;
      }

      for (final imageRecord in missingImages) {
        try {
          // 1. ขอรูปภาพเป็น Base64 จาก API
          final base64String =
              await _apiService.fetchImageAsBase64(imageRecord.id);

          // 2. แปลง Base64 เป็น Binary
          final Uint8List imageBytes = base64Decode(base64String);

          // (ทางเลือก) 3. บีบอัดรูปภาพ (สามารถเพิ่ม Logic ตรงนี้ได้ในอนาคต)
          // final Uint8List compressedBytes = await compressImage(imageBytes);
          final Uint8List compressedBytes =
              imageBytes; // ตอนนี้ใช้ไฟล์เดิมไปก่อน

          // 4. บันทึกไฟล์ลงในเครื่อง
          final String localPath = await _saveImageToLocalFile(
            imageBytes: compressedBytes,
            imageId: imageRecord.id,
          );

          // 5. อัปเดต Path ใน Local DB
          await _appDatabase.checksheetMasterImageDao
              .updateImagePath(imageRecord.id, localPath);
          debugPrint(
              'Successfully downloaded and saved image ID ${imageRecord.id} to path: $localPath');
        } catch (e) {
          debugPrint(
              'Failed to download image ID ${imageRecord.id}. Error: $e');
          // ดำเนินการต่อเพื่อดาวน์โหลดรูปถัดไป
        }
      }
    } catch (e) {
      debugPrint(
          'An error occurred during the downloadMissingImages process: $e');
      rethrow;
    }
  }

  /// Helper: บันทึก Binary data เป็นไฟล์รูปภาพในเครื่อง
  Future<String> _saveImageToLocalFile({
    required Uint8List imageBytes,
    required int imageId,
  }) async {
    // 1. หา Directory สำหรับเก็บข้อมูล
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/master_images');

    // 2. สร้าง Directory ถ้ายังไม่มี
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    // 3. สร้าง Path ของไฟล์ (เช่น /.../master_images/img_123.jpg)
    final filePath = '${imageDir.path}/img_$imageId.jpg';
    final file = File(filePath);

    // 4. เขียนข้อมูลลงไฟล์
    await file.writeAsBytes(imageBytes);

    return filePath;
  }
}
