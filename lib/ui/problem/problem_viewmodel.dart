// lib/ui/problem/problem_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/problem_repository.dart'; // For ProblemRepository
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // For userId
import 'package:fl_chart/fl_chart.dart'; // For FlSpot (for online chart)
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart'; // For online chart data source
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart'; // <<< NEW: Import DataSyncService
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // <<< NEW: Import sync_status.dart
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart'; // <<< NEW: Import ImageDao

class ProblemViewModel extends ChangeNotifier {
  final ProblemRepository _problemRepository;
  final LoginRepository _loginRepository;
  final DocumentRecordRepository _documentRecordRepository; // For online chart data
  final DataSyncService _dataSyncService; // <<< NEW: Add DataSyncService dependency
  final ImageDao _imageDao; // <<< NEW: Add ImageDao dependency

  Stream<List<DbProblem>>? _problemsStream;
  Stream<List<DbProblem>>? get problemsStream => _problemsStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusMessage = "กำลังโหลดปัญหา...";
  String get statusMessage => _statusMessage;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  final Map<int, String?> _problemErrors = {}; // Map to store validation errors for each problem's UID
  Map<int, String?> get problemErrors => _problemErrors;

    // NEW: Stream for online chart data for problems
  Stream<List<FlSpot>>? _onlineChartDataStream;
  Stream<List<FlSpot>>? get onlineChartDataStream => _onlineChartDataStream;

  ProblemViewModel({required AppDatabase appDatabase})
      : _problemRepository = ProblemRepository(appDatabase: appDatabase),
        _loginRepository = LoginRepository(),
        _documentRecordRepository = DocumentRecordRepository(appDatabase: appDatabase),
        _dataSyncService = DataSyncService(appDatabase: appDatabase),
        _imageDao = appDatabase.imageDao; // <<< NEW: Initialize ImageDao

  /// โหลดรายการปัญหาตาม Status (0, 1, 2)
  Future<void> loadProblems() async {
    _isLoading = true;
    _statusMessage = "กำลังดึงรายการปัญหา...";
    notifyListeners();

    try {
      _problemsStream = _problemRepository.watchProblemsByStatus([0, 1, 2]); // Load problems with status 0, 1, 2
      _statusMessage = "รายการปัญหาโหลดแล้ว.";
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลดรายการปัญหาได้: $e";
      print("ข้อผิดพลาดในการโหลดรายการปัญหา: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh รายการปัญหา
  Future<void> refreshProblems() async {
    _isLoading = true;
    _syncMessage = "กำลัง Refresh รายการปัญหา...";
    _statusMessage = "กำลัง Refresh รายการปัญหา...";
    notifyListeners();
    try {
      // NEW: Call API sync for problems first
      print('ProblemViewModel: กำลังซิงค์ปัญหาจาก API...');
      // Assuming _syncProblemsData is public or you create a public method for it.
      // If _syncProblemsData is private, you might need to make it public or create a wrapper.
      // For now, let's assume performFullSync can be called, or we make _syncProblemsData public.
      // Let's call performFullSync to ensure all master data is synced.
      final syncResult = await _dataSyncService.performProblemsSync(); // Calls full sync

      if (syncResult is SyncError) {
        _syncMessage = "ข้อผิดพลาดในการซิงค์ปัญหา: ${syncResult.exception}";
        _statusMessage = "ซิงค์ปัญหาล้มเหลว.";
        print("Error during problem sync: ${syncResult.exception}");
      } else {
        _syncMessage = "ซิงค์ปัญหาสำเร็จ!";
        _statusMessage = "ซิงค์ปัญหาสำเร็จ.";
      }
      await loadProblems(); // Reload from DB
      _syncMessage = "รายการปัญหา Refresh แล้ว!";
    } catch (e) {
      _syncMessage = "ข้อผิดพลาดในการ Refresh รายการปัญหา: $e";
      print("ข้อผิดพลาดในการ Refresh รายการปัญหา: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// อัปเดต SolvingDescription ของปัญหา
  Future<bool> updateProblemSolvingDescription(int uid, String? newDescription) async {
    _isLoading = true;
    _syncMessage = null;
    _problemErrors[uid] = null;
    _statusMessage = "กำลังอัปเดตคำอธิบายการแก้ไข...";
    notifyListeners();

    try {
      final success = await _problemRepository.updateProblem(
        uid: uid,
        problemSolvingDescription: newDescription,
        newProblemStatus: 0, // Set status to 0 when modified
        problemSolvingBy: _loginRepository.loggedInUser?.userId, // Set solvingBy
      );
      _syncMessage = success ? "อัปเดตคำอธิบายการแก้ไขสำเร็จ!" : "ไม่สามารถอัปเดตคำอธิบายการแก้ไขได้.";
      _statusMessage = success ? "อัปเดตแล้ว." : "อัปเดตล้มเหลว.";
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปเดตคำอธิบายการแก้ไข: $e";
      _statusMessage = "อัปเดตล้มเหลว: $e";
      print("Error updating problem solving description: $e");
      _problemErrors[uid] = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

 
/// ฟังก์ชัน Validate สำหรับปัญหาแต่ละรายการ
  /// คืนค่า true หาก Validate ผ่าน, false หากไม่ผ่าน.
  Future<bool> _validateProblem(int uid, String? problemSolvingDescription) async {
    // ดึงปัญหาล่าสุดจาก DB เพื่อตรวจสอบสถานะ
    final DbProblem? problemInDB = await _problemRepository.getProblemByUid(uid);
    bool isProblemSolved = (problemInDB?.problemStatus == 0 || problemInDB?.problemStatus == 0); // Status 1 หรือ 2 ถือว่า "แก้ไขแล้ว"

    // กฎ: ถ้า problemStatus เป็น 1 หรือ 2, SolvingDescription ต้องไม่ว่างเปล่า.
    if (isProblemSolved && (problemSolvingDescription == null || problemSolvingDescription.isEmpty)) {
      _problemErrors[uid] = "เมื่อปัญหาถูกแก้ไข/ส่งข้อมูล ต้องระบุคำอธิบายการแก้ไข.";
      return false;
    }
    _problemErrors[uid] = null; // ล้างข้อผิดพลาดหาก Valid
    return true;
  }

  /// NEW: ฟังก์ชัน Save All Changes สำหรับปัญหา
  Future<bool> saveAllProblemChanges({
    required Map<int, TextEditingController> solvingDescriptionControllers,
  }) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังบันทึกการเปลี่ยนแปลงปัญหาทั้งหมด...";
    notifyListeners();

    bool allProblemsValid = true;
    final List<DbProblem> currentProblemsSnapshot = await (_problemsStream?.first ?? Future.value([]));

    for (final problem in currentProblemsSnapshot) {
      String? uiSolvingDescription = solvingDescriptionControllers[problem.uid]?.text.trim();

      // Perform individual problem validation
      final bool problemIsValid = await _validateProblem(problem.uid, uiSolvingDescription);
      if (!problemIsValid) {
        allProblemsValid = false; // If any problem fails validation, overall save fails
      } else {
        // If problem is valid, check for changes and save
        final DbProblem? latestProblemInDB = await _problemRepository.getProblemByUid(problem.uid);
        bool solvingDescriptionChanged = uiSolvingDescription != (latestProblemInDB?.problemSolvingDescription ?? '');

        if (solvingDescriptionChanged) {
          final success = await _problemRepository.updateProblem(
            uid: problem.uid,
            problemSolvingDescription: uiSolvingDescription,
            newProblemStatus: 0, // Set to 0 on any edit
            problemSolvingBy: _loginRepository.loggedInUser?.userId,
          );
          if (!success) allProblemsValid = false;
        }
      }
    }

    if (allProblemsValid) {
      _syncMessage = "บันทึกการเปลี่ยนแปลงปัญหาสำเร็จ!";
      _statusMessage = "บันทึกข้อมูลเรียบร้อย.";
    } else {
      _syncMessage = "บันทึกการเปลี่ยนแปลงปัญหาล้มเหลว. โปรดตรวจสอบข้อผิดพลาด.";
      _statusMessage = "บันทึกข้อมูลล้มเหลว.";
    }
    notifyListeners();
    await loadProblems(); // Reload to reflect changes
    return allProblemsValid;
  }

  /// NEW: ฟังก์ชัน Post Problem (เปลี่ยน Status เป็น 2)
  /// ฟังก์ชัน Post Problem (เปลี่ยน Status เป็น 2)
  Future<bool> postProblem(int uid, String? currentSolvingDescription) async { // <<< NEW: รับ currentSolvingDescription
    _isLoading = true;
    _syncMessage = null;
    _problemErrors[uid] = null; // Clear specific error for this problem
    _statusMessage = "กำลังส่งข้อมูลปัญหา...";
    notifyListeners();

    try {
      final DbProblem? problem = await _problemRepository.getProblemByUid(uid);
      if (problem == null) {
        throw Exception("ไม่พบปัญหา UID $uid.");
      }

      // Check if problem is already Status 2
      if (problem.problemStatus == 2) {
        _syncMessage = "ปัญหา UID $uid ถูกส่งข้อมูลแล้ว.";
        _statusMessage = "ส่งข้อมูลสำเร็จ.";
        return true;
      }

      // --- Pre-Post Validation ---
      // 1. Validate SolvingDescription using the current UI value
      final bool isValidSolvingDesc = await _validateProblem(uid, currentSolvingDescription); // <<< ใช้ currentSolvingDescription
      if (!isValidSolvingDesc) {
        _syncMessage = "ไม่สามารถส่งข้อมูลได้: โปรดระบุคำอธิบายการแก้ไข.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }

      // If solving description is valid, make sure to update it in DB before posting
      final DbProblem? latestProblemInDB = await _problemRepository.getProblemByUid(uid);
      if (currentSolvingDescription != (latestProblemInDB?.problemSolvingDescription ?? '')) {
          await _problemRepository.updateProblem(
            uid: uid,
            problemSolvingDescription: currentSolvingDescription,
            newProblemStatus: problem.problemStatus, // Keep current status for now (0)
            problemSolvingBy: _loginRepository.loggedInUser?.userId,
          );
      }

      // 2. Validate at least one photo exists for this problem
      if (problem.problemId == null || problem.problemId!.isEmpty) {
        _problemErrors[uid] = "Problem ID ขาดหาย ไม่สามารถตรวจสอบรูปภาพได้.";
        _syncMessage = "ไม่สามารถส่งข้อมูลได้: Problem ID ขาดหาย.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }
      final int imageCount = await _imageDao.countImagesForProblem(problem.problemId!);
      if (imageCount == 0) {
        _problemErrors[uid] = "ต้องมีรูปถ่ายอย่างน้อย 1 รูป.";
        _syncMessage = "ไม่สามารถส่งข้อมูลได้: ต้องมีรูปถ่ายอย่างน้อย 1 รูป.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }
      // --- End Pre-Post Validation ---

      // Proceed to update status to 2
      final success = await _problemRepository.updateProblem(
        uid: uid,
        newProblemStatus: 2, // Set status to 2 (Posted)
        problemSolvingBy: _loginRepository.loggedInUser?.userId, // Who posted it
      );

      if (success) {
        _syncMessage = "ส่งข้อมูลปัญหา UID $uid สำเร็จ!";
        _statusMessage = "ส่งข้อมูลสำเร็จ.";
        await refreshProblems(); // Refresh list to show new status
      } else {
        _syncMessage = "ไม่สามารถส่งข้อมูลปัญหา UID $uid ได้.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
      }
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการส่งข้อมูลปัญหา: $e";
      _statusMessage = "ส่งข้อมูลล้มเหลว: $e";
      print("Error posting problem: $e");
      _problemErrors[uid] = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NEW: โหลดข้อมูลกราฟ Online สำหรับปัญหา (ใช้ DocumentRecordRepository)
  Future<void> loadOnlineChartDataForProblem(String tagId, String machineId, String jobId) async {
    _isLoading = true;
    _statusMessage = "กำลังดึงข้อมูลกราฟ Online สำหรับปัญหา...";
    notifyListeners();

    try {
      // Reuse DocumentRecordRepository's method to get historical chart data
      _onlineChartDataStream = _documentRecordRepository.getOnlineChartDataStream(
        jobId,
        machineId,
        tagId,
      );
      _statusMessage = "ข้อมูลกราฟ Online สำหรับปัญหาโหลดแล้ว.";
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลดข้อมูลกราฟ Online สำหรับปัญหาได้: $e";
      print("ข้อผิดพลาดในการโหลดข้อมูลกราฟ Online สำหรับปัญหา: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// NEW: Method เพื่อส่งข้อมูลปัญหาทั้งหมดที่ ProblemStatus เป็น 2 ขึ้น Server.
  Future<bool> uploadAllProblemsToServer() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังส่งข้อมูลปัญหาทั้งหมดขึ้น Server...";
    notifyListeners();

    try {
     // 1. Upload Problems
      final problemUploadSuccess = await _problemRepository.uploadProblemsToServer();

      // 2. Upload associated Images (for problems)
      final imageUploadSuccess = await _dataSyncService.performImageUploadSync(); // <<< NEW: Call image upload

      bool allSuccessful = true;
      String finalMessage = "";

      if (problemUploadSuccess) { // problemRepository.uploadProblemsToServer returns bool
        finalMessage += "อัปโหลดปัญหาสำเร็จ.\n";
      } else {
        finalMessage += "อัปโหลดปัญหาล้มเหลว.\n";
        allSuccessful = false;
      }

      if (imageUploadSuccess is SyncSuccess) {
        finalMessage += "อัปโหลดรูปภาพปัญหา: ${imageUploadSuccess.message}\n";
      } else if (imageUploadSuccess is SyncError) {
        finalMessage += "อัปโหลดรูปภาพปัญหาล้มเหลว: ${imageUploadSuccess.exception}\n";
        allSuccessful = false;
      }

      
      _syncMessage = finalMessage.trim();
      _statusMessage = allSuccessful ? "อัปโหลดทั้งหมดสำเร็จ." : "อัปโหลดบางส่วนล้มเหลว.";

      await refreshProblems(); // Refresh list to show new status (3)
      return problemUploadSuccess;

    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการส่งข้อมูลปัญหาขึ้น Server: $e";
      _statusMessage = "ส่งข้อมูลล้มเหลว: $e";
      print("Error uploading all problems to server: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}