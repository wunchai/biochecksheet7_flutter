import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/checksheet_image_api_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // <<< เพิ่ม Import

class ChecksheetImageRepository {
  final AppDatabase _appDatabase;
  final ChecksheetImageApiService _apiService;
  final LoginRepository
      _loginRepository; // <<< เพิ่ม Repository สำหรับดึงข้อมูลผู้ใช้

// ฟังก์ชันนี้จะทำงานอยู่เบื้องหลัง ไม่รบกวน UI หลัก
  Future<String> _saveAndOverwriteInIsolate(Map<String, dynamic> params) async {
    // รับข้อมูลที่จำเป็นเข้ามา
    final Uint8List newImageBytes = params['newBytes'];
    final String? oldPath = params['oldPath'];
    // <<< รับ Path หลักของโฟลเดอร์เข้ามา ไม่ต้องหาเอง >>>
    final String baseDirectoryPath = params['basePath'];

    // 1. สร้าง Path ใหม่โดยใช้ Path หลักที่ได้รับมา
    final imageDir = Directory('$baseDirectoryPath/new_master_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final newFilePath = '${imageDir.path}/edited_master_$timestamp.jpg';

    // 2. เขียนไฟล์ใหม่ (งานหนัก)
    final newFile = File(newFilePath);
    await newFile.writeAsBytes(newImageBytes);

    // 3. ลบไฟล์เก่าทิ้ง
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        debugPrint('Could not delete old image file in isolate. Error: $e');
      }
    }

    // 4. คืนค่า Path ใหม่กลับไปให้ Main Thread
    return newFilePath;
  }

  ChecksheetImageRepository({
    required AppDatabase appDatabase,
    required ChecksheetImageApiService apiService,
  })  : _appDatabase = appDatabase,
        _apiService = apiService,
        _loginRepository = LoginRepository();

  /// === ขั้นตอนที่ 1: Sync ข้อมูล Metadata ===
  /// ดึงข้อมูล Text (Metadata) ของรูปภาพจาก Server แล้วบันทึกลง Local DB
  Future<void> syncImageMetadata() async {
    try {
      debugPrint('Starting image metadata sync...');
      final metadataFromApi = await _apiService.getChecksheetImageMetadata();
      debugPrint(
          'Fetched ${metadataFromApi.length} metadata records from API.');

      if (metadataFromApi.isEmpty) {
        return;
      }

      // 1. ดึงข้อมูลรูปภาพทั้งหมดที่มีในเครื่องมาเก็บใน Map เพื่อให้ค้นหาได้เร็ว
      final localImages =
          await _appDatabase.checksheetMasterImageDao.getAllImages();
      final localImageMap = {for (var img in localImages) img.id: img};

      // 2. สร้าง List ของข้อมูลที่จะทำการบันทึก (เฉพาะที่ปลอดภัย)
      final List<CheckSheetMasterImagesCompanion> companionsToUpsert = [];

      for (final dto in metadataFromApi) {
        final localRecord = localImageMap[dto.id];

        // 3. ตรวจสอบเงื่อนไข:
        //    - ถ้าไม่เจอ record ในเครื่องเลย (localRecord == null) -> เป็นข้อมูลใหม่ ให้เพิ่มเข้าไป
        //    - หรือ ถ้าเจอ record แต่ newImage ไม่ใช่ 1 -> เป็นข้อมูลเก่าที่ปลอดภัย สามารถอัปเดตได้
        if (localRecord == null || localRecord.newImage != 1) {
          final createDateTime = dto.createDate != null
              ? DateTime.tryParse(dto.createDate!)
              : null;
          final updatedAtDateTime =
              dto.updatedAt != null ? DateTime.tryParse(dto.updatedAt!) : null;

          companionsToUpsert.add(CheckSheetMasterImagesCompanion(
            id: drift.Value(dto.id),
            machineId: drift.Value(dto.machineId),
            jobId: drift.Value(dto.jobId),
            tagId: drift.Value(dto.tagId),
            status: drift.Value(dto.status),
            createDate: drift.Value(createDateTime),
            createBy: drift.Value(dto.createBy),
            updatedAt: drift.Value(updatedAtDateTime?.toIso8601String()),
            syncStatus: const drift.Value(1),
          ));
        } else {
          // ถ้า newImage == 1, ให้ข้ามการอัปเดตรายการนี้ไป
          debugPrint(
              'Skipping update for image ID ${dto.id} because it has local changes (newImage = 1).');
        }
      }

      // 4. บันทึกเฉพาะข้อมูลที่ผ่านเงื่อนไขแล้วเท่านั้น
      if (companionsToUpsert.isNotEmpty) {
        await _appDatabase.checksheetMasterImageDao
            .insertOrUpdateAll(companionsToUpsert);
        debugPrint(
            'Successfully inserted/updated ${companionsToUpsert.length} metadata records.');
      }
    } catch (e) {
      debugPrint('Error during image metadata sync: $e');
      rethrow;
    }
  }

  /// === ขั้นตอนที่ 2: ดาวน์โหลดรูปภาพที่ยังขาดหายไป ===
  /// ค้นหารูปที่ยังไม่มี Path ใน Local DB แล้วดาวน์โหลดทีละรูป
  ///
  /// === ฟังก์ชันที่แก้ไข: ดาวน์โหลดรูปภาพโดยแยก Logic ตามแพลตฟอร์ม ===
  ///
  Future<void> downloadMissingImages(
      {required Function(int current, int total) onProgress}) async {
    try {
      debugPrint('Searching for missing local images...');
      final missingImages =
          await _appDatabase.checksheetMasterImageDao.getRecordsWithNullPath();

      final total = missingImages.length;
      debugPrint('Found $total images to download.');

      if (total == 0) {
        onProgress(0, 0); // แจ้งว่าไม่มีอะไรต้องทำ
        return;
      }

      if (missingImages.isEmpty) {
        debugPrint('No missing images to download. Process complete.');
        return;
      }
      int current = 0;

      for (final imageRecord in missingImages) {
        current++;
        onProgress(current, total);
        try {
          // 1. ขอรูปภาพเป็น Base64 จาก API
          final base64String =
              await _apiService.fetchImageAsBase64(imageRecord.id);

          // --- <<< จุดที่แก้ไขสำคัญ >>> ---
          if (kIsWeb) {
            // บน Web: บันทึก Base64 string ลงในคอลัมน์ path โดยตรง
            await _appDatabase.checksheetMasterImageDao
                .updateImagePath(imageRecord.id, base64String);
            debugPrint(
                'Successfully saved Base64 for image ID ${imageRecord.id} to local DB.');
          } else {
            // บน Native: แปลง, บันทึกเป็นไฟล์, และอัปเดต path เหมือนเดิม
            final Uint8List imageBytes = base64Decode(base64String);
            final String localPath = await _saveImageToLocalFile(
              imageBytes: imageBytes,
              imageId: imageRecord.id,
            );
            await _appDatabase.checksheetMasterImageDao
                .updateImagePath(imageRecord.id, localPath);
            debugPrint(
                'Successfully downloaded image ID ${imageRecord.id} to path: $localPath');
          }
          // --- <<< สิ้นสุดการแก้ไข >>> ---

/*
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
              */
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

  /// === ฟังก์ชันที่แก้ไข: จัดการการบันทึกรูปที่ถ่ายในแอป (ทั้ง Insert และ Update) ===
  Future<bool> createOrUpdateNewMasterImageRecord({
    required int jobId,
    required int machineId,
    required int tagId,
    required String localPath,
  }) async {
    try {
      final currentUser = _loginRepository.loggedInUser;
      if (currentUser == null || currentUser.userId.isEmpty) {
        throw Exception("ไม่พบข้อมูลผู้ใช้, ไม่สามารถบันทึกรูปภาพได้");
      }

      // --- <<< จุดที่แก้ไขสำคัญ >>> ---
      // 1. ค้นหา record เก่าก่อน เพื่อเอา path ของไฟล์เก่ามาลบ
      final existingRecord =
          await _appDatabase.checksheetMasterImageDao.getImageForTag(
        jobId: jobId,
        machineId: machineId,
        tagId: tagId,
      );
// 2. ถ้ามี record เก่า และมี path ของไฟล์อยู่ ให้ทำการลบไฟล์นั้นทิ้ง
      if (existingRecord != null &&
          existingRecord.path != null &&
          existingRecord.path!.isNotEmpty) {
        try {
          final oldFile = File(existingRecord.path!);
          if (await oldFile.exists()) {
            await oldFile.delete();
            debugPrint(
                'Successfully deleted old image file: ${existingRecord.path}');
          }
        } catch (e) {
          // ถ้าลบไฟล์เก่าไม่สำเร็จ ก็ไม่เป็นไร ให้ดำเนินการต่อ แต่ให้แสดง log ไว้
          debugPrint(
              'Could not delete old image file at ${existingRecord.path}. Error: $e');
        }
      }
      // --- <<< สิ้นสุดการแก้ไข >>> ---

      // เรียกใช้ฟังก์ชัน saveNewLocalImage จาก DAO
      // ซึ่ง DAO จะจัดการเองว่าจะ Insert หรือ Update
      await _appDatabase.checksheetMasterImageDao.saveNewLocalImage(
        jobId: jobId,
        machineId: machineId,
        tagId: tagId,
        localPath: localPath,
        createBy: currentUser.userId, // ส่งชื่อผู้ใช้ปัจจุบันเข้าไป
      );

      debugPrint('Successfully saved/updated local image for TagId: $tagId');
      return true;
    } catch (e) {
      debugPrint('Error in createOrUpdateNewMasterImageRecord: $e');
      return false;
    }
  }

  /// === ฟังก์ชันที่แก้ไข: สร้างไฟล์ใหม่, ลบไฟล์เก่า, และอัปเดตฐานข้อมูล ===
  Future<bool> overwriteMasterImage({
    required DbCheckSheetMasterImage originalImageRecord,
    required Uint8List newImageBytes,
  }) async {
    try {
      final currentUser = _loginRepository.loggedInUser;
      if (currentUser == null || currentUser.userId.isEmpty) {
        throw Exception("ไม่พบข้อมูลผู้ใช้, ไม่สามารถบันทึกรูปภาพได้");
      }

      String newPathOrBase64;

      if (kIsWeb) {
        // --- กรณี Web ---
        newPathOrBase64 = base64Encode(newImageBytes);
      } else {
        /*
        // Android / iOS / Windows: save เป็นไฟล์
        newPathOrBase64 = await _saveImageToPlatformFile(
          newImageBytes,
          originalImageRecord.path,
        );
      }
      */

        /*
        // --- <<< 2. แก้ไขสำหรับ Native (Android, Windows) >>> ---
        // 2.1 หา Path หลักบน Main Thread ก่อน
        final directory = await getApplicationDocumentsDirectory();
        // เตรียมข้อมูลที่จะส่งไปให้ "คนงาน" อีกคน
        // 2.2 เตรียมข้อมูลที่จะส่งไปให้ "คนงาน" อีกคน
        final params = <String, dynamic>{
          'newBytes': newImageBytes,
          'oldPath': originalImageRecord.path,
          'basePath': directory.path, // <<< ส่ง Path หลักไปด้วย
        };
        newPathOrBase64 = await compute(_saveAndOverwriteInIsolate, params);
      }
      */

        // 2. ลบไฟล์เก่าทิ้ง (หลังจากสร้างไฟล์ใหม่สำเร็จแล้ว)

        newPathOrBase64 = await _saveImageBytesToNewFile(newImageBytes);

        final oldPath = originalImageRecord.path;
        if (oldPath != null && oldPath.isNotEmpty) {
          try {
            final oldFile = File(oldPath);
            if (await oldFile.exists()) {
              await oldFile.delete();
              debugPrint('Successfully deleted old image file: $oldPath');
            }
          } catch (e) {
            debugPrint(
                'Could not delete old image file at $oldPath. Error: $e');
          }
        }
      }

      // 3. อัปเดตระเบียนข้อมูลในฐานข้อมูลด้วย Path/Base64 ใหม่
      final companion = CheckSheetMasterImagesCompanion(
        path: drift.Value(newPathOrBase64),
        createBy: drift.Value(currentUser.userId),
        newImage: const drift.Value(1),
        syncStatus: const drift.Value(0),
        updatedAt: drift.Value(DateTime.now().toIso8601String()),
      );

      final result =
          await (_appDatabase.update(_appDatabase.checkSheetMasterImages)
                ..where((tbl) => tbl.id.equals(originalImageRecord.id)))
              .write(companion);

      debugPrint(
          'Successfully updated image record ID: ${originalImageRecord.id}. Rows affected: $result');
      return result > 0;
    } catch (e) {
      debugPrint('Error in overwriteMasterImage: $e');
      return false;
    }
  }

  Future<String> _saveImageToPlatformFile(Uint8List bytes,
      [String? oldPath]) async {
    final dir = await _getAppDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '${dir.path}/edited_master_$timestamp.jpg';
    final file = File(path);

    await file.writeAsBytes(bytes);

    // ลบไฟล์เก่า
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) await oldFile.delete();
      } catch (e) {
        debugPrint('Failed to delete old file at $oldPath: $e');
      }
    }

    return path;
  }

  /// ===== Helper: Path สำหรับ Windows =====

  /// Helper: หา Directory สำหรับเก็บไฟล์บนแต่ละแพลตฟอร์ม
  Future<Directory> _getAppDirectory() async {
    if (kIsWeb) {
      throw UnimplementedError('Web does not use filesystem');
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final dir = Directory('$userProfile/Documents/new_master_images');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      } else {
        throw Exception('Cannot find Windows Documents folder');
      }
    } else {
      // Android / iOS
      return await getApplicationDocumentsDirectory();
    }
  }

  /// ===== Helper: บันทึกไฟล์ใหม่ และลบไฟล์เก่า =====
  Future<String> _saveImageToFile(Uint8List bytes, [String? oldPath]) async {
    final dir = await _getAppDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '${dir.path}/edited_master_$timestamp.jpg';
    final file = File(path);

    await file.writeAsBytes(bytes);

/*
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) await oldFile.delete();
      } catch (e) {
        debugPrint('Failed to delete old file at $oldPath: $e');
      }
    }

*/

    return path;
  }

  /// Helper: สำหรับบันทึก Byte Array ลงไฟล์ใหม่และคืนค่า Path
  Future<String> _saveImageBytesToNewFile(Uint8List imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/new_master_images');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final filePath = '${imageDir.path}/edited_master_$timestamp.jpg';
    final file = File(filePath);
    debugPrint('filePath ${filePath}: ');

    await file.writeAsBytes(imageBytes);
    return filePath;
  }

/*
  /// อัปโหลดรูปภาพใหม่ (newImage = 1) ขึ้น Server
  Future<void> uploadNewMasterImages() async {
    try {
      final imagesToUpload =
          await _appDatabase.checksheetMasterImageDao.getImagesToUpload();
      debugPrint('Found ${imagesToUpload.length} new master images to upload.');

      for (final imageRecord in imagesToUpload) {
        try {
          if (imageRecord.path == null || imageRecord.path!.isEmpty) {
            debugPrint(
                'Skipping image ID ${imageRecord.id}: path is null or empty.');
            continue;
          }

          final imageFile = File(imageRecord.path!);
          if (!await imageFile.exists()) {
            debugPrint(
                'Skipping image ID ${imageRecord.id}: file does not exist at ${imageRecord.path}.');
            continue;
          }

          final success =
              await _apiService.uploadNewMasterImage(imageRecord, imageFile);

          if (success) {
            // (ทางเลือก) อัปเดตสถานะใน Local DB หลังจาก Upload สำเร็จ
            // เช่น ตั้ง newImage = 0 และ syncStatus = 1
          }
        } catch (e) {
          debugPrint('Failed to upload image ID ${imageRecord.id}. Error: $e');
        }
      }
    } catch (e) {
      debugPrint(
          'An error occurred during the uploadNewMasterImages process: $e');
      rethrow;
    }
  }

  */

  /// === ฟังก์ชันที่แก้ไข: เพิ่มการรายงานความคืบหน้า และอัปเดตสถานะหลังอัปโหลด ===
  Future<void> uploadNewMasterImages(
      {required Function(int current, int total) onProgress}) async {
    try {
      final imagesToUpload =
          await _appDatabase.checksheetMasterImageDao.getImagesToUpload();
      final total = imagesToUpload.length;
      debugPrint('Found $total new master images to upload.');

      if (total == 0) {
        onProgress(0, 0); // แจ้งว่าไม่มีอะไรต้องทำ
        return;
      }

      int current = 0;
      for (final imageRecord in imagesToUpload) {
        current++;
        // --- <<< รายงานความคืบหน้าก่อนเริ่มอัปโหลด >>> ---
        onProgress(current, total);

        try {
          if (imageRecord.path == null || imageRecord.path!.isEmpty) continue;
          final imageFile = File(imageRecord.path!);
          if (!await imageFile.exists()) continue;

          final success =
              await _apiService.uploadNewMasterImage(imageRecord, imageFile);

          if (success) {
            // --- <<< อัปเดตสถานะใน Local DB หลังจาก Upload สำเร็จ >>> ---
            await _appDatabase.checksheetMasterImageDao
                .updateStatusAfterUpload(imageRecord.id);
            debugPrint(
                'Successfully uploaded and updated status for image ID ${imageRecord.id}');
          }
        } catch (e) {
          debugPrint('Failed to upload image ID ${imageRecord.id}. Error: $e');
        }
      }
    } catch (e) {
      debugPrint('An error occurred during uploadNewMasterImages: $e');
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
