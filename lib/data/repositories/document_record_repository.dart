// lib/data/repositories/document_record_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';
import 'package:drift/drift.dart' as drift; // Alias drift

// NEW: Import for JobTag and Problem
import 'package:biochecksheet7_flutter/data/database/daos/job_tag_dao.dart'; // For JobTagDao
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag

// NEW: Import for charts
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // For IterableExtension, if needed for complex grouping/ordering

// NEW: Import DocumentRecordApiService
import 'package:biochecksheet7_flutter/data/network/document_record_api_service.dart';


/// Repository for managing document records.
/// This class abstracts data operations for records from UI/ViewModels.
class DocumentRecordRepository {
  final DocumentRecordDao _documentRecordDao;
  final JobTagDao _jobTagDao; // NEW
  final DocumentRecordApiService _documentRecordApiService; // <<< เพิ่ม Dependency นี้
   
  // TODO: หากมี DocumentRecordApiService ก็เพิ่มที่นี่
  // final DocumentRecordApiService _documentRecordApiService;

  DocumentRecordRepository({required AppDatabase appDatabase})
      : _documentRecordDao = appDatabase.documentRecordDao,
        _jobTagDao = appDatabase.jobTagDao, // NEW
      _documentRecordApiService = DocumentRecordApiService(); // <<< สร้าง instance
        // _documentRecordApiService = documentRecordApiService ?? DocumentRecordApiService(); // หากมี API

// Get chart data from local database
 // Corrected: Get chart data as a stream of FlSpot
  Stream<List<FlSpot>> getChartDataStream(String jobId, String machineId, String tagId) { // <<< Changed documentId to jobId
    // Watch the records for the chart
    return _documentRecordDao.watchRecordsForChart(jobId, machineId, tagId).map((records) { // <<< Changed documentId to jobId
      final List<FlSpot> spots = [];
      int spotIndex = 0;
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        final double? value = double.tryParse(record.value ?? '');
        if (value != null) {
          spots.add(FlSpot(spotIndex.toDouble(), value));
          spotIndex++;
        }
      }
      print('DocumentRecordRepository: Generated ${spots.length} chart spots.');
      return spots;
    });
  }
   // NEW: Get chart data from API (online chart)
  Stream<List<FlSpot>> getOnlineChartDataStream(String jobId, String machineId, String tagId) {
    // Since API calls are one-time fetches, we return a Future that then converts to a Stream.
    // Or, more simply, just map the Future to a Stream.
    return Stream.fromFuture(_documentRecordApiService.fetchHistoricalRecords(
      jobId: jobId,
      machineId: machineId,
      tagId: tagId,
    ).then((historicalData) {
      final List<FlSpot> spots = [];
      int spotIndex = 0;
      for (var i = 0; i < historicalData.length; i++) {
        final data = historicalData[i];
        final double? value = double.tryParse(data['Value']?.toString() ?? ''); // Assuming 'Value' key
        // You might want to parse 'CreateDate' for X-axis if it's a date-time chart
        // For now, use index for X.
        if (value != null) {
          spots.add(FlSpot(spotIndex.toDouble(), value));
          spotIndex++;
        }
      }
      print('DocumentRecordRepository: Generated ${spots.length} online chart spots.');
      return spots;
    }).catchError((error) {
      print('DocumentRecordRepository: Error fetching online chart data: $error');
      throw error; // Re-throw to be caught by ViewModel
    }));
  }
  /// Loads document records for a specific document and machine,
  /// joined with their corresponding job tags and problems.
  /// This provides data for the DocumentRecordScreen.
  Stream<List<DocumentRecordWithTagAndProblem>> loadRecordsForDocumentMachine({
    required String documentId,
    required String machineId,
  }) {
     print('DocumentRecordRepository: Loading records for DocID=$documentId, MachineID=$machineId'); // <<< Debugging
    // Uses the join query defined in DocumentRecordDao.
    return _documentRecordDao.getDocumentRecordsList(documentId, machineId);
  }

