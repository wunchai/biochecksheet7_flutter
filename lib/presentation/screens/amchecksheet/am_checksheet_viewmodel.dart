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
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart'; // Import DataSyncService
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // Import SyncStatus

class AMChecksheetViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;
  final LoginRepository _loginRepository;
  final AppDatabase _appDatabase; // เพิ่ม AppDatabase เพื่อเข้าถึง DAO อื่นๆ
  // เพิ่ม property นี้เข้าไปใน class
  final ImageProcessingService _imageProcessingService;
  final ChecksheetImageRepository _checksheetImageRepository;
  final DataSyncService _dataSyncService; // Add DataSyncService

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

  // Sync Progress Notifiers
  final ValueNotifier<double?> syncProgressNotifier = ValueNotifier(null);
  final ValueNotifier<String> syncStatusNotifier = ValueNotifier('');

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
            appDatabase: appDatabase, apiService: ChecksheetImageApiService()),
        _dataSyncService = DataSyncService(appDatabase: appDatabase) {
    // Initialize DataSyncService
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
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังบันทึกการเปลี่ยนแปลงทั้งหมด...";
    notifyListeners();

    // NEW: เรียกฟังก์ชัน Validate ก่อนบันทึก
    final bool validationPassed = await _validateAllRecordsForValidation(
      allControllers: allControllers,
      allComboBoxValues: allComboBoxValues,
    );

    if (!validationPassed) {
      _isLoading = false;
      notifyListeners();
      _statusMessage = "บันทึกข้อมูลล้มเหลว: โปรดแก้ไขข้อผิดพลาดก่อน.";
      _syncMessage = "มีข้อผิดพลาดในการ Validate. โปรดตรวจสอบ.";
      return false; // หยุดการทำงานถ้า Validation ไม่ผ่าน
    }

    // หาก Validation ผ่าน ก็ดำเนินการบันทึกต่อ
    int updatedCount = 0;
    bool allSucceeded = true;
    final String? currentUserId = _loginRepository.loggedInUser?.userId;

    // ใช้ข้อมูลปัจจุบันจาก _currentRecords
    final List<DocumentRecordWithTagAndProblem> currentRecordsSnapshot =
        List.from(_currentRecords);

    if (currentRecordsSnapshot.isEmpty) {
      _statusMessage = "ไม่มีบันทึกให้บันทึก.";
      _isLoading = false;
      notifyListeners();
      return true; // ไม่มีอะไรให้บันทึก
    }

    for (final recordWithTag in currentRecordsSnapshot) {
      final DbDocumentRecord record = recordWithTag.documentRecord;
      final DbJobTag? jobTag = recordWithTag.jobTag;

      String? uiValue;
      String? uiRemark = record.remark; // Default to existing remark

      // ดึงค่าจาก UI Controller/Map
      if (jobTag?.tagType == 'ComboBox' || jobTag?.tagType == 'CheckBox') {
        if (allComboBoxValues.containsKey(record.uid)) {
          uiValue = allComboBoxValues[record.uid];
        } else {
          uiValue =
              record.value; // Fallback to DB value if UI element not built
        }
      } else {
        if (allControllers.containsKey(record.uid)) {
          uiValue = allControllers[record.uid]?.text;
        } else {
          uiValue =
              record.value; // Fallback to DB value if UI element not built
        }
      }

      // เปรียบเทียบกับค่าล่าสุดใน DB (ดึงมาใหม่เพื่อความแม่นยำ)
      final DbDocumentRecord? latestRecordInDB =
          await _documentRecordRepository.getRecordByUid(record.uid);

      bool valueChanged = uiValue != (latestRecordInDB?.value ?? '');
      bool remarkChanged = uiRemark !=
          (latestRecordInDB?.remark ?? ''); // เปรียบเทียบกับค่า remark ปัจจุบัน
      // สำหรับ unReadable, ตรวจสอบสถานะใหม่จาก UI (ถ้าเป็น Number type และ empty/not empty)
      String newUnReadableStatus =
          (jobTag?.tagType == 'Number' && (uiValue?.isEmpty ?? false))
              ? 'true'
              : 'false';
      bool unReadableStatusChanged =
          newUnReadableStatus != (latestRecordInDB?.unReadable ?? 'false');

      // Check if this specific record passed validation (no error for it)
      bool recordPassedIndividualValidation = (_recordErrors[record.uid] ==
          null); // Error from _validateAllRecordsForValidation
      // Determine the status to apply for this record
      int statusToApply =
          latestRecordInDB?.status ?? 0; // Get current status from DB
      if (recordPassedIndividualValidation) {
        // If the record is valid
        if (statusToApply != 1 && statusToApply != 2) {
          // And its current status is not 1 or 2 (needs promotion)
          statusToApply = 1; // Set to 1 (Validated)
        }
        // If statusToApply is already 1 or 2, keep it.
      } else {
        // If record did NOT pass validation (has an error)
        statusToApply = 0; // Ensure its status is 0 (Validation Failed)
      }
      bool needsUpdateCall = valueChanged ||
          remarkChanged ||
          unReadableStatusChanged ||
          (statusToApply != (latestRecordInDB?.status ?? 0));
      // ตรวจสอบว่ามีการเปลี่ยนแปลงจริงในค่า, หมายเหตุ, หรือสถานะ unReadable
      if (needsUpdateCall) {
        bool success;
        success = await _documentRecordRepository.updateRecordValue(
          uid: record.uid,
          newValue: uiValue, // Pass the current UI value
          newRemark: uiRemark, // Pass the current UI remark
          newUnReadable:
              (jobTag?.tagType == 'Number') ? newUnReadableStatus : null,
          userId: currentUserId,
          newStatus: statusToApply, // Pass the determined status
        );

        if (success) {
          updatedCount++;
          _recordErrors[record.uid] = null; // ล้าง Error สำหรับ Record นี้
        } else {
          allSucceeded = false;
          _recordErrors.putIfAbsent(
              record.uid, () => "บันทึกข้อมูลล้มเหลว"); // เก็บ Error
        }
      } else {
        // หากไม่มีการเปลี่ยนแปลง แต่ Record นี้มี Error จาก Validation
        if (_recordErrors[record.uid] != null) {
          allSucceeded = false; // ถ้ามี Error จาก Validation, ก็ถือว่าไม่สำเร็จ
        }
      }
    }

    if (allSucceeded) {
      _syncMessage =
          "บันทึกการเปลี่ยนแปลงทั้งหมดสำเร็จ ($updatedCount รายการ)!";
      _statusMessage = "บันทึกข้อมูลเรียบร้อย.";
    } else {
      _syncMessage =
          "บันทึกการเปลี่ยนแปลงบางรายการล้มเหลว. โปรดตรวจสอบข้อผิดพลาด.";
      _statusMessage = "บันทึกข้อมูลล้มเหลว.";
    }
    _isLoading = false;
    notifyListeners(); // แจ้ง UI ให้ Refresh/Rebuild
    // ไม่ต้องโหลดใหม่ทั้งหมดเพราะ Stream จะจัดการเอง แต่ถ้าต้องการความชัวร์ก็เรียกได้
    // await loadRecords(_documentId!, _machineId!, _jobId!);
    return allSucceeded;
  }

  // NEW: ฟังก์ชัน Validate โดยเฉพาะ (เทียบเท่า btValidate)
  // จะตรวจสอบความครบถ้วนและอัปเดต userId สำหรับ TagType='User'
  Future<bool> _validateAllRecordsForValidation({
    required Map<int, TextEditingController> allControllers,
    required Map<int, String?> allComboBoxValues,
  }) async {
    _recordErrors.clear(); // ล้าง Error ทั้งหมดก่อนเริ่ม Validate ใหม่
    bool allRecordsValid = true;
    final String? currentUserId = _loginRepository.loggedInUser?.userId;

    // ใช้ข้อมูลจาก _currentRecords
    final List<DocumentRecordWithTagAndProblem> currentRecordsSnapshot =
        List.from(_currentRecords);

    for (final recordWithTag in currentRecordsSnapshot) {
      final DbDocumentRecord record = recordWithTag.documentRecord;
      final DbJobTag? jobTag = recordWithTag.jobTag;

      String? uiValue;

      // ดึงค่าจาก UI Controller/Map
      if (jobTag?.tagType == 'ComboBox' || jobTag?.tagType == 'CheckBox') {
        if (allComboBoxValues.containsKey(record.uid)) {
          uiValue = allComboBoxValues[record.uid];
        } else {
          uiValue =
              record.value; // Fallback to DB value if UI element not built
        }
      } else {
        if (allControllers.containsKey(record.uid)) {
          uiValue = allControllers[record.uid]?.text;
        } else {
          uiValue =
              record.value; // Fallback to DB value if UI element not built
        }
      }
      uiValue = uiValue?.trim();
      String? uiRemark = record.remark
          ?.trim(); // Remark ไม่ได้อยู่ใน Controller หลักเสมอไป เอาจาก DB เดิมก่อน

      String? validationErrorForThisRecord;

      // --- 1. Auto-populate User ID for 'User' TagType (เทียบเท่า updateUserTag) ---
      if (jobTag?.tagType == 'User') {
        if (currentUserId != null &&
            currentUserId.isNotEmpty &&
            (uiValue == null || uiValue.isEmpty)) {
          uiValue = currentUserId; // กำหนด userId อัตโนมัติ
          allControllers[record.uid]?.text =
              currentUserId; // อัปเดต UI Controller ด้วย (เพื่อให้ UI แสดงค่า)
          // บันทึกลง DB ทันที (เพราะถือว่าเป็นการเปลี่ยนแปลงที่สำคัญ)
          await _documentRecordRepository.updateRecordValue(
            uid: record.uid,
            newValue: currentUserId,
            newRemark: record.remark,
            userId: currentUserId,
            newStatus: 0, // ตั้ง Status เป็น 0 เมื่อมีการแก้ไข/Auto-populate
          );
        } else if ((uiValue == null || uiValue == '') &&
            (currentUserId == null || currentUserId.isEmpty)) {
          validationErrorForThisRecord =
              "กรุณาเข้าสู่ระบบ หรือ ซิงค์ข้อมูลผู้ใช้ เพื่อกรอก User ID อัตโนมัติ.";
          allRecordsValid = false;
        }
      }

      // --- 2. Required Field Validation (สำหรับทุก Record) ---
      // กฎ: ทุก Record ต้องมีข้อมูล (uiValue ไม่ว่างเปล่า)
      // ยกเว้น: Number ที่เลือก N/A

      // ตรวจสอบสถานะ unReadable สำหรับ Number (จาก DB ล่าสุด หรือจาก UI Logic)
      // ในที่นี้เราดูจาก DB ล่าสุด หรือถ้า UI ว่างและเป็น Number เราอาจจะถือว่าเป็น N/A?
      // แต่ปกติ N/A ต้องมีการติ๊กเลือก หรือกดปุ่ม
      // ใน Code เก่า (DocumentRecordViewModel) ใช้ latestRecordInDB?.unReadable

      final DbDocumentRecord? latestRecordInDB =
          await _documentRecordRepository.getRecordByUid(record.uid);
      bool isCurrentlyUnReadable = (jobTag?.tagType == 'Number' &&
          (latestRecordInDB?.unReadable == 'true'));

      // ถ้า UI Value ว่าง และไม่ใช่ UnReadable -> Error
      if (uiValue == null || uiValue == '') {
        if (jobTag?.tagType == 'Number') {
          if (!isCurrentlyUnReadable) {
            // ถ้าเป็น Number แต่ไม่ได้เลือก N/A = Error
            validationErrorForThisRecord = "จำเป็นต้องกรอกข้อมูลตัวเลข.";
            allRecordsValid = false;
          }
        } else if (jobTag?.tagType != 'Problem') {
          // Tag Type อื่นๆ (Text, ComboBox, CheckBox) ถือเป็น Required ถ้าว่างเปล่า
          validationErrorForThisRecord = "จำเป็นต้องกรอกข้อมูล.";
          allRecordsValid = false;
        }
      }

      // --- 3. Mandatory Remark for N/A Number ---
      if (jobTag?.tagType == 'Number' && isCurrentlyUnReadable) {
        if (uiRemark == null || uiRemark.isEmpty) {
          // หมายเหตุอาจจะต้องดึงจาก DB ถ้าไม่ได้แก้ในหน้านี้
          // แต่ปกติหน้า AM Checksheet แก้หมายเหตุได้
          // ในที่นี้เราใช้ record.remark ไปก่อน
          if (record.remark == null || record.remark!.isEmpty) {
            validationErrorForThisRecord =
                "เมื่อ 'ไม่อ่านค่าได้' ต้องระบุหมายเหตุ.";
            allRecordsValid = false;
          }
        }
      }

      // --- 4. Type-specific validation (สำหรับค่าที่ไม่ว่างเปล่า และยังไม่มี Error) ---
      if (validationErrorForThisRecord == null &&
          uiValue != null &&
          uiValue.isNotEmpty) {
        if (jobTag?.tagType == 'Number') {
          validationErrorForThisRecord = _validateNumberInput(uiValue, jobTag);
          if (validationErrorForThisRecord != null) {
            allRecordsValid = false;
          }
        }
      }

      // --- สิ้นสุด Validation Rules ---

      if (validationErrorForThisRecord != null) {
        _recordErrors[record.uid] = validationErrorForThisRecord;
      } else {
        _recordErrors[record.uid] =
            null; // Clear any existing error for this record
      }
    }

    notifyListeners();
    return allRecordsValid;
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

  /// === ฟังก์ชันที่แก้ไข: จัดการทั้งการ Upload และ Download (เหมือน HomeViewModel) ===
  Future<String> syncMasterImages() async {
    // --- ขั้นตอนที่ 1: UPLOAD ---
    syncProgressNotifier.value = null; // Indeterminate progress
    syncStatusNotifier.value = 'ขั้นตอนที่ 1/2: กำลังอัปโหลดรูปภาพใหม่...';

    final uploadResult = await _dataSyncService.performMasterImageUploadSync(
      onProgress: (current, total) {
        if (total > 0) {
          syncProgressNotifier.value = current / total;
          syncStatusNotifier.value =
              'กำลังอัปโหลดรูปภาพ $current จาก $total...';
        } else {
          syncStatusNotifier.value = 'ไม่พบรูปภาพใหม่ที่ต้องอัปโหลด';
        }
      },
    );

    // หากการ Upload ล้มเหลว ให้หยุดทำงานและรายงานผล
    if (uploadResult is SyncError) {
      return uploadResult.message ?? 'เกิดข้อผิดพลาดในการอัปโหลด';
    }

    // --- ขั้นตอนที่ 2: DOWNLOAD ---
    syncProgressNotifier.value = null; // Reset progress for download
    syncStatusNotifier.value =
        'ขั้นตอนที่ 2/2: กำลังดาวน์โหลดรูปภาพจากเซิร์ฟเวอร์...';

    final downloadResult = await _dataSyncService.performMasterImageSync(
      onProgress: (current, total) {
        if (total > 0) {
          syncProgressNotifier.value = current / total;
          syncStatusNotifier.value =
              'กำลังดาวน์โหลดรูปภาพ $current จาก $total...';
        } else {
          syncStatusNotifier.value = 'ไม่พบรูปภาพใหม่ที่ต้องดาวน์โหลด';
        }
      },
    );

    syncProgressNotifier.value = null;

    if (downloadResult is SyncSuccess) {
      return 'ซิงค์ข้อมูล Master Image สำเร็จ!';
    } else if (downloadResult is SyncError) {
      return downloadResult.message ?? 'เกิดข้อผิดพลาดในการดาวน์โหลด';
    }
    return 'การซิงค์สิ้นสุดลง';
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
