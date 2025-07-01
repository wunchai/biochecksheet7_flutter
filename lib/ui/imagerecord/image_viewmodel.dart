// lib/ui/imagerecord/image_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart'; // สำหรับ ImageDao
import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart'; // สำหรับ DbImage
import 'package:drift/drift.dart' as drift; // สำหรับ drift.Value

// NEW: Imports for camera and image processing
import 'package:image_picker/image_picker.dart'; // สำหรับถ่ายรูป/เลือกรูป
import 'package:image/image.dart' as img; // สำหรับจัดการรูปภาพ (alias as img)
import 'dart:io'; // สำหรับ File
import 'package:path_provider/path_provider.dart'; // สำหรับ Path
import 'package:path/path.dart' as p; // สำหรับ Path joining
import 'package:uuid/uuid.dart'; // สำหรับสร้าง GUID (UUID)
import 'dart:typed_data'; // <<< NEW: Import for Uint8List
import 'package:flutter/foundation.dart'; // <<< NEW: Import for kIsWeb
import 'dart:convert'; // <<< NEW: Import for base64Encode
// NEW: Import the platform-specific image processor
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart'; // This will conditionally import native or web version


class ImageViewModel extends ChangeNotifier {
  final ImageDao _imageDao;
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker
  final Uuid _uuid = const Uuid(); // Instance of UUID generator
   final ImageProcessor _imageProcessor = ImageProcessor(); // <<< CRUCIAL FIX: Use the factory constructor
  // Parameters passed from DocumentRecordScreen
  String? _documentId;
  String? get documentId => _documentId;
  String? _machineId;
  String? get machineId => _machineId;
  String? _jobId;
  String? get jobId => _jobId;
  String? _tagId; // Tag ID ของ Record ที่เกี่ยวข้องกับรูปภาพ
  String? get tagId => _tagId;

  Stream<List<DbImage>>? _imagesStream; // Stream สำหรับรายการรูปภาพ
  Stream<List<DbImage>>? get imagesStream => _imagesStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusMessage = "กำลังโหลดรูปภาพ...";
  String get statusMessage => _statusMessage;

  String? _syncMessage; // ข้อความสำหรับสถานะการซิงค์รูปภาพ
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  ImageViewModel({required AppDatabase appDatabase})
      : _imageDao = appDatabase.imageDao;