/// NEW: Initializes document records from job tags if they don't exist yet.
  /// Equivalent to DbDocumentRecordCode.initFirstRun
  Future<void> initializeRecordsFromJobTags({
    required String jobId,
    required String documentId,
    required String machineId,
  }) async {
    try {
       print('DocumentRecordRepository: Initializing records for JobID=$jobId, DocID=$documentId, MachineID=$machineId'); // <<< Debugging
      // 1. Get relevant job tags for this jobId and machineId
      final List<DbJobTag> jobTags = await _jobTagDao.getJobTagsByJobAndMachine(jobId, machineId); // Assuming you add this method to JobTagDao
      print('DocumentRecordRepository: Found ${jobTags.length} job tags for initialization.'); // <<< Debugging
      if (jobTags.isEmpty) {
        print('No job tags found for Job ID: $jobId, Machine ID: $machineId. Cannot initialize records.');
        return; // No tags to create records from
      }

      // 2. For each job tag, check if a corresponding DbDocumentRecord exists
      for (final jobTag in jobTags) {
        final existingRecord = await _documentRecordDao.getDocumentRecord(
          documentId: documentId, // <<< แก้ไขตรงนี้
          machineId: machineId, // <<< แก้ไขตรงนี้
          tagId: jobTag.tagId ?? '', // <<< แก้ไขตรงนี้
        );

        if (existingRecord == null) {
          // 3. If no record exists, create a new DbDocumentRecord based on the JobTag
          final newRecordEntry = DocumentRecordsCompanion(
            documentId: drift.Value(documentId),
            machineId: drift.Value(machineId),
            jobId: drift.Value(jobId), // Record is tied to the job too
            tagId: drift.Value(jobTag.tagId),
            tagName: drift.Value(jobTag.tagName),
            tagType: drift.Value(jobTag.tagType),
            tagGroupId: drift.Value(jobTag.tagGroupId),
            tagGroupName: drift.Value(jobTag.tagGroupName),
            tagSelectionValue: drift.Value(jobTag.tagSelectionValue),
            description: drift.Value(jobTag.description),
            specification: drift.Value(jobTag.specification),
            specMin: drift.Value(jobTag.specMin),
            specMax: drift.Value(jobTag.specMax),
            unit: drift.Value(jobTag.unit),
            queryStr: drift.Value(jobTag.queryStr),
            status: drift.Value(jobTag.status), // Default status from tag
            value: const drift.Value(''), // Default empty value
            remark: const drift.Value(''), // Default empty remark
            unReadable: const drift.Value('false'),
            lastSync: drift.Value(DateTime.now().toIso8601String()),
          );
          await _documentRecordDao.insertDocumentRecord(newRecordEntry);
          print('Created new record for Tag ID: ${jobTag.tagId}');
        }
      }
      print('Records initialization complete for Doc: $documentId, Machine: $machineId');
    } catch (e) {
      print('Error initializing records from JobTags: $e');
      throw Exception('Failed to initialize records: $e');
    }
  }
  
  /// Updates the 'value' and 'remark' of a specific document record locally.
  /// Equivalent to updating a record in DbDocumentRecord.
  Future<bool> updateRecordValue({
    required int uid, // Local unique ID of the record
    required String? newValue,
    required String? newRemark,
  }) async {
    try {
      final existingRecord = await _documentRecordDao.getDocumentRecordByUid(uid);
      if (existingRecord == null) {
        throw Exception("Record with UID $uid not found for update.");
      }

      final updatedEntry = existingRecord.copyWith(
        value: drift.Value(newValue), // <<< แก้ไขตรงนี้: ห่อด้วย drift.Value()
        remark: drift.Value(newRemark), // <<< แก้ไขตรงนี้: ห่อด้วย drift.Value()
        lastSync: drift.Value(DateTime.now().toIso8601String()), // Update lastSync timestamp
      );

      final success = await _documentRecordDao.updateDocumentRecord(updatedEntry);
      // TODO: หากมี API สำหรับ Sync การอัปเดตขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentRecordApiService.uploadRecordUpdate(updatedEntry);
      print('Record UID $uid updated: Value=$newValue, Remark=$newRemark');
      return success;
    } catch (e) {
      print('Error updating record UID $uid: $e');
      throw Exception('Failed to update record: $e');
    }
  }

/// Updates the 'value', 'remark', and 'unReadable' status for a specific record locally.
  Future<bool> updateRecordValueWithUnReadable({
    required int uid,
    required String? newValue,
    required String? newRemark,
    required String newUnReadable, // 'true' or 'false'
  }) async {
    try {
      final existingRecord = await _documentRecordDao.getDocumentRecordByUid(uid);
      if (existingRecord == null) {
        throw Exception("Record with UID $uid not found for update.");
      }

      // CRUCIAL FIX: existingRecord.copyWith expects drift.Value objects
      final updatedEntry = existingRecord.copyWith(
        value: drift.Value(newValue), // <<< แก้ไขตรงนี้: ห่อด้วย drift.Value()
        remark: drift.Value(newRemark), // <<< แก้ไขตรงนี้: ห่อด้วย drift.Value()
        unReadable: newUnReadable, // <<< แก้ไขตรงนี้: ห่อด้วย drift.Value()
        lastSync: drift.Value(DateTime.now().toIso8601String()), // Also needs Value
      );

      final success = await _documentRecordDao.updateDocumentRecord(updatedEntry);
      print('Record UID $uid updated: Value=$newValue, Remark=$newRemark, UnReadable=$newUnReadable');
      return success;
    } catch (e) {
      print('Error updating record UID $uid with unReadable: $e');
      throw Exception('Failed to update record with unReadable: $e');
    }
  }

  /// Deletes a specific document record locally.
  /// Equivalent to deleting a record in DbDocumentRecord.
  Future<void> deleteRecord({
    required int uid,
  }) async {
    try {
      final recordToDelete = await _documentRecordDao.getDocumentRecordByUid(uid);
      if (recordToDelete == null) {
        throw Exception('Record with UID $uid not found for deletion.');
      }

      await _documentRecordDao.deleteDocumentRecord(recordToDelete);
      // TODO: หากมี API สำหรับ Sync การลบ record ขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentRecordApiService.deleteRecordOnServer(recordToDelete.documentId, recordToDelete.machineId, recordToDelete.tagId);
      print('Record UID $uid deleted.');
    } catch (e) {
      print('Error deleting record UID $uid: $e');
      throw Exception('Failed to delete record: $e');
    }
  }
}