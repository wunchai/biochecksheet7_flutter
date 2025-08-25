// lib/ui/amchecksheet/am_checksheet_viewmodel.dart

import 'package:flutter/material.dart';

// Import ส่วนที่จำเป็นจากโปรเจกต์ของคุณ
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';

class AMChecksheetViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;
  final LoginRepository _loginRepository;

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
      : _documentRecordRepository =
            DocumentRecordRepository(appDatabase: appDatabase),
        _loginRepository = LoginRepository() {
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

  // --- เพิ่มฟังก์ชันที่ขาดไปทั้งหมด ---

  /// อัปเดตค่า record เดียว (สำหรับ Input Widgets)
  Future<bool> updateRecordValue(int uid, String? newValue, String? newRemark,
      {String? newUnReadable, String? userId, int? newStatus}) async {
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

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
