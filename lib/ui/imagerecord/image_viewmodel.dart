// lib/ui/imagerecord/image_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart';
import 'package:drift/drift.dart' as drift;

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data'; // สำหรับ Uint8List
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb
import 'dart:convert'; // สำหรับ base64Encode

// CRUCIAL FIX: Re-add these imports for file system access on Native platforms
import 'dart:io'; // <<< NEW: สำหรับ File
import 'package:path_provider/path_provider.dart'; // <<< NEW: สำหรับ getApplicationDocumentsDirectory
import 'package:path/path.dart' as p; // <<< NEW: สำหรับ path.join
// NEW: Import the platform-specific image processor
import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart';

class ImageViewModel extends ChangeNotifier {
  final ImageDao _imageDao;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final ImageProcessor
      _imageProcessor; // <<< CRUCIAL FIX: Make it a final parameter

  // Parameters passed from DocumentRecordScreen
  String? _documentId;
  String? get documentId => _documentId;
  String? _machineId;
  String? get machineId => _machineId;
  String? _jobId;
  String? get jobId => _jobId;
  String? _tagId; // Tag ID ของ Record ที่เกี่ยวข้องกับรูปภาพ
  String? get tagId => _tagId;
  String? _problemId; // <<< NEW: Problem ID
  String? get problemId => _problemId;

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

  ImageViewModel(
      {required AppDatabase appDatabase,
      required ImageProcessor
          imageProcessor}) // <<< CRUCIAL FIX: Add imageProcessor to constructor
      : _imageDao = appDatabase.imageDao,
        _imageProcessor = imageProcessor; // <<< Initialize it from parameter

  /// โหลดรูปภาพจาก Local Database ตาม documentId, machineId, jobId, tagId.
  Future<void> loadImages({
    required String documentId,
    required String machineId,
    required String jobId,
    required String tagId,
    String? problemId, // <<< NEW: Optional problemId
  }) async {
    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
    _jobId = jobId;
    _tagId = tagId;
     _problemId = problemId; // Store problemId
    _statusMessage = "กำลังดึงรูปภาพ...";
    notifyListeners();

    try {
       print('ImageViewModel.loadImages: Loading images for DocID=$documentId, MachineID=$machineId, JobID=$jobId, TagID=$tagId, ProblemID=$problemId'); // <<< Debugging
     
      _imagesStream = _imageDao.watchImagesForRecord(
        documentId: documentId,
        machineId: machineId,
        jobId: jobId,
        tagId: tagId,
        problemId: problemId, // Pass problemId to DAO
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
    if (_documentId == null ||
        _machineId == null ||
        _jobId == null ||
        _tagId == null) {
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
        problemId: _problemId, // Pass stored problemId
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
  Future<void> takePhotoAndSave() async {
    await _processAndSaveImage(ImageSource.camera);
  }

  /// Picks an image from the gallery/files, resizes it, saves it locally, and saves metadata to DB.
  Future<void> pickImageAndSave() async {
    await _processAndSaveImage(ImageSource.gallery);
  }

  /// Helper method to handle image picking/taking, resizing, local saving, and DB insertion.
  Future<void> _processAndSaveImage(ImageSource source) async {
    if (_documentId == null ||
        _machineId == null ||
        _jobId == null ||
        _tagId == null) {
      _syncMessage =
          "ไม่สามารถดำเนินการได้: ID ขาดหาย (Document/Machine/Job/Tag).";
      _statusMessage = "ดำเนินการล้มเหลว.";
      notifyListeners();
      return;
    }

 // Check if problemId is needed for this context (if coming from ProblemScreen)
    if (_problemId == null && _tagId == null) { // Or if you want to enforce problemId when it's a problem image
        _syncMessage = "ไม่สามารถดำเนินการได้: Problem ID หรือ Tag ID ขาดหาย.";
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

      // Use the platform-specific ImageProcessor to process and get bytes.
      final Uint8List? processedBytes =
          await _imageProcessor.processAndSaveImage(pickedFile);

      if (processedBytes == null || processedBytes.isEmpty) {
        throw Exception("ไม่สามารถประมวลผลรูปภาพได้.");
      }

      String? newFilePath;
      String? newImageUri;
      String uniqueFileName = '${_uuid.v4()}.jpg';

      if (kIsWeb) {
        // Check if running on web
        newImageUri =
            'data:image/jpeg;base64,${base64Encode(processedBytes)}'; // Store as Data URI
        newFilePath = null; // No file path on web
      } else {
        // For Native, save to file system
        final directory = await getApplicationDocumentsDirectory();
        final String appSpecificDir =
            p.join(directory.path, 'biochecksheet_images');
        await Directory(appSpecificDir)
            .create(recursive: true); // Ensure directory exists
        newFilePath = p.join(appSpecificDir, uniqueFileName);
        File newFile = File(newFilePath);
        await newFile
            .writeAsBytes(processedBytes); // Save processed bytes to file
        newImageUri = newFilePath; // URI is the file path
        print('รูปภาพถูกบันทึกที่ (Native): $newFilePath');
      }
    print('ImageViewModel._processAndSaveImage: Saving image with ProblemID: "${_problemId}"'); // <<< Debugging

      // Save image metadata to DbImage table
      final newImageEntry = ImagesCompanion(
        guid: drift.Value(_uuid.v4()),
        imageIndex: drift.Value('1'), // You might manage this index later
        picture: kIsWeb
            ? drift.Value(base64Encode(processedBytes))
            : const drift.Value(null), // Store base64 on web
        imageUri: drift.Value(newImageUri), // Store URI (filepath or data URI)
        filename: drift.Value(uniqueFileName),
        filepath: drift.Value(newFilePath), // Filepath only for native
        documentId: drift.Value(_documentId!),
        machineId: drift.Value(_machineId!),
        jobId: drift.Value(_jobId!),
        tagId: drift.Value(_tagId!),
        problemId: drift.Value(_problemId), // <<< NEW: Save problemId
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: const drift.Value(0), // 0 = Local, not yet synced to server
        lastSync: drift.Value(DateTime.now().toIso8601String()),
        statusSync: const drift.Value(0), // 0 = Pending sync
      );

      await _imageDao.insertImage(newImageEntry);
      _syncMessage = "รูปภาพถูกบันทึกสำเร็จ!";
      _statusMessage = "รูปภาพถูกบันทึกแล้ว.";
      await refreshImages(); // Refresh the list to show the new photo
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการประมวลผล/บันทึกรูปภาพ: $e";
      _statusMessage = "ดำเนินการล้มเหลว.";
      print("Error processing and saving image: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes an image record from the local database and its corresponding file.
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

      // 1. Delete the file from local storage (only for Native)
      // Use dart:io.File only on non-web platforms.
      if (!kIsWeb &&
          imageToDelete.filepath != null &&
          imageToDelete.filepath!.isNotEmpty) {
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
