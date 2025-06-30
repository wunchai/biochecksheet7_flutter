// lib/ui/documentrecord/document_record_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart'; // สำหรับ DocumentRecordWithTagAndProblem
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // สำหรับ DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // สำหรับ DbJobTag
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // สำหรับ DbProblem
import 'package:drift/drift.dart' as drift; // Alias drift

import 'package:fl_chart/fl_chart.dart'; // สำหรับ FlSpot
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // เพื่อดึง userId จาก LoggedInUser

/// เทียบเท่ากับ DocumentRecordViewModel.kt ในโปรเจกต์ Kotlin เดิม
/// ViewModel นี้จัดการสถานะและ Logic สำหรับ DocumentRecordScreen.
class DocumentRecordViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;
  final LoginRepository _loginRepository; // ใช้เข้าถึงข้อมูลผู้ใช้ที่ล็อกอินอยู่

  String? _documentId; // เก็บ Document ID ปัจจุบัน
  String? get documentId => _documentId;
  String? _machineId; // เก็บ Machine ID ปัจจุบัน
  String? get machineId => _machineId;
  String? _jobId; // เก็บ Job ID ปัจจุบัน
  String? get jobId => _jobId;

  Stream<List<DocumentRecordWithTagAndProblem>>? _recordsStream; // Stream ของบันทึกที่จะแสดงผล
  Stream<List<DocumentRecordWithTagAndProblem>>? get recordsStream => _recordsStream;

  Stream<List<FlSpot>>? _chartDataStream; // Stream สำหรับข้อมูลกราฟ Local
  Stream<List<FlSpot>>? get chartDataStream => _chartDataStream;

  Stream<List<FlSpot>>? _onlineChartDataStream; // Stream สำหรับข้อมูลกราฟ Online
  Stream<List<FlSpot>>? get onlineChartDataStream => _onlineChartDataStream;

  bool _isLoading = false; // สถานะบ่งชี้ว่ากำลังโหลดหรือซิงค์ข้อมูล
  bool get isLoading => _isLoading;

  String _statusMessage = "กำลังโหลดบันทึก..."; // ข้อความสถานะที่แสดงใต้ AppBar
  String get statusMessage => _statusMessage;

  String? _syncMessage; // ข้อความสำหรับสถานะการซิงค์ (เช่น สำเร็จ/ล้มเหลวใน SnackBar)
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  final Map<int, String?> _recordErrors = {}; // Map เก็บข้อผิดพลาดการ Validate ของแต่ละ Record (UID เป็น Key)
  Map<int, String?> get recordErrors => _recordErrors;

  DbDocumentRecord? _selectedDocument; // บันทึกที่ถูกเลือกในปัจจุบัน (สำหรับ Copy/Delete)
  DbDocumentRecord? get selectedDocument => _selectedDocument;
  void selectDocument(DbDocumentRecord doc) {
    _selectedDocument = doc;
    notifyListeners();
  }
  void clearSelection() {
    _selectedDocument = null;
    notifyListeners();
  }

  // Constructor: กำหนดค่าเริ่มต้นของ DAOs, Services, และ Repositories
  DocumentRecordViewModel({required AppDatabase appDatabase})
      : _documentRecordRepository = DocumentRecordRepository(appDatabase: appDatabase),
        _loginRepository = LoginRepository(); // รับ instance Singleton ที่มีอยู่

  /// โหลดบันทึกเอกสารจาก Local Database ตาม documentId และ machineId.
  /// Method นี้ยัง Initialize บันทึกจาก JobTags หากยังไม่มีข้อมูล.
  Future<void> loadRecords(String documentId, String machineId, String jobId) async {
    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
    _jobId = jobId;
    _statusMessage = "กำลังดึงบันทึก...";
    notifyListeners();

    try {
      print('DocumentRecordViewModel: loadRecords ถูกเรียกด้วย DocID=$documentId, MachineID=$machineId, JobID=$jobId');

      // ขั้นตอนสำคัญ: Initialize บันทึกจาก Job Tags หากยังไม่มี
      await _documentRecordRepository.initializeRecordsFromJobTags(
        jobId: _jobId!,
        documentId: _documentId!,
        machineId: _machineId!,
      );
      _statusMessage = "บันทึกถูก Initialize/ตรวจสอบแล้ว.";
      print('DocumentRecordViewModel: บันทึกถูก Initialize แล้ว. กำลังโหลดจาก DB.');

      // โหลดบันทึกจริง (ซึ่งอาจเพิ่งถูก Initialize)
      _recordsStream = _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!,
        machineId: _machineId!,
      );

      // Listen ไปที่ Stream และแสดงผลเนื้อหาเพื่อ Debug
      _recordsStream?.listen((data) {
        print("DocumentRecordViewModel Stream: ได้รับ ${data.length} บันทึก.");
        if (data.isEmpty) {
          print("DocumentRecordViewModel Stream: ไม่พบบันทึกหลังจากโหลด.");
        } else {
          for (var recordWithTag in data) {
            print("  บันทึก: UID=${recordWithTag.documentRecord.uid}, TagName=${recordWithTag.jobTag?.tagName}, ค่า=${recordWithTag.documentRecord.value}, ประเภท Tag=${recordWithTag.jobTag?.tagType}");
          }
        }
      }, onError: (error) {
        print("DocumentRecordViewModel Stream ข้อผิดพลาด: $error");
      });

      _statusMessage = "บันทึกสำหรับ Document ID: $documentId, Machine ID: $machineId โหลดแล้ว.";
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลดบันทึกได้: $e";
      print("ข้อผิดพลาดในการโหลดบันทึก: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh บันทึกโดยโหลดใหม่จาก Repository.
  Future<void> refreshRecords() async {
    _isLoading = true;
    _syncMessage = "กำลัง Refresh บันทึก...";
    _statusMessage = "กำลัง Refresh บันทึก...";
    notifyListeners();

    try {
      if (_documentId != null && _machineId != null && _jobId != null) {
        // Re-initialize/ตรวจสอบบันทึกจาก tags (มีประโยชน์หากมีการซิงค์ tags ใหม่)
        await _documentRecordRepository.initializeRecordsFromJobTags(
          jobId: _jobId!,
          documentId: _documentId!,
          machineId: _machineId!,
        );
        await loadRecords(_documentId!, _machineId!, _jobId!); // โหลดใหม่จาก Local DB
      } else {
        _statusMessage = "ไม่สามารถ Refresh ได้: documentId, machineId หรือ jobId หายไป.";
      }
      _syncMessage = "บันทึก Refresh แล้ว!";
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการ Refresh บันทึก: $e";
      _statusMessage = "ข้อผิดพลาดในการ Refresh บันทึก.";
      print("ข้อผิดพลาดในการ Refresh บันทึก: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// โหลดข้อมูลกราฟสำหรับ Tag เฉพาะจาก Local Database.
  Future<void> loadChartData(String tagId) async {
    if (_documentId == null || _machineId == null || _jobId == null) {
      _syncMessage = "ไม่สามารถโหลดกราฟ: Missing documentId, machineId, or jobId.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _statusMessage = "กำลังดึงข้อมูลกราฟ Local...";
    notifyListeners();

    try {
      _chartDataStream = _documentRecordRepository.getChartDataStream(
        _jobId!, // ใช้ _jobId!
        _machineId!,
        tagId,
      );
      _statusMessage = "ข้อมูลกราฟ Local สำหรับ Tag ID: $tagId โหลดแล้ว.";
      print('DocumentRecordViewModel: Stream ข้อมูลกราฟ Local ถูก Initialize แล้วสำหรับ Tag ID: $tagId');
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลดข้อมูลกราฟ Local ได้: $e";
      print("ข้อผิดพลาดในการโหลดข้อมูลกราฟ Local: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// โหลดข้อมูลกราฟสำหรับ Tag เฉพาะจาก API (Online).
  Future<void> loadOnlineChartData(String tagId) async {
    if (_documentId == null || _machineId == null || _jobId == null) {
      _syncMessage = "ไม่สามารถโหลดกราฟ Online: Missing documentId, machineId, or jobId.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _statusMessage = "กำลังดึงข้อมูลกราฟ Online...";
    notifyListeners();

    try {
      _onlineChartDataStream = _documentRecordRepository.getOnlineChartDataStream(
        _jobId!,
        _machineId!,
        tagId,
      );
      _statusMessage = "ข้อมูลกราฟ Online สำหรับ Tag ID: $tagId โหลดแล้ว.";
      print('DocumentRecordViewModel: Stream ข้อมูลกราฟ Online ถูก Initialize แล้วสำหรับ Tag ID: $tagId');
    } catch (e) {
      _statusMessage = "ไม่สามารถโหลดข้อมูลกราฟ Online ได้: $e";
      print("ข้อผิดพลาดในการโหลดข้อมูลกราฟ Online: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// แยกฟังก์ชัน Validation สำหรับข้อมูลประเภทตัวเลข.
  /// คืนค่าข้อความ Error หาก Validation ไม่ผ่าน, คืนค่า null หากผ่าน.
  String? _validateNumberInput(int uid, String? newValue, DbJobTag? jobTag) {
    final String? specMin = jobTag?.specMin;
    final String? specMax = jobTag?.specMax;

    if (newValue == null || newValue.isEmpty) {
      return null; // ค่าว่างเปล่าไม่ถือเป็น Error ในการ Validation นี้ (จัดการโดย unReadable)
    }

    final double? numValue = double.tryParse(newValue);
    if (numValue == null) {
      return "กรุณาป้อนตัวเลขที่ถูกต้อง";
    }

    if (specMin != null && specMin.isNotEmpty) {
      final double? min = double.tryParse(specMin);
      if (min != null && numValue < min) {
        return "ค่าน้อยกว่าค่าต่ำสุด ($min).";
      }
    }
    if (specMax != null && specMax.isNotEmpty) {
      final double? max = double.tryParse(specMax);
      if (max != null && numValue > max) {
        return "ค่ามากกว่าค่าสูงสุด ($max).";
      }
    }
    return null; // Validation ผ่าน
  }

  /// อัปเดตค่าและ/หรือหมายเหตุของบันทึกเฉพาะที่ Local.
  /// รวมถึงการ Validate ตามประเภท Tag และ Specification ของ JobTag.
  Future<bool> updateRecordValue(int uid, String? newValue, String? newRemark, {String? newUnReadable, String? userId, int? newStatus}) async {
    _isLoading = true;
    _syncMessage = null; // ล้างข้อความ Sync โดยรวม
    _recordErrors[uid] = null; // ล้างข้อผิดพลาดเฉพาะบันทึกก่อน Validate
    _statusMessage = "กำลังอัปเดตบันทึก...";
    notifyListeners();

    try {
      // ดึงบันทึกปัจจุบันพร้อมข้อมูล Tag
      final recordWithTag = (await _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!, machineId: _machineId!,
      ).first).firstWhere((element) => element.documentRecord.uid == uid);

      final DbJobTag? jobTag = recordWithTag.jobTag;
      final String tagType = jobTag?.tagType ?? '';
      final String? specMin = jobTag?.specMin;
      final String? specMax = jobTag?.specMax;

      // --- Logic การ Validate (เฉพาะ Number) ---
      if (tagType == 'Number' && newValue != null && newValue.isNotEmpty) {
        final String? validationError = _validateNumberInput(uid, newValue, jobTag); // ใช้ _validateNumberInput
        if (validationError != null) {
          _recordErrors[uid] = validationError; // กำหนดข้อผิดพลาดเฉพาะ Field
          _statusMessage = "อัปเดตล้มเหลว: ${validationError}";
          notifyListeners();
          return false; // Validate ล้มเหลว
        }
      }
      // --- สิ้นสุด Logic การ Validate ---

      _recordErrors[uid] = null; // ล้างข้อผิดพลาดหาก Validate ผ่าน

      // ดึง User ID ปัจจุบัน
      final String? finalUserId = userId ?? _loginRepository.loggedInUser?.userId;
      
       // Determine the status to save based on the input 'newStatus' parameter.
      int statusToSet;
      DbDocumentRecord? currentRecordInDB;
      if (newStatus != null) { // ถ้า newStatus ถูกส่งมา (เช่น 0 จากการแก้ไข, 1 จาก Save All Changes)
        statusToSet = newStatus;
      } else { // ถ้า newStatus ไม่ได้ถูกส่งมา (หมายถึงการแก้ไขทั่วไปที่ยังไม่รู้สถานะสุดท้าย)
       currentRecordInDB = await _documentRecordRepository.getRecordByUid(uid);
        statusToSet = (currentRecordInDB?.status != 2) ? 0 : 2; // ถ้าไม่ใช่ Status 2 ให้เป็น 0, ถ้าเป็น 2 ให้คงเดิม
      }
      
      print('--- Debugging Status Update ---'); // <<< NEW Debug
      print('Record UID: $uid');
      print('newStatus param: $newStatus');
      print('Status from DB before logic: ${currentRecordInDB?.status}');
      print('Status calculated to set: $statusToSet');
      print('-----------------------------');
      final success = await _documentRecordRepository.updateRecordValue(
        uid: uid,
        newValue: newValue,
        newRemark: newRemark,
        newUnReadable: newUnReadable, // ส่งสถานะ unReadable
        userId: finalUserId, // ส่ง userId เพื่ออัปเดต CreateBy
        newStatus: statusToSet,
      );
      _syncMessage = success ? "อัปเดตบันทึกสำเร็จ!" : "ไม่สามารถอัปเดตบันทึกได้.";
      _statusMessage = success ? "บันทึกอัปเดตแล้ว." : "อัปเดตล้มเหลว.";
      notifyListeners();
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปเดตบันทึก: $e";
      _statusMessage = "อัปเดตล้มเหลว: $e";
      print("ข้อผิดพลาดในการอัปเดตบันทึก: $e");
      _recordErrors[uid] = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// อัปเดตสถานะ 'ไม่อ่านค่าได้' (unReadable) สำหรับบันทึกเฉพาะ.
  /// หาก unReadable เป็น true, Field 'value' จะถูกล้าง.
  /// Method นี้จะเรียก updateRecordValue() ภายใน.
  Future<bool> updateUnReadableStatus(int uid, bool isUnReadable) async {
    _isLoading = true;
    _syncMessage = null;
    _recordErrors[uid] = null; // ล้างข้อผิดพลาดเฉพาะบันทึก
    _statusMessage = "กำลังอัปเดตสถานะ 'ไม่อ่านค่าได้'...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!, machineId: _machineId!,
      ).first).firstWhere((element) => element.documentRecord.uid == uid);

      String? currentValue = recordWithTag.documentRecord.value;
      String? currentRemark = recordWithTag.documentRecord.remark;
      String newUnReadableStatus = isUnReadable ? 'true' : 'false';
      String? newValueToSet = isUnReadable ? '' : currentValue; // ล้างค่าถ้า 'ไม่อ่านค่าได้' เป็น true

      final String? currentUserId = _loginRepository.loggedInUser?.userId;
      
       
      final success = await _documentRecordRepository.updateRecordValue( // เรียกใช้เมธอด updateRecordValue เดียว
        uid: uid,
        newValue: newValueToSet, // ส่งค่าใหม่ (จะถูกล้างถ้า 'ไม่อ่านค่าได้' เป็น true)
        newRemark: currentRemark,
        newUnReadable: newUnReadableStatus, // ส่งสถานะ 'ไม่อ่านค่าได้'
        userId: currentUserId,
        newStatus: 0, // กำหนดสถานะเป็น 0 (แก้ไข) เพื่อไม่ให้เปลี่ยนแปลงสถานะอื่น
      );

      _syncMessage = success ? "สถานะ 'ไม่อ่านค่าได้' อัปเดตสำเร็จ!" : "ไม่สามารถอัปเดตสถานะ 'ไม่อ่านค่าได้' ได้.";
      _statusMessage = success ? "สถานะ 'ไม่อ่านค่าได้' อัปเดตแล้ว." : "อัปเดตสถานะล้มเหลว.";
      notifyListeners();
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปเดตสถานะ 'ไม่อ่านค่าได้': $e";
      _statusMessage = "อัปเดตสถานะล้มเหลว: $e";
      print("ข้อผิดพลาดในการอัปเดตสถานะ 'ไม่อ่านค่าได้': $e");
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ลบบันทึกเฉพาะ.
  Future<bool> deleteRecord(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังลบบันทึก...";
    notifyListeners();
    try {
      await _documentRecordRepository.deleteRecord(uid: uid);
      _syncMessage = "ลบบันทึกสำเร็จ!";
      _statusMessage = "บันทึกลบแล้ว.";
      return true;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการลบบันทึก: $e";
      _statusMessage = "ลบข้อมูลล้มเหลว: $e";
      print("ข้อผิดพลาดในการลบบันทึก: $e");
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Method สำหรับ trigger การคำนวณสำหรับบันทึกเฉพาะ.
  Future<void> calculateRecordValue(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _recordErrors[uid] = null;
    _statusMessage = "กำลังคำนวณค่า...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!, machineId: _machineId!,
      ).first).firstWhere((element) => element.documentRecord.uid == uid);

      final DbDocumentRecord record = recordWithTag.documentRecord;
      final DbJobTag? jobTag = recordWithTag.jobTag;

      if (jobTag == null || jobTag.valueType == null || jobTag.driftQueryStr == null || jobTag.driftQueryStr!.isEmpty) {
        _syncMessage = "ไม่สามารถคำนวณได้: ข้อมูล Tag, ประเภท หรือ QueryStr (สำหรับ Drift) ไม่ครบถ้วน.";
        _statusMessage = "คำนวณล้มเหลว.";
        _recordErrors[uid] = "Tag/DriftQueryStr Missing";
        return;
      }

      String? calculatedValue;
      String? errorMessage;

      if (jobTag.valueType == 'Calculate') {
        final result = await _documentRecordRepository.executeSqlCalculation(
          jobTag.driftQueryStr!,
          documentId: _documentId!,
          machineId: _machineId!,
        );
        if (result != null) {
          calculatedValue = result.toString();
        } else {
          errorMessage = "คำนวณด้วย SQL ล้มเหลว.";
        }
      } else if (jobTag.valueType == 'Formula') {
        final result = await _documentRecordRepository.evaluateFormula(
          jobTag.queryStr!,
          documentId: _documentId!,
          machineId: _machineId!,
          jobId: _jobId!,
          jobTag: jobTag,
        );
        if (result != null) {
          calculatedValue = result.toString();
        } else {
          errorMessage = "คำนวณด้วยสูตรล้มเหลว.";
        }
      } else {
        errorMessage = "ประเภทการคำนวณไม่ถูกต้อง: ${jobTag.valueType}.";
      }

      if (calculatedValue != null) {
        final success = await _documentRecordRepository.updateRecordValue(
          uid: record.uid,
          newValue: calculatedValue,
          newRemark: record.remark,
          userId: _loginRepository.loggedInUser?.userId, // ส่ง userId เมื่อคำนวณสำเร็จ
        );
        _syncMessage = success ? "คำนวณและอัปเดตค่าสำเร็จ!" : "คำนวณสำเร็จ แต่อัปเดตค่าไม่ได้.";
        _statusMessage = "ค่าถูกคำนวณแล้ว.";
      } else {
        _recordErrors[uid] = errorMessage;
        _syncMessage = errorMessage;
        _statusMessage = "คำนวณล้มเหลว.";
      }
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการคำนวณ: $e";
      _statusMessage = "คำนวณล้มเหลว.";
      print("ข้อผิดพลาดในการคำนวณ: $e");
      _recordErrors[uid] = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Method เพื่อบันทึกการเปลี่ยนแปลงทั้งหมดจากหน้าจอ (ถูกเรียกโดยปุ่ม Save)
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

    // ดึง Snapshot ของ Records ปัจจุบันจาก Stream (เพื่อให้ได้ข้อมูล JobTag ที่ถูกต้อง)
    final List<DocumentRecordWithTagAndProblem> currentRecordsSnapshot = 
        await (_recordsStream?.first ?? Future.value([]));

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
        uiValue = allComboBoxValues[record.uid];
      } else {
        uiValue = allControllers[record.uid]?.text;
      }
      
      // เปรียบเทียบกับค่าล่าสุดใน DB (ดึงมาใหม่เพื่อความแม่นยำ)
      final DbDocumentRecord? latestRecordInDB = await _documentRecordRepository.getRecordByUid(record.uid);
      
      bool valueChanged = uiValue != (latestRecordInDB?.value ?? '');
      bool remarkChanged = uiRemark != (latestRecordInDB?.remark ?? ''); // เปรียบเทียบกับค่า remark ปัจจุบัน
      // สำหรับ unReadable, ตรวจสอบสถานะใหม่จาก UI (ถ้าเป็น Number type และ empty/not empty)
      String newUnReadableStatus = (jobTag?.tagType == 'Number' && (uiValue?.isEmpty ?? false)) ? 'true' : 'false';
      bool unReadableStatusChanged = newUnReadableStatus != (latestRecordInDB?.unReadable ?? 'false');



      // Check if this specific record passed validation (no error for it)
      bool recordPassedIndividualValidation = (_recordErrors[record.uid] == null); // Error from _validateAllRecordsForValidation
       // Determine the status to apply for this record
      int statusToApply = latestRecordInDB?.status ?? 0; // Get current status from DB
      if (recordPassedIndividualValidation) { // If the record is valid
        if (statusToApply != 1 && statusToApply != 2) { // And its current status is not 1 or 2 (needs promotion)
          statusToApply = 1; // Set to 1 (Validated)
        }
        // If statusToApply is already 1 or 2, keep it.
      } else { // If record did NOT pass validation (has an error)
        statusToApply = 0; // Ensure its status is 0 (Validation Failed)
      }
         bool needsUpdateCall = valueChanged || remarkChanged || unReadableStatusChanged || (statusToApply != (latestRecordInDB?.status ?? 0));
      // ตรวจสอบว่ามีการเปลี่ยนแปลงจริงในค่า, หมายเหตุ, หรือสถานะ unReadable
        if (needsUpdateCall) {
        bool success;
        success = await _documentRecordRepository.updateRecordValue(
          uid: record.uid,
          newValue: uiValue, // Pass the current UI value
          newRemark: uiRemark, // Pass the current UI remark
          newUnReadable: (jobTag?.tagType == 'Number') ? newUnReadableStatus : null,
          userId: currentUserId,
          newStatus: statusToApply, // Pass the determined status
        );

        if (success) {
          updatedCount++;
          _recordErrors[record.uid] = null; // ล้าง Error สำหรับ Record นี้
        } else {
          allSucceeded = false;
          _recordErrors.putIfAbsent(record.uid, () => "บันทึกข้อมูลล้มเหลว"); // เก็บ Error
        }
      } else { // หากไม่มีการเปลี่ยนแปลง แต่ Record นี้มี Error จาก Validation
        if (_recordErrors[record.uid] != null) {
          allSucceeded = false; // ถ้ามี Error จาก Validation, ก็ถือว่าไม่สำเร็จ
        }
      }
    }

    if (allSucceeded) {
      _syncMessage = "บันทึกการเปลี่ยนแปลงทั้งหมดสำเร็จ ($updatedCount รายการ)!";
      _statusMessage = "บันทึกข้อมูลเรียบร้อย.";
    } else {
      _syncMessage = "บันทึกการเปลี่ยนแปลงบางรายการล้มเหลว. โปรดตรวจสอบข้อผิดพลาด.";
      _statusMessage = "บันทึกข้อมูลล้มเหลว.";
    }
    notifyListeners(); // แจ้ง UI ให้ Refresh/Rebuild
    await loadRecords(_documentId!, _machineId!, _jobId!); // โหลดบันทึกจาก DB ใหม่ เพื่อให้ UI แสดงผลสถานะล่าสุด
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

    final List<DocumentRecordWithTagAndProblem> currentRecordsSnapshot = 
        await (_recordsStream?.first ?? Future.value([]));

    for (final recordWithTag in currentRecordsSnapshot) {
      final DbDocumentRecord record = recordWithTag.documentRecord;
      final DbJobTag? jobTag = recordWithTag.jobTag;
      
      String? uiValue;
      // ดึงค่าจาก Record object โดยตรง (ซึ่งควรเป็นค่าล่าสุดจาก DB แล้ว)
      uiValue = record.value?.trim();
      String? uiRemark = record.remark?.trim();

      print('Validating record UID ${record.uid}: TagName ${jobTag?.tagName}: Record value "${record.value}", UI value: "$uiValue"');


      String? validationErrorForThisRecord;

      // --- 1. Auto-populate User ID for 'User' TagType (เทียบเท่า updateUserTag) ---
      if (jobTag?.tagType == 'User') {
        if (currentUserId != null && currentUserId.isNotEmpty && (uiValue == null || uiValue.isEmpty)) {
          uiValue = currentUserId; // กำหนด userId อัตโนมัติ
          allControllers[record.uid]?.text = currentUserId; // อัปเดต UI Controller ด้วย (เพื่อให้ UI แสดงค่า)
          // บันทึกลง DB ทันที (เพราะถือว่าเป็นการเปลี่ยนแปลงที่สำคัญ)
          await _documentRecordRepository.updateRecordValue(
            uid: record.uid,
            newValue: currentUserId,
            newRemark: record.remark,
            userId: currentUserId,
            newStatus: 0, // ตั้ง Status เป็น 0 เมื่อมีการแก้ไข/Auto-populate
          );
          print('Auto-filled User ID for record UID ${record.uid}: $currentUserId');
        } else if ((uiValue == null || uiValue == '') && (currentUserId == null || currentUserId.isEmpty)) { // <<< Changed uiValue.isEmpty to uiValue == '' for clarity if trimmed.
          validationErrorForThisRecord = "กรุณาเข้าสู่ระบบ หรือ ซิงค์ข้อมูลผู้ใช้ เพื่อกรอก User ID อัตโนมัติ.";
          allRecordsValid = false;
        }
      }

      // --- 2. Required Field Validation (สำหรับทุก Record) ---
      // กฎ: ทุก Record ต้องมีข้อมูล (uiValue ไม่ว่างเปล่า)
      // ยกเว้น: Number ที่เลือก N/A
      
      // ตรวจสอบสถานะ unReadable สำหรับ Number (จาก DB ล่าสุด)
      final DbDocumentRecord? latestRecordInDB = await _documentRecordRepository.getRecordByUid(record.uid);
      bool isCurrentlyUnReadable = (jobTag?.tagType == 'Number' && (latestRecordInDB?.unReadable == 'true'));

      if (uiValue == null || uiValue == '') { // <<< Changed uiValue.isEmpty to uiValue == '' for clarity if trimmed.
        if (jobTag?.tagType == 'Number') {
          if (!isCurrentlyUnReadable) { // ถ้าเป็น Number แต่ไม่ได้เลือก N/A = Error
            validationErrorForThisRecord = "จำเป็นต้องกรอกข้อมูลตัวเลข.";
            allRecordsValid = false;
          }
        } else if (jobTag?.tagType != 'Problem') { // Tag Type อื่นๆ (Text, ComboBox, CheckBox) ถือเป็น Required ถ้าว่างเปล่า
          validationErrorForThisRecord = "จำเป็นต้องกรอกข้อมูล.";
          allRecordsValid = false;
        }
      }
      
      // --- 3. Mandatory Remark for N/A Number ---
      if (jobTag?.tagType == 'Number' && isCurrentlyUnReadable) {
        if (uiRemark == null || uiRemark.isEmpty) {
          validationErrorForThisRecord = "เมื่อ 'ไม่อ่านค่าได้' ต้องระบุหมายเหตุ.";
          allRecordsValid = false;
        }
      }

      // --- 4. Type-specific validation (สำหรับค่าที่ไม่ว่างเปล่า และยังไม่มี Error) ---
      if (validationErrorForThisRecord == null && uiValue != null && uiValue.isNotEmpty) {
        if (jobTag?.tagType == 'Number') {
          validationErrorForThisRecord = _validateNumberInput(record.uid, uiValue, jobTag);
          if (validationErrorForThisRecord != null) {
            allRecordsValid = false;
          }
        }
      }

      // --- สิ้นสุด Validation Rules ---

      if (validationErrorForThisRecord != null) {
        _recordErrors[record.uid] = validationErrorForThisRecord;
      } else {
        _recordErrors[record.uid] = null; // Clear any existing error for this record
      }
    }

    notifyListeners();
    return allRecordsValid;
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

  /// NEW: Method เพื่อส่งข้อมูลบันทึกที่ Validate แล้วขึ้น Server.
  Future<bool> uploadAllChangesToServer() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "กำลังส่งข้อมูลบันทึกขึ้น Server...";
    notifyListeners();

    // ตรวจสอบว่ามี DocumentId, MachineId, JobId ครบถ้วน
    if (_documentId == null || _machineId == null || _jobId == null) {
      _syncMessage = "ไม่สามารถส่งข้อมูลได้: ข้อมูล Document/Machine/Job ID ไม่ครบถ้วน.";
      _statusMessage = "ส่งข้อมูลล้มเหลว.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // เรียก Repository เพื่ออัปโหลด Records ที่มี Status 1
      final success = await _documentRecordRepository.uploadRecordsToServer(
        documentId: _documentId!,
        machineId: _machineId!,
        jobId: _jobId!,
      );

      if (success) {
        _syncMessage = "ส่งข้อมูลขึ้น Server สำเร็จแล้ว!";
        _statusMessage = "ข้อมูลถูกส่งแล้ว.";
        // Reload records to reflect updated status (to 2)
        await loadRecords(_documentId!, _machineId!, _jobId!);
      } else {
        _syncMessage = "ไม่สามารถส่งข้อมูลขึ้น Server ได้.";
        _statusMessage = "ส่งข้อมูลล้มเหลว.";
      }
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการส่งข้อมูลขึ้น Server: $e";
      _statusMessage = "ส่งข้อมูลล้มเหลว: $e";
      print("Error uploading records to server: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
}
