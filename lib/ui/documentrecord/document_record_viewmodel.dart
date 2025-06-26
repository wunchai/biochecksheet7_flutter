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

/// Equivalent to DocumentRecordViewModel.kt
class DocumentRecordViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;

  String? _documentId;
  String? get documentId => _documentId;
  String? _machineId;
  String? get machineId => _machineId;
  String? _jobId; // NEW: Need jobId to initialize records from job tags

  Stream<List<DocumentRecordWithTagAndProblem>>? _recordsStream;
  Stream<List<DocumentRecordWithTagAndProblem>>? get recordsStream => _recordsStream;

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
  DbDocumentRecord? _selectedDocument; // Note: This is DbDocumentRecord, not DbDocument
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
      : _documentRecordRepository = DocumentRecordRepository(appDatabase: appDatabase);

  /// Loads document records for the specified documentId and machineId.
  Future<void> loadRecords(String documentId, String machineId, String jobId) async {
    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
     _jobId = jobId; // Store jobId
    _statusMessage = "Fetching records...";
    notifyListeners();

    try {
       print('DocumentRecordViewModel: loadRecords called with DocID=$documentId, MachineID=$machineId, JobID=$jobId'); // <<< Debugging
        
        await _documentRecordRepository.initializeRecordsFromJobTags(
        jobId: _jobId!, // Use stored jobId
        documentId: _documentId!, // Use stored documentId
        machineId: _machineId!, // Use stored machineId
      );
      _statusMessage = "Records initialized/checked.";
        print('DocumentRecordViewModel: Records initialized. Now loading from DB.'); // <<< Debugging
     
      _recordsStream = _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: documentId,
        machineId: machineId,
      );

      _recordsStream?.listen((data) {
        print("DocumentRecordViewModel Stream: Received ${data.length} records.");
        if (data.isEmpty) {
          print("DocumentRecordViewModel Stream: No records found after loading.");
        } else {
          for (var recordWithTag in data) {
            print("  Record: UID=${recordWithTag.documentRecord.uid}, TagName=${recordWithTag.jobTag?.tagName}, Value=${recordWithTag.documentRecord.value}, TagType=${recordWithTag.jobTag?.tagType}");
          }
        }
      }, onError: (error) {
        print("DocumentRecordViewModel Stream Error: $error");
      });



      _statusMessage = "Records for Document ID: $documentId, Machine ID: $machineId loaded.";
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
        _statusMessage = "Cannot refresh: documentId, machineId or jobId is missing.";
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
      _syncMessage = "Cannot load chart: Missing documentId, machineId, or jobId.";
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
      print('DocumentRecordViewModel: Chart data stream initialized for Tag ID: $tagId');
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
      _syncMessage = "Cannot load online chart: Missing documentId, machineId, or jobId.";
      notifyListeners();
      return;
    }
    _isLoading = true;
    _statusMessage = "Fetching online chart data...";
    notifyListeners();

    try {
      _onlineChartDataStream = _documentRecordRepository.getOnlineChartDataStream(
        _jobId!,
        _machineId!,
        tagId,
      );
      _statusMessage = "Online chart data for Tag ID: $tagId loaded.";
      print('DocumentRecordViewModel: Online chart data stream initialized for Tag ID: $tagId');
    } catch (e) {
      _statusMessage = "Failed to load online chart data: $e";
      print("Error loading online chart data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
/// Updates the value and/or remark of a specific record locally.
  /// Includes validation based on tagType and jobTag specifications.
  /// Displays validation errors directly on the input field.
  Future<bool> updateRecordValue(int uid, String? newValue, String? newRemark) async {
    _isLoading = true;
    _syncMessage = null; // Clear overall sync message.
    _recordErrors[uid] = null; // NEW: Clear specific record error before validation.
    _statusMessage = "Updating record...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!, machineId: _machineId!,
      ).first).firstWhere((element) => element.documentRecord.uid == uid);

      final DbJobTag? jobTag = recordWithTag.jobTag;
      final String tagType = jobTag?.tagType ?? '';
      final String? specMin = jobTag?.specMin;
      final String? specMax = jobTag?.specMax;

      // --- Validation Logic ---
      if (tagType == 'Number' && newValue != null && newValue.isNotEmpty) {
        final double? numValue = double.tryParse(newValue);
        if (numValue == null) {
          _recordErrors[uid] = "กรุณาป้อนตัวเลขที่ถูกต้อง"; // NEW: Set specific error for field.
          _statusMessage = "อัปเดตล้มเหลว: รูปแบบตัวเลขไม่ถูกต้อง.";
          notifyListeners(); // Notify to update UI with error.
          return false; // Validation failed
        }

        if (specMin != null && specMin.isNotEmpty) {
          final double? min = double.tryParse(specMin);
          if (min != null && numValue < min) {
            _recordErrors[uid] = "ค่าน้อยกว่าค่าต่ำสุด ($min)."; // NEW: Set specific error.
            _statusMessage = "อัปเดตล้มเหลว: ค่าอยู่นอกช่วง.";
            notifyListeners();
            return false; // Validation failed
          }
        }
        if (specMax != null && specMax.isNotEmpty) {
          final double? max = double.tryParse(specMax);
          if (max != null && numValue > max) {
            _recordErrors[uid] = "ค่ามากกว่าค่าสูงสุด ($max)."; // NEW: Set specific error.
            _statusMessage = "อัปเดตล้มเหลว: ค่าอยู่นอกช่วง.";
            notifyListeners();
            return false; // Validation failed
          }
        }
      }
      // --- End Validation Logic ---

      // If validation passes, ensure error is cleared.
      _recordErrors[uid] = null;


      final success = await _documentRecordRepository.updateRecordValue(
        uid: uid,
        newValue: newValue,
        newRemark: newRemark,
      );
      _syncMessage = success ? "Record updated successfully!" : "Failed to update record.";
      _statusMessage = success ? "Record updated." : "Update failed.";
      return success;
    } on Exception catch (e) {
      _syncMessage = "Error updating record: $e";
      _statusMessage = "Update failed: $e";
      print("Error updating record: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

/// NEW: Updates the 'unReadable' status for a specific record.
  /// If unReadable is true, the value field is also cleared.
  Future<bool> updateUnReadableStatus(int uid, bool isUnReadable) async {
    _isLoading = true;
    _syncMessage = null;
    _recordErrors[uid] = null; // Clear any existing error for this record.
    _statusMessage = "Updating unReadable status...";
    notifyListeners();

    try {
      final recordWithTag = (await _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: _documentId!, machineId: _machineId!,
      ).first).firstWhere((element) => element.documentRecord.uid == uid);

      // Get current values
      String? currentValue = recordWithTag.documentRecord.value;
      String? currentRemark = recordWithTag.documentRecord.remark;

      // Determine new value based on unReadable status
      String newUnReadableStatus = isUnReadable ? 'true' : 'false';
      String? newValueToSet = isUnReadable ? '' : currentValue; // Clear value if unReadable is true

      // Update record in repository
      final success = await _documentRecordRepository.updateRecordValueWithUnReadable( // NEW method in repo
        uid: uid,
        newValue: newValueToSet,
        newRemark: currentRemark,
        newUnReadable: newUnReadableStatus,
      );

      _syncMessage = success ? "สถานะ 'ไม่อ่านค่าได้' อัปเดตสำเร็จ!" : "ไม่สามารถอัปเดตสถานะ 'ไม่อ่านค่าได้' ได้.";
      _statusMessage = success ? "สถานะ 'ไม่อ่านค่าได้' อัปเดตแล้ว." : "อัปเดตสถานะล้มเหลว.";
      return success;
    } on Exception catch (e) {
      _syncMessage = "ข้อผิดพลาดในการอัปเดตสถานะ 'ไม่อ่านค่าได้': $e";
      _statusMessage = "อัปเดตสถานะล้มเหลว: $e";
      print("Error updating unReadable status: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a specific record.
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
}