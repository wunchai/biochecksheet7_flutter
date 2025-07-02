// lib/ui/problem/problem_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/problem_repository.dart'; // For ProblemRepository
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // For userId
import 'package:fl_chart/fl_chart.dart'; // For FlSpot (for online chart)
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart'; // For online chart data source

class ProblemViewModel extends ChangeNotifier {
  final ProblemRepository _problemRepository;
  final LoginRepository _loginRepository;
  final DocumentRecordRepository _documentRecordRepository; // For online chart data

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
        _documentRecordRepository = DocumentRecordRepository(appDatabase: appDatabase); // Initialize for online chart

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

  /// NEW: ฟังก์ชัน Validate สำหรับปัญหาแต่ละรายการ
  Future<bool> _validateProblem(int uid, String? problemSolvingDescription) async {
    // Get the latest problem from DB for accurate status check
    final DbProblem? problemInDB = await _problemRepository.getProblemByUid(uid);
    bool isProblemSolved = (problemInDB?.problemStatus == 1 || problemInDB?.problemStatus == 2); // Status 1 or 2 means it's considered "solved"

    // Rule: If problemStatus is 1 or 2, SolvingDescription must not be empty.
    if (isProblemSolved && (problemSolvingDescription == null || problemSolvingDescription.isEmpty)) {
      _problemErrors[uid] = "เมื่อปัญหาถูกแก้ไข/ส่งข้อมูล ต้องระบุคำอธิบายการแก้ไข.";
      return false;
    }
    _problemErrors[uid] = null; // Clear error if valid
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
  Future<bool> postProblem(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _problemErrors[uid] = null;
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

      // Validate before posting (ensure solving description is filled if status becomes 1 or 2)
      final bool isValid = await _validateProblem(uid, problem.problemSolvingDescription);
      if (!isValid) {
        _syncMessage = "ไม่สามารถส่งข้อมูลได้: โปรดระบุคำอธิบายการแก้ไข.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
        return false;
      }

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

  // TODO: Add sync function for problems in Phase 4
}