  /// โหลดรูปภาพจาก Local Database ตาม documentId, machineId, jobId, tagId.
  Future<void> loadImages({
    required String documentId,
    required String machineId,
    required String jobId,
    required String tagId,
  }) async {
    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
    _jobId = jobId;
    _tagId = tagId;
    _statusMessage = "กำลังดึงรูปภาพ...";
    notifyListeners();

    try {
      print('ImageViewModel: โหลดรูปภาพสำหรับ DocID=$documentId, MachineID=$machineId, JobID=$jobId, TagID=$tagId');
      _imagesStream = _imageDao.watchImagesForRecord(
        documentId: documentId,
        machineId: machineId,
        jobId: jobId,
        tagId: tagId,
      );
      _statusMessage = "รูปภาพโหลดแล้ว.";
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลดรูปภาพได้: $e";
      print("ข้อผิดพลาดในการโหลดรูปภาพ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh รายการรูปภาพจาก Local Database.
  Future<void> refreshImages() async {
    if (_documentId == null || _machineId == null || _jobId == null || _tagId == null) {
      _syncMessage = "ไม่สามารถ Refresh รูปภาพได้: ID ขาดหาย.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _syncMessage = "กำลัง Refresh รูปภาพ...";
    _statusMessage = "กำลัง Refresh รูปภาพ...";
    notifyListeners();

    try {
      await loadImages(
        documentId: _documentId!,
        machineId: _machineId!,
        jobId: _jobId!,
        tagId: _tagId!,
      );
      _syncMessage = "รูปภาพ Refresh แล้ว!";
    } catch (e) {
      _syncMessage = "ข้อผิดพลาดในการ Refresh รูปภาพ: $e";
      _statusMessage = "ข้อผิดพลาดในการ Refresh รูปภาพ.";
      print("ข้อผิดพลาดในการ Refresh รูปภาพ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Takes a photo using the camera, resizes it, saves it locally, and saves metadata to DB.
  Future<void> takePhotoAndSaveCamera() async {
    if (_documentId == null || _machineId == null || _jobId == null || _tagId == null) {
      _syncMessage = "ไม่สามารถถ่ายรูปได้: ID ขาดหาย (Document/Machine/Job/Tag).";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _syncMessage = "กำลังเปิดกล้อง...";
    _statusMessage = "กำลังถ่ายรูป...";
    notifyListeners();

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo == null) {
        _syncMessage = "ยกเลิกการถ่ายรูป.";
        _statusMessage = "ถ่ายรูปถูกยกเลิก.";
        return;
      }

      _statusMessage = "กำลังประมวลผลรูปภาพ...";
      notifyListeners();

      // 1. Load image from file
      File originalFile = File(photo.path);
      img.Image? image = img.decodeImage(originalFile.readAsBytesSync());

      if (image == null) {
        throw Exception("ไม่สามารถโหลดรูปภาพได้.");
      }

      // 2. Resize image (e.g., to max width 800px, maintaining aspect ratio)
      int targetWidth = 800;
      int targetHeight = (image.height * targetWidth / image.width).round();

      if (image.width > targetWidth) {
        image = img.copyResize(image, width: targetWidth, height: targetHeight);
      }

      // 3. Compress and save to a new local file (e.g., JPEG)
      final directory = await getApplicationDocumentsDirectory();
      final String appSpecificDir = p.join(directory.path, 'biochecksheet_images');
      await Directory(appSpecificDir).create(recursive: true);

      final String uniqueFileName = '${_uuid.v4()}.jpg';
      final String newFilePath = p.join(appSpecificDir, uniqueFileName);
      File newFile = File(newFilePath);
      await newFile.writeAsBytes(img.encodeJpg(image, quality: 85));

      print('รูปภาพถูกบันทึกที่: $newFilePath');

      // 4. Save image metadata to DbImage table
      final newImageEntry = ImagesCompanion(
        guid: drift.Value(_uuid.v4()),
        imageIndex: drift.Value('1'), // You might manage this index later
        picture: const drift.Value(null), // Not storing base64, storing filepath
        imageUri: drift.Value(newFilePath), // Store local file path as URI
        filename: drift.Value(uniqueFileName),
        filepath: drift.Value(newFilePath),
        documentId: drift.Value(_documentId!),
        machineId: drift.Value(_machineId!),
        jobId: drift.Value(_jobId!),
        tagId: drift.Value(_tagId!),
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: const drift.Value(0), // 0 = Local, not yet synced to server
        lastSync: drift.Value(DateTime.now().toIso8601String()),
        statusSync: const drift.Value(0), // 0 = Pending sync
      );

      await _imageDao.insertImage(newImageEntry);
      _syncMessage = "ถ่ายรูปและบันทึกสำเร็จ!";
      _statusMessage = "รูปภาพถูกบันทึกแล้ว.";
      await refreshImages(); // Refresh the list to show the new photo
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการถ่ายรูป/บันทึก: $e";
      _statusMessage = "ถ่ายรูป/บันทึกล้มเหลว.";
      print("Error taking photo and saving: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


/// Takes a photo using the camera, resizes it, saves it locally, and saves metadata to DB.
  Future<void> takePhotoAndSave() async {
    await _processAndSaveImage(ImageSource.camera);
  }

  /// NEW: Picks an image from the gallery/files, resizes it, saves it locally, and saves metadata to DB.
  Future<void> pickImageAndSave() async {
    await _processAndSaveImage(ImageSource.gallery);
  }

  /// Helper method to handle image picking/taking, resizing, local saving, and DB insertion.
  Future<void> _processAndSaveImage(ImageSource source) async {
    if (_documentId == null || _machineId == null || _jobId == null || _tagId == null) {
      _syncMessage = "ไม่สามารถดำเนินการได้: ID ขาดหาย (Document/Machine/Job/Tag).";
      _statusMessage = "ดำเนินการล้มเหลว.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _syncMessage = "กำลังเปิดตัวเลือกรูปภาพ...";
    _statusMessage = "กำลังเลือกรูปภาพ...";
    notifyListeners();

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) {
        _syncMessage = "ยกเลิกการเลือกรูปภาพ.";
        _statusMessage = "การดำเนินการถูกยกเลิก.";
        return;
      }

      _statusMessage = "กำลังประมวลผลรูปภาพ...";
      notifyListeners();

      // CRUCIAL CHANGE: Use the platform-specific ImageProcessor
      final Uint8List? processedBytes = await _imageProcessor.processAndSaveImage(pickedFile);

      if (processedBytes == null || processedBytes.isEmpty) {
        throw Exception("ไม่สามารถประมวลผลรูปภาพได้.");
      }

      // Determine filepath or imageUri based on platform
      String? newFilePath;
      String? newImageUri;
      String uniqueFileName = '${_uuid.v4()}.jpg';

      // For Web, we might store as a data URI or just know it's in memory.
      // For Native, we save to a file and store the path.
      if (kIsWeb) { // Use kIsWeb to check if running on web
        newImageUri = 'data:image/jpeg;base64,${base64Encode(processedBytes)}'; // Store as Data URI
        newFilePath = null; // No file path on web
      } else {
        // For Native, save to file system
        final directory = await getApplicationDocumentsDirectory();
        final String appSpecificDir = p.join(directory.path, 'biochecksheet_images');
        await Directory(appSpecificDir).create(recursive: true);
        newFilePath = p.join(appSpecificDir, uniqueFileName);
        File newFile = File(newFilePath);
        await newFile.writeAsBytes(processedBytes); // Save processed bytes to file
        newImageUri = newFilePath; // URI is the file path
        print('รูปภาพถูกบันทึกที่ (Native): $newFilePath');
      }


      // 4. Save image metadata to DbImage table
      final newImageEntry = ImagesCompanion(
        guid: drift.Value(_uuid.v4()),
        imageIndex: drift.Value('1'),
        picture: kIsWeb ? drift.Value(base64Encode(processedBytes)) : const drift.Value(null), // Store base64 on web
        imageUri: drift.Value(newImageUri), // Store URI (filepath or data URI)
        filename: drift.Value(uniqueFileName),
        filepath: drift.Value(newFilePath), // Filepath only for native
        documentId: drift.Value(_documentId!),
        machineId: drift.Value(_machineId!),
        jobId: drift.Value(_jobId!),
        tagId: drift.Value(_tagId!),
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: const drift.Value(0),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
        statusSync: const drift.Value(0),
      );

      await _imageDao.insertImage(newImageEntry);
      _syncMessage = "รูปภาพถูกบันทึกสำเร็จ!";
      _statusMessage = "รูปภาพถูกบันทึกแล้ว.";
      await refreshImages();
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการประมวลผล/บันทึกรูปภาพ: $e";
      _statusMessage = "ดำเนินการล้มเหลว.";
      print("Error processing and saving image: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NEW: Deletes an image record from the local database and its corresponding file.
  Future<void> deleteImage(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังลบรูปภาพ...";
    notifyListeners();

    try {
      final DbImage? imageToDelete = await _imageDao.getImageByUid(uid);
      if (imageToDelete == null) {
        throw Exception("รูปภาพ UID $uid ไม่พบสำหรับการลบ.");
      }

      // 1. Delete the file from local storage
      if (imageToDelete.filepath != null && imageToDelete.filepath!.isNotEmpty) {
        final file = File(imageToDelete.filepath!);
        if (await file.exists()) {
          await file.delete();
          print('ไฟล์รูปภาพถูกลบแล้ว: ${imageToDelete.filepath}');
        }
      }

      // 2. Delete the record from the database
      await _imageDao.deleteImage(imageToDelete);
      _syncMessage = "ลบรูปภาพสำเร็จ!";
      _statusMessage = "รูปภาพถูกลบแล้ว.";
      await refreshImages(); // Refresh the list after deletion
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการลบรูปภาพ: $e";
      _statusMessage = "ลบรูปภาพล้มเหลว.";
      print("ข้อผิดพลาดในการลบรูปภาพ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Add methods for uploading image to API in Phase 4
}