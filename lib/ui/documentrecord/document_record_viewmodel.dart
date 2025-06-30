// lib/ui/documentrecord/document_record_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:drift/drift.dart' as drift; // Alias drift

// NEW: Import for charts
import 'package:fl_chart/fl_chart.dart'; // For FlSpot
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // <<< NEW: Import LoginRepository for userId

/// Equivalent to DocumentRecordViewModel.kt
class DocumentRecordViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;
  final LoginRepository _loginRepository; // <<< NEW: Access logged-in user

  String? _documentId;
  String? get documentId => _documentId;
  String? _machineId;
  String? get machineId => _machineId;
  String? _jobId; // NEW: Need jobId to initialize records from job tags

  Stream<List<DocumentRecordWithTagAndProblem>>? _recordsStream;
  Stream<List<DocumentRecordWithTagAndProblem>>? get recordsStream =>
      _recordsStream;

  // NEW: Stream for chart data
  Stream<List<FlSpot>>? _chartDataStream;
  Stream<List<FlSpot>>? get chartDataStream => _chartDataStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusMessage = "Loading records...";
  String get statusMessage => _statusMessage;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  // NEW: Map to store validation errors for each record's UID
  final Map<int, String?> _recordErrors = {};
  Map<int, String?> get recordErrors => _recordErrors;

  // Currently selected document (for copy/delete operations)
  DbDocumentRecord?
      _selectedDocument; // Note: This is DbDocumentRecord, not DbDocument
  DbDocumentRecord? get selectedDocument => _selectedDocument;

  //NEW: Stream for online chart data
  Stream<List<FlSpot>>? _onlineChartDataStream;
  Stream<List<FlSpot>>? get onlineChartDataStream => _onlineChartDataStream;

  void selectDocument(DbDocumentRecord doc) {
    _selectedDocument = doc;
    notifyListeners();
  }

  void clearSelection() {
    _selectedDocument = null;
    notifyListeners();
  }

  DocumentRecordViewModel({required AppDatabase appDatabase})
      : _documentRecordRepository =
            DocumentRecordRepository(appDatabase: appDatabase),
        _loginRepository =
            LoginRepository(); // รับ instance Singleton ที่มีอยู่
  /// Loads document records for the specified documentId and machineId.
  Future<void> loadRecords(
      String documentId, String machineId, String jobId) async {
    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
    _jobId = jobId; // Store jobId
    _statusMessage = "Fetching records...";
    notifyListeners();

    try {
      print(
          'DocumentRecordViewModel: loadRecords called with DocID=$documentId, MachineID=$machineId, JobID=$jobId'); // <<< Debugging

      await _documentRecordRepository.initializeRecordsFromJobTags(
        jobId: _jobId!, // Use stored jobId
        documentId: _documentId!, // Use stored documentId
        machineId: _machineId!, // Use stored machineId
      );
      _statusMessage = "Records initialized/checked.";
      print(
          'DocumentRecordViewModel: Records initialized. Now loading from DB.'); // <<< Debugging

      _recordsStream = _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: documentId,
        machineId: machineId,
      );

      _recordsStream?.listen((data) {
        print(
            "DocumentRecordViewModel Stream: Received ${data.length} records.");
        if (data.isEmpty) {
          print(
              "DocumentRecordViewModel Stream: No records found after loading.");
        } else {
          for (var recordWithTag in data) {
            print(
                "  Record: UID=${recordWithTag.documentRecord.uid}, TagName=${recordWithTag.jobTag?.tagName}, Value=${recordWithTag.documentRecord.value}, TagType=${recordWithTag.jobTag?.tagType}");
          }
        }
      }, onError: (error) {
        print("DocumentRecordViewModel Stream Error: $error");
      });

      _statusMessage =
          "Records for Document ID: $documentId, Machine ID: $machineId loaded.";
    } catch (e) {
      _statusMessage = "Failed to load records: $e";
      print("Error loading records: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes records by re-loading them from the repository.
  Future<void> refreshRecords() async {
    _isLoading = true;
    _syncMessage = "Refreshing records...";
    _statusMessage = "Refreshing records...";
    notifyListeners();

    try {
      if (_documentId != null && _machineId != null && _jobId != null) {
        await _documentRecordRepository.initializeRecordsFromJobTags(
          jobId: _jobId!,
          documentId: _documentId!,
          machineId: _machineId!,
        );
        await loadRecords(_documentId!, _machineId!, _jobId!);
      } else {
        _statusMessage =
            "Cannot refresh: documentId, machineId or jobId is missing.";
      }
      _syncMessage = "Records refreshed!";
    } on Exception catch (e) {
      _syncMessage = "Error refreshing records: $e";
      _statusMessage = "Error refreshing records.";
      print("Error refreshing records: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Corrected: Loads chart data for a specific tag within the current job and machine.
  Future<void> loadChartData(String tagId) async {
    if (_documentId == null || _machineId == null || _jobId == null) {
      _syncMessage =
          "Cannot load chart: Missing documentId, machineId, or jobId.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _statusMessage = "Fetching chart data...";
    notifyListeners();

    try {
      _chartDataStream = _documentRecordRepository.getChartDataStream(
        _jobId!, // <<< Changed to _jobId!
        _machineId!,
        tagId,
      );
      _statusMessage = "Chart data for Tag ID: $tagId loaded.";
      print(
          'DocumentRecordViewModel: Chart data stream initialized for Tag ID: $tagId');
    } catch (e) {
      _statusMessage = "Failed to load chart data: $e";
      print("Error loading chart data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Loads chart data for a specific tag from API (online)
  Future<void> loadOnlineChartData(String tagId) async {
    if (_documentId == null || _machineId == null || _jobId == null) {
      _syncMessage =
          "Cannot load online chart: Missing documentId, machineId, or jobId.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _statusMessage = "Fetching online chart data...";
    notifyListeners();

    try {
      _onlineChartDataStream =
          _documentRecordRepository.getOnlineChartDataStream(
        _jobId!,
        _machineId!,
        tagId,
      );
      _statusMessage = "Online chart data for Tag ID: $tagId loaded.";
      print(
          'DocumentRecordViewModel: Online chart data stream initialized for Tag ID: $tagId');
    } catch (e) {
      _statusMessage = "Failed to load online chart data: $e";
      print("Error loading online chart data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the value and/or remark of a specific record locally.
  /// Updates the value and/or remark of a specific record locally.
  /// Includes validation based on tagType and jobTag specifications.
  Future<bool> updateRecordValue(
      int uid, String? newValue, String? newRemark) async {
    _isLoading = true;
    _syncMessage = null;
    _recordErrors[uid] = null;
    _statusMessage = "Updating record...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository
              .loadRecordsForDocumentMachine(
                documentId: _documentId!,
                machineId: _machineId!,
              )
              .first)
          .firstWhere((element) => element.documentRecord.uid == uid);

      // Get current record's status from DB for comparison
      final DbDocumentRecord? currentRecordInDB =
          await _documentRecordRepository.getRecordByUid(uid);
      int statusToSet = currentRecordInDB?.status ??
          0; // Default to 0 if not found, or use current

      // Set status to 0 if record is being edited AND is not already 2 (Posted)
      if (statusToSet != 2) {
        // Do not change status if already Posted
        statusToSet = 0;
      }

      final DbJobTag? jobTag = recordWithTag.jobTag;
      final String tagType = jobTag?.tagType ?? '';
      final String? specMin = jobTag?.specMin;
      final String? specMax = jobTag?.specMax;

      // --- Validation Logic ---
      if (tagType == 'Number' && newValue != null && newValue.isNotEmpty) {
        final double? numValue = double.tryParse(newValue);
        if (numValue == null) {
          _recordErrors[uid] = "กรุณาป้อนตัวเลขที่ถูกต้อง";
          _statusMessage = "อัปเดตล้มเหลว: รูปแบบตัวเลขไม่ถูกต้อง.";
          notifyListeners();
          return false;
        }

        if (specMin != null && specMin.isNotEmpty) {
          final double? min = double.tryParse(specMin);
          if (min != null && numValue < min) {
            _recordErrors[uid] = "ค่าน้อยกว่าค่าต่ำสุด ($min).";
            _statusMessage = "อัปเดตล้มเหลว: ค่าอยู่นอกช่วง.";
            notifyListeners();
            return false;
          }
        }
        if (specMax != null && specMax.isNotEmpty) {
          final double? max = double.tryParse(specMax);
          if (max != null && numValue > max) {
            _recordErrors[uid] = "ค่ามากกว่าค่าสูงสุด ($max).";
            _statusMessage = "อัปเดตล้มเหลว: ค่าอยู่นอกช่วง.";
            notifyListeners();
            return false;
          }
        }
      }
      // --- End Validation Logic ---

      _recordErrors[uid] = null; // Clear error if validation passes.

      final String? currentUserId = _loginRepository.loggedInUser?.userId;

      // Corrected: Call the single updateRecordValue method in repository
      final success = await _documentRecordRepository.updateRecordValue(
        uid: uid,
        newValue: newValue,
        newRemark: newRemark,
        userId: currentUserId,
        newStatus: statusToSet, // <<< ส่ง Status ที่ปรับแล้ว
      );
      _syncMessage =
          success ? "อัปเดตบันทึกสำเร็จ!" : "ไม่สามารถอัปเดตบันทึกได้.";
      _statusMessage = success ? "บันทึกอัปเดตแล้ว." : "อัปเดตล้มเหลว.";
      notifyListeners();
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปเดตบันทึก: $e";
      _statusMessage = "อัปเดตล้มเหลว: $e";
      print("Error updating record: $e");
      _recordErrors[uid] = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Corrected: updateUnReadableStatus now calls the single updateRecordValue
  Future<bool> updateUnReadableStatus(int uid, bool isUnReadable) async {
    _isLoading = true;
    _syncMessage = null;
    _recordErrors[uid] = null;
    _statusMessage = "Updating unReadable status...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository
              .loadRecordsForDocumentMachine(
                documentId: _documentId!,
                machineId: _machineId!,
              )
              .first)
          .firstWhere((element) => element.documentRecord.uid == uid);

      String? currentValue = recordWithTag.documentRecord.value;
      String? currentRemark = recordWithTag.documentRecord.remark;
      String newUnReadableStatus = isUnReadable ? 'true' : 'false';
      String? newValueToSet = isUnReadable ? '' : currentValue;

      // Get current record's status from DB for comparison
      final DbDocumentRecord? currentRecordInDB =
          await _documentRecordRepository.getRecordByUid(uid);
      int statusToSet = currentRecordInDB?.status ??
          0; // Default to 0 if not found, or use current

      // Set status to 0 if record is being edited AND is not already 2 (Posted)
      if (statusToSet != 2) {
        // Do not change status if already Posted
        statusToSet = 0;
      }

      final String? currentUserId = _loginRepository.loggedInUser?.userId;

      // Corrected: Call the single updateRecordValue method in repository
      final success = await _documentRecordRepository.updateRecordValue(
        // <<< Call the single method
        uid: uid,
        newValue:
            newValueToSet, // Pass the new value (cleared if unReadable is true)
        newRemark: currentRemark,
        newUnReadable: newUnReadableStatus, // Pass the unReadable status
        userId: currentUserId,
        newStatus: statusToSet, // <<< ส่ง Status ที่ปรับแล้ว
      );

      _syncMessage = success
          ? "สถานะ 'ไม่อ่านค่าได้' อัปเดตสำเร็จ!"
          : "ไม่สามารถอัปเดตสถานะ 'ไม่อ่านค่าได้' ได้.";
      _statusMessage =
          success ? "สถานะ 'ไม่อ่านค่าได้' อัปเดตแล้ว." : "อัปเดตสถานะล้มเหลว.";
      notifyListeners();
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปเดตสถานะ 'ไม่อ่านค่าได้': $e";
      _statusMessage = "อัปเดตสถานะล้มเหลว: $e";
      print("Error updating unReadable status: $e");
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Method to save all changes from the screen (triggered by Save button)
  // NEW: Method to save all changes from the screen (triggered by Save button)

  Future<bool> deleteRecord(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "Deleting record...";
    notifyListeners();
    try {
      await _documentRecordRepository.deleteRecord(uid: uid);
      _syncMessage = "Record deleted successfully!";
      _statusMessage = "Record deleted.";
      return true;
    } on Exception catch (e) {
      _syncMessage = "Error deleting record: $e";
      _statusMessage = "Delete failed: $e";
      print("Error deleting record: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Method to trigger calculation for a specific record
  Future<void> calculateRecordValue(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _recordErrors[uid] = null;
    _statusMessage = "Calculating value...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository
              .loadRecordsForDocumentMachine(
                documentId: _documentId!,
                machineId: _machineId!,
              )
              .first)
          .firstWhere((element) => element.documentRecord.uid == uid);

      final DbDocumentRecord record = recordWithTag.documentRecord;
      final DbJobTag? jobTag = recordWithTag.jobTag;

      if (jobTag == null ||
          jobTag.valueType == null ||
          jobTag.driftQueryStr == null ||
          jobTag.driftQueryStr!.isEmpty) {
        _syncMessage =
            "ไม่สามารถคำนวณได้: ข้อมูล Tag, ประเภท หรือ QueryStr (สำหรับ Drift) ไม่ครบถ้วน.";
        _statusMessage = "คำนวณล้มเหลว.";
        _recordErrors[uid] = "Tag/DriftQueryStr Missing";
        return;
      }

      String? calculatedValue;
      String? errorMessage;
      print(
          "Calculating record value for UID: $uid, JobTag: ${jobTag.tagName}, ValueType: ${jobTag.valueType}");
      if (jobTag.valueType == 'Calculate') {
        // Corrected: Pass documentId and machineId as parameters for the SQL query
        final result = await _documentRecordRepository.executeSqlCalculation(
          jobTag.driftQueryStr!,
          documentId: _documentId!, // <<< Pass documentId
          machineId: _machineId!, // <<< Pass machineId
        );
        if (result != null) {
          calculatedValue = result.toString();
        } else {
          errorMessage = "คำนวณด้วย SQL ล้มเหลว.";
        }
      } else if (jobTag.valueType == 'Formula') {
        // Evaluate predefined formula using driftQueryStr
        final result = await _documentRecordRepository.evaluateFormula(
          jobTag
              .queryStr!, // Still use original queryStr for general formula name
          documentId: _documentId!,
          machineId: _machineId!,
          jobId: _jobId!,
          jobTag: jobTag, // Pass the jobTag itself
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
          newStatus: 0, // <<< เมื่อคำนวณแล้ว ค่าเปลี่ยน, Status เป็น 0
        );
        _syncMessage = success
            ? "คำนวณและอัปเดตค่าสำเร็จ!"
            : "คำนวณสำเร็จ แต่อัปเดตค่าไม่ได้.";
        _statusMessage = "ค่าถูกคำนวณแล้ว.";
      } else {
        _recordErrors[uid] = errorMessage;
        _syncMessage = errorMessage;
        _statusMessage = "คำนวณล้มเหลว.";
      }
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการคำนวณ: $e";
      _statusMessage = "คำนวณล้มเหลว.";
      print("Error calculating record value: $e");
      _recordErrors[uid] = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Method เพื่อบันทึกการเปลี่ยนแปลงทั้งหมดจากหน้าจอ (ถูกเรียกโดยปุ่ม Save)
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
      print("DocumentRecordViewModel: Validation failed, not saving changes.");
      return false; // หยุดการทำงานถ้า Validation ไม่ผ่าน
    }

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
      if (jobTag?.tagType == 'ComboBox' || jobTag?.tagType == 'CheckBox') {
        uiValue = record.value; //allComboBoxValues[record.uid]?.trim();
        print(
            'saveAllChanges ComboBox/CheckBox for record UID ${record.uid}:TagName ${jobTag?.tagName}: Record value ${record.value}, UI value: "$uiValue"');
      } else {
        uiValue = record.value; //allControllers[record.uid]?.text.trim();
        print(
            'saveAllChanges TextField for record UID ${record.uid}: TagName ${jobTag?.tagName}:Record value ${record.value}, UI value: "$uiValue"');
      }
      String? uiRemark = record.remark?.trim();

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

      // Check if this record passed its individual validation
      bool recordPassedIndividualValidation =
          (_recordErrors[record.uid] == null);
      // ตรวจสอบว่ามีการเปลี่ยนแปลงจริงในค่า, หมายเหตุ, หรือสถานะ unReadable

      // Only update if there's an actual change in value, remark, unReadable,
      // OR if the record is currently valid AND its status is not yet 1.
      /*
      if (recordPassedIndividualValidation &&
          (valueChanged ||
              remarkChanged ||
              unReadableStatusChanged ||
              (latestRecordInDB?.status != 1))) {
        bool success;
        success = await _documentRecordRepository.updateRecordValue(
          uid: record.uid,
          newValue: uiValue,
          newRemark: uiRemark,
          newUnReadable:
              (jobTag?.tagType == 'Number') ? newUnReadableStatus : null,
          userId: currentUserId,
          newStatus: 1, // <<< เมื่อ Validate ผ่านแล้ว บันทึก Status เป็น 1
        );
        */

      if (recordPassedIndividualValidation) {
        bool success;
        success = await _documentRecordRepository.updateRecordValue(
          uid: record.uid,
          newValue: uiValue,
          newRemark: uiRemark,
          newUnReadable:
              (jobTag?.tagType == 'Number') ? newUnReadableStatus : null,
          userId: currentUserId,
          newStatus: 1, // <<< เมื่อ Validate ผ่านแล้ว บันทึก Status เป็น 1
        );

        if (success) {
          updatedCount++;
          _recordErrors[record.uid] = null; // ล้าง Error สำหรับ Record นี้
        } else {
          allSucceeded = false;
          _recordErrors.putIfAbsent(
              record.uid, () => "บันทึกข้อมูลล้มเหลว"); // เก็บ Error
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
    notifyListeners(); // แจ้ง UI ให้ Refresh/Rebuild
    await loadRecords(_documentId!, _machineId!,
        _jobId!); // โหลดบันทึกจาก DB ใหม่ เพื่อให้ UI แสดงผลสถานะล่าสุด
    return allSucceeded;
  }

// NEW: แยกฟังก์ชัน Validation สำหรับข้อมูลประเภทตัวเลข.
  // คืนค่าข้อความ Error หาก Validation ไม่ผ่าน, คืนค่า null หากผ่าน.
  /// คืนค่าข้อความ Error หาก Validation ไม่ผ่าน, คืนค่า null หากผ่าน.
  String? _validateNumberInput(int uid, String? newValue, DbJobTag? jobTag) {
    final String? specMin = jobTag?.specMin;
    final String? specMax = jobTag?.specMax;

    // newValue ว่างเปล่า จะไม่ถูก validate ในส่วนนี้ (จัดการโดย Required check หรือ unReadable check)
    if (newValue == null || newValue.isEmpty) {
      return null;
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
      if (jobTag?.tagType == 'ComboBox' || jobTag?.tagType == 'CheckBox') {
        //uiValue = allComboBoxValues[record.uid]?.trim();
        uiValue = record.value?.trim();

        print(
            'Validating ComboBox/CheckBox for record UID ${record.uid}:TagName ${jobTag?.tagName}: Record value ${record.value}, UI value: "$uiValue"');
      } else {
        uiValue = record.value?.trim();
        print(
            'Validating TextField for record UID ${record.uid}: TagName ${jobTag?.tagName}:Record value ${record.value}, UI value: "$uiValue"');
      }
      String? uiRemark = record.remark?.trim();
      String? validationErrorForThisRecord; // Error สำหรับ Record ปัจจุบันนี้

      // --- 1. Auto-populate User ID for 'User' TagType (เทียบเท่า updateUserTag) ---
      if (jobTag?.tagType == 'User') {
        if (currentUserId != null &&
            currentUserId.isNotEmpty &&
            (uiValue == null || uiValue.isEmpty)) {
          uiValue = currentUserId; // กำหนด userId อัตโนมัติ
          allControllers[record.uid]?.text =
              currentUserId; // อัปเดต UI Controller ด้วย
          // บันทึกลง DB ทันที (เพราะถือว่าเป็นการเปลี่ยนแปลงที่สำคัญ)
          await _documentRecordRepository.updateRecordValue(
            uid: record.uid,
            newValue: currentUserId,
            newRemark: record.remark,
            userId: currentUserId,
            newStatus: 0, // ตั้ง Status เป็น 0 เมื่อมีการแก้ไข/Auto-populate
          );
          print(
              'Auto-filled User ID for record UID ${record.uid}: $currentUserId');
        } else if ((uiValue == null || uiValue.isEmpty) &&
            (currentUserId == null || currentUserId.isEmpty)) {
          // ถ้าเป็น User Tag และช่องว่างเปล่า และไม่มี userId ผู้ใช้ปัจจุบัน
          validationErrorForThisRecord =
              "กรุณาเข้าสู่ระบบ หรือ ซิงค์ข้อมูลผู้ใช้ เพื่อกรอก User ID อัตโนมัติ.";
          allRecordsValid = false;
        }
      }

      // --- 2. Required Field Validation (สำหรับทุก Record ยกเว้น Number ที่เลือก N/A) ---
      // ตรวจสอบว่า Record นี้ถูกตั้งค่าว่า unReadable หรือไม่ (สำหรับ Number Type)
      final DbDocumentRecord? latestRecordInDB =
          await _documentRecordRepository.getRecordByUid(record.uid);
      bool isCurrentlyUnReadable = (jobTag?.tagType == 'Number' &&
          (latestRecordInDB?.unReadable == 'true'));

      if (uiValue == null || uiValue.isEmpty) {
        if (jobTag?.tagType == 'Number') {
          if (!isCurrentlyUnReadable) {
            validationErrorForThisRecord = "จำเป็นต้องกรอกข้อมูลตัวเลข.";
            allRecordsValid = false;
          }
        } else if (jobTag?.tagType != 'Problem') {
          validationErrorForThisRecord = "จำเป็นต้องกรอกข้อมูล.";
          allRecordsValid = false;
        }
      }

      // --- 3. Mandatory Remark for N/A Number ---
      if (validationErrorForThisRecord == null &&
          jobTag?.tagType == 'Number' &&
          isCurrentlyUnReadable) {
        if (uiRemark == null || uiRemark.isEmpty) {
          validationErrorForThisRecord =
              "เมื่อ 'ไม่อ่านค่าได้' ต้องระบุหมายเหตุ.";
          allRecordsValid = false;
        }
      }

      // --- 4. Type-specific validation ---
      if (validationErrorForThisRecord == null &&
          uiValue != null &&
          uiValue.isNotEmpty) {
        if (jobTag?.tagType == 'Number') {
          validationErrorForThisRecord =
              _validateNumberInput(record.uid, uiValue, jobTag);
          if (validationErrorForThisRecord != null) {
            allRecordsValid = false;
          }
        }
      }

      // --- สิ้นสุด Validation Rules ---

      // กำหนด Error หรือล้าง Error สำหรับ Record นี้
      if (validationErrorForThisRecord != null) {
        _recordErrors[record.uid] = validationErrorForThisRecord;
        notifyListeners(); // แจ้ง UI ให้แสดงผล Validation Errors
      } else {
        _recordErrors[record.uid] = null;
      }
    }

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
}
