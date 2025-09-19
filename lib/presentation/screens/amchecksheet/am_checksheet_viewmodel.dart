// lib/ui/amchecksheet/am_checksheet_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <<< เพิ่ม Import

// Import ส่วนที่จำเป็นจากโปรเจกต์ของคุณ
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';

import 'package:biochecksheet7_flutter/data/services/image_processing_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/checksheet_image_repository.dart';
import 'package:biochecksheet7_flutter/data/network/checksheet_image_api_service.dart';

class AMChecksheetViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;
  final LoginRepository _loginRepository;
  final AppDatabase _appDatabase; // เพิ่ม AppDatabase เพื่อเข้าถึง DAO อื่นๆ
  // เพิ่ม property นี้เข้าไปใน class
  final ImageProcessingService _imageProcessingService;
  final ChecksheetImageRepository _checksheetImageRepository;

  // --- ตัวแปรสำหรับจัดการ State ---
  String? _documentId;
  String? _machineId;
  String? _jobId;

  Stream<List<DocumentRecordWithTagAndProblem>>? _recordsStream;
  Stream<List<DocumentRecordWithTagAndProblem>>? get recordsStream =>
      _recordsStream;

  List<DocumentRecordWithTagAndProblem> _currentRecords = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusMessage = "กรุณารอสักครู่...";
  String get statusMessage => _statusMessage;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  final Map<int, String?> _recordErrors = {};
  Map<int, String?> get recordErrors => _recordErrors;

  // --- ส่วนจัดการ PageView ---
  int _currentPage = 0;
  int get currentPage => _currentPage;
  int get totalRecords => _currentRecords.length;
  late PageController pageController;

  // --- Constructor ---
  AMChecksheetViewModel({required AppDatabase appDatabase})
      : _appDatabase = appDatabase,
        _documentRecordRepository =
            DocumentRecordRepository(appDatabase: appDatabase),
        _loginRepository = LoginRepository(),
        _imageProcessingService = ImageProcessingService(),
        _checksheetImageRepository = ChecksheetImageRepository(
            appDatabase: appDatabase, apiService: ChecksheetImageApiService()) {
    pageController = PageController(initialPage: _currentPage);
  }

  // --- ฟังก์ชันสำหรับจัดการ PageView ---
  void onPageChanged(int newPage) {
    _currentPage = newPage;
    notifyListeners();
  }

  void navigateToNextPage() {
    if (_currentPage < totalRecords - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void navigateToPreviousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Logic หลัก (ยกมาจาก DocumentRecordViewModel เพื่อแก้ Error) ---

  Future<void> loadRecords(
      String documentId, String machineId, String jobId) async {
    // --- *** จุดที่แก้ไข *** ---
    // 1. รีเซ็ตค่า currentPage กลับไปเป็น 0
    _currentPage = 0;
    // 2. สั่งให้ PageController กลับไปที่หน้าแรก (สำคัญมาก)
    // ใช้ hasClients เพื่อเช็คว่า PageController พร้อมใช้งานหรือยัง
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    // --- สิ้นสุดการแก้ไข ---

    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
    _jobId = jobId;
    _statusMessage = "กำลังโหลดข้อมูล...";
    notifyListeners();

    try {
      await _documentRecordRepository.initializeRecordsFromJobTags(
        jobId: _jobId!,
        documentId: _documentId!,
        machineId: _machineId!,
      );

      _recordsStream = _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!,
        machineId: _machineId!,
      );

      _recordsStream?.listen((data) {
        _currentRecords = data;
        _statusMessage = "พบข้อมูลทั้งหมด ${_currentRecords.length} รายการ";
        if (data.isEmpty) {
          _statusMessage = "ไม่พบข้อมูลสำหรับ Checksheet นี้";
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _statusMessage = "เกิดข้อผิดพลาด: $error";
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _statusMessage = "เกิดข้อผิดพลาดในการโหลด: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  /// === ฟังก์ชันใหม่: ค้นหารูปภาพ Master สำหรับ Tag ที่ระบุ ===
  Future<DbCheckSheetMasterImage?> findMasterImageForTag(
      DbJobTag jobTag) async {
    try {
      final jobId = int.tryParse(jobTag.jobId ?? '');
      final machineId = int.tryParse(jobTag.machineId ?? '');
      final tagId = int.tryParse(jobTag.tagId ?? '');

      if (jobId == null || machineId == null || tagId == null) {
        debugPrint("Invalid ID format for finding image.");
        return null;
      }

      return await _appDatabase.checksheetMasterImageDao.getImageForTag(
        jobId: jobId,
        machineId: machineId,
        tagId: tagId,
      );
    } catch (e) {
      debugPrint("Error finding master image for tag ${jobTag.tagId}: $e");
      return null;
    }
  }

  // --- เพิ่มฟังก์ชันที่ขาดไปทั้งหมด ---

  Future<bool> updateRecordValue(int uid, String? newValue, String? newRemark,
      {String? newUnReadable, String? userId, int? newStatus}) async {
    _recordErrors[uid] = null; // ล้าง error เก่าก่อน
    notifyListeners();

    // ค้นหา record ที่ต้องการอัปเดตเพื่อเอาข้อมูล jobTag มาใช้
    final recordWithTag = _currentRecords.firstWhere(
        (r) => r.documentRecord.uid == uid,
        orElse: () => throw Exception('Record not found'));
    final jobTag = recordWithTag.jobTag;

    // --- Logic การ Validate (เฉพาะ Number) ---
    if (jobTag?.tagType == 'Number' &&
        newValue != null &&
        newValue.isNotEmpty) {
      final String? validationError = _validateNumberInput(newValue, jobTag);
      if (validationError != null) {
        _recordErrors[uid] = validationError; // กำหนด error message
        notifyListeners();
        return false; // หยุดการทำงานถ้า Validate ไม่ผ่าน
      }
    }
    // --- สิ้นสุด Logic การ Validate ---

    final success = await _documentRecordRepository.updateRecordValue(
      uid: uid,
      newValue: newValue,
      newRemark: newRemark,
      newUnReadable: newUnReadable,
      userId: userId ?? _loginRepository.loggedInUser?.userId,
      newStatus: newStatus,
    );

    // Stream จะจัดการอัปเดต UI เอง
    return success;
  }

  /// อัปเดตสถานะ "ไม่อ่านค่า"
  Future<bool> updateUnReadableStatus(int uid, bool isUnReadable) async {
    final record = _currentRecords
        .firstWhere((r) => r.documentRecord.uid == uid)
        .documentRecord;
    return await updateRecordValue(
      uid,
      isUnReadable ? '' : record.value,
      record.remark,
      newUnReadable: isUnReadable ? 'true' : 'false',
      newStatus: 0,
    );
  }

  String? _validateNumberInput(String? newValue, DbJobTag? jobTag) {
    if (newValue == null || newValue.isEmpty) return null;

    final double? numValue = double.tryParse(newValue);
    if (numValue == null) return "ต้องเป็นตัวเลขเท่านั้น";

    final String? specMin = jobTag?.specMin;
    final String? specMax = jobTag?.specMax;

    if (specMin != null && specMin.isNotEmpty) {
      final double? min = double.tryParse(specMin);
      if (min != null && numValue < min) {
        return "ค่าต่ำกว่ามาตรฐาน ($min)";
      }
    }
    if (specMax != null && specMax.isNotEmpty) {
      final double? max = double.tryParse(specMax);
      if (max != null && numValue > max) {
        return "ค่าสูงกว่ามาตรฐาน ($max)";
      }
    }
    return null; // ผ่านการตรวจสอบ
  }

  /// สั่งคำนวณค่า
  Future<void> calculateRecordValue(int uid) async {
    // ยก Logic การคำนวณมาจาก DocumentRecordViewModel
    _isLoading = true;
    _statusMessage = "กำลังคำนวณค่า...";
    notifyListeners();
    try {
      // (ใส่ Logic การเรียก repository.calculate... ที่นี่)
      // ตัวอย่าง:
      // await _documentRecordRepository.calculateRecordValue(uid, ...);
      _syncMessage = "คำนวณค่าสำเร็จ";
    } catch (e) {
      _syncMessage = "การคำนวณล้มเหลว: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// รับค่า Search (สำหรับ AppBar)
  void setSearchQuery(String query) {
    // ใน UI แบบ PageView การค้นหาอาจไม่จำเป็น แต่ต้องมีฟังก์ชันนี้ไว้เพื่อไม่ให้ AppBar error
    print("Search query changed: $query (Not implemented in AM Checksheet)");
  }

  /// NEW: Method เพื่อตรวจสอบและเปลี่ยนสถานะของ Records เป็น 2 (Posted).
  /// จะทำงานก็ต่อเมื่อทุก Record มี Status เป็น 1.
  Future<bool> postRecords() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังตรวจสอบเพื่อส่งข้อมูล...";
    notifyListeners();

    try {
      final List<DocumentRecordWithTagAndProblem> currentRecords =
          await (_recordsStream?.first ?? Future.value([]));

      if (currentRecords.isEmpty) {
        _syncMessage = "ไม่มีบันทึกให้ส่งข้อมูล.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }

      // Step 1: ตรวจสอบว่าทุก Record มี Status เป็น 1
      bool allRecordsAreStatus1 = true;
      String? validationErrorForPost;
      for (final recordWithTag in currentRecords) {
        final DbDocumentRecord record = recordWithTag.documentRecord;
        if (record.status != 1) {
          allRecordsAreStatus1 = false;
          validationErrorForPost =
              "ไม่สามารถส่งข้อมูลได้: บางบันทึกยังไม่ได้ถูกบันทึก/Validate (Status ไม่ใช่ 1).";
          _recordErrors[record.uid] =
              "Status ต้องเป็น 1 ก่อนส่งข้อมูล"; // Highlight record with wrong status
          break;
        }
      }

      if (!allRecordsAreStatus1) {
        _syncMessage = validationErrorForPost;
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }

      // Step 2: หากทุก Record มี Status เป็น 1, ทำการอัปเดต Status เป็น 2
      int postedCount = 0;
      for (final recordWithTag in currentRecords) {
        final DbDocumentRecord record = recordWithTag.documentRecord;
        final String? currentUserId = _loginRepository.loggedInUser?.userId;

        // Update status to 2 (Posted)
        final success = await _documentRecordRepository.updateRecordValue(
          uid: record.uid,
          newValue: record.value, // Keep current value
          newRemark: record.remark, // Keep current remark
          newUnReadable: record.unReadable, // Keep current unReadable status
          userId: currentUserId, // Update createBy if desired on post
          newStatus: 2, // CRUCIAL: Set status to 2
        );

        if (success) {
          postedCount++;
        } else {
          allRecordsAreStatus1 = false; // Mark as failed if any update fails
          _recordErrors[record.uid] = "ไม่สามารถอัปเดตเป็น Status 2 ได้";
        }
      }

      if (allRecordsAreStatus1) {
        _syncMessage =
            "ส่งข้อมูลสำเร็จ! ($postedCount รายการถูกอัปเดตเป็น Status 2).";
        _statusMessage = "ข้อมูลถูกส่งแล้ว.";
        await loadRecords(_documentId!, _machineId!,
            _jobId!); // Reload to show new status/read-only state
        return true;
      } else {
        _syncMessage = "มีข้อผิดพลาดในการอัปเดต Status เป็น 2. โปรดตรวจสอบ.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการส่งข้อมูล: $e";
      _statusMessage = "ส่งข้อมูลล้มเหลว.";
      print("Error posting records: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// อัปโหลดข้อมูลขึ้น Server (สำหรับ AppBar)
  Future<bool> uploadAllChangesToServer() async {
    // ยก Logic การอัปโหลดมาจาก DocumentRecordViewModel
    _isLoading = true;
    _statusMessage = "กำลังอัปโหลดขึ้นเซิร์ฟเวอร์...";
    notifyListeners();
    bool success = false;
    try {
      success = await _documentRecordRepository.uploadRecordsToServer(
        documentId: _documentId!,
        machineId: _machineId!,
        jobId: _jobId!,
      );
      _syncMessage = success ? "อัปโหลดสำเร็จ" : "อัปโหลดล้มเหลว";
    } catch (e) {
      _syncMessage = "เกิดข้อผิดพลาด: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  // --- ส่วนที่เหลือ (saveAllChanges, validate, dispose) ---

  Future<bool> saveAllChanges({
    required Map<int, TextEditingController> allControllers,
    required Map<int, String?> allComboBoxValues,
  }) async {
    // ... (โค้ด saveAllChanges เหมือนเดิม) ...
    return true; // Placeholder
  }

// --- <<< จุดที่แก้ไขสำคัญ >>> ---
  /// เปลี่ยนชื่อฟังก์ชันและเปลี่ยน Furture เป็น Stream
  Stream<DbCheckSheetMasterImage?> watchMasterImageForTag(DbJobTag jobTag) {
    try {
      final jobId = int.tryParse(jobTag.jobId ?? '');
      final machineId = int.tryParse(jobTag.machineId ?? '');
      final tagId = int.tryParse(jobTag.tagId ?? '');

      if (jobId == null || machineId == null || tagId == null) {
        debugPrint("Invalid ID format for watching image.");
        return Stream.value(null); // คืน Stream ที่มีค่า null ทันที
      }

      // เรียกใช้ฟังก์ชัน watch... ใหม่จาก DAO
      return _appDatabase.checksheetMasterImageDao.watchImageForTag(
        jobId: jobId,
        machineId: machineId,
        tagId: tagId,
      );
    } catch (e) {
      debugPrint("Error watching master image for tag ${jobTag.tagId}: $e");
      return Stream.error(e); // คืน Stream ที่มี error
    }
  }

  // --- <<< ฟังก์ชันใหม่ที่เพิ่มเข้ามา >>> ---
  /// รับข้อมูลรูปภาพที่แก้ไขแล้วมาบันทึกทับข้อมูลเดิม
  Future<bool> updateMasterImage(
      DbCheckSheetMasterImage originalImage, Uint8List editedImageBytes) async {
    try {
      _isLoading = true;
      _statusMessage = "กำลังบันทึกรูปภาพที่แก้ไข...";
      notifyListeners();

      // เรียกใช้ Repository เพื่อจัดการการบันทึกทับไฟล์/ข้อมูล
      final success = await _checksheetImageRepository.overwriteMasterImage(
        originalImageRecord: originalImage,
        newImageBytes: editedImageBytes,
      );

      if (success) {
        _syncMessage = "อัปเดตรูปภาพสำเร็จ";
      } else {
        _syncMessage = "ไม่สามารถอัปเดตรูปภาพได้";
      }
      return success;
    } catch (e) {
      _syncMessage = "เกิดข้อผิดพลาดในการอัปเดตรูปภาพ: $e";
      return false;
    } finally {
      _isLoading = false;
      _statusMessage = "";
      notifyListeners();
    }
  }

  Future<void> selectAndSaveNewMasterImage(
      DbJobTag jobTag, ImageSource source) async {
    try {
      _isLoading = true;
      _statusMessage = "กำลังประมวลผลรูปภาพ...";
      notifyListeners();

      // เรียกใช้ Service โดยส่ง `source` ที่ผู้ใช้เลือกไปด้วย
      final String? imagePath =
          await _imageProcessingService.pickAndProcessImage(source: source);

      if (imagePath != null) {
        final success =
            await _checksheetImageRepository.createOrUpdateNewMasterImageRecord(
          jobId: int.parse(jobTag.jobId!),
          machineId: int.parse(jobTag.machineId!),
          tagId: int.parse(jobTag.tagId!),
          localPath: imagePath,
        );

        if (success) {
          _syncMessage = "บันทึกรูปภาพใหม่เรียบร้อยแล้ว";
          // TODO: ต้องมีวิธี refresh หน้าจอเพื่อแสดงรูปใหม่
        } else {
          _syncMessage = "ไม่สามารถบันทึกข้อมูลรูปภาพได้";
        }
      }
    } catch (e) {
      _syncMessage = "เกิดข้อผิดพลาด: $e";
    } finally {
      _isLoading = false;
      _statusMessage = "";
      notifyListeners();
    }
  }

  // เพิ่มฟังก์ชันนี้เข้าไปใน class
  Future<void> captureAndSaveNewMasterImage(DbJobTag jobTag) async {
    try {
      _isLoading = true;
      _statusMessage = "กำลังประมวลผลรูปภาพ...";
      notifyListeners();

      final String? imagePath =
          await _imageProcessingService.pickAndProcessImage();

      if (imagePath != null) {
        final success =
            await _checksheetImageRepository.createOrUpdateNewMasterImageRecord(
          jobId: int.parse(jobTag.jobId!),
          machineId: int.parse(jobTag.machineId!),
          tagId: int.parse(jobTag.tagId!),
          localPath: imagePath,
        );
        if (success) {
          _syncMessage = "บันทึกรูปภาพใหม่เรียบร้อยแล้ว";
          // เราอาจจะต้องมีวิธี refresh หน้าจอเพื่อแสดงรูปใหม่
        } else {
          _syncMessage = "ไม่สามารถบันทึกข้อมูลรูปภาพได้";
        }
      }
    } catch (e) {
      _syncMessage = "เกิดข้อผิดพลาด: $e";
    } finally {
      _isLoading = false;
      _statusMessage = "";
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
