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
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart'; // <<< NEW: Import DocumentDao
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // <<< NEW: Import DbDocument
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< CRUCIAL FIX: Add this import for UploadRecordResult

import 'dart:math'; // <<< NEW: Import for atan and pow

/// Repository for managing document records.
/// This class abstracts data operations for records from UI/ViewModels.
class DocumentRecordRepository {
  final DocumentRecordDao _documentRecordDao;
  final JobTagDao _jobTagDao; // NEW
  final DocumentRecordApiService
      _documentRecordApiService; // <<< เพิ่ม Dependency นี้
  final AppDatabase _appDatabase; // NEW: Add AppDatabase to access raw queries
  final DocumentDao _documentDao; // <<< CRUCIAL FIX: Declare DocumentDao here
  


  DocumentRecordRepository({required AppDatabase appDatabase})
      : _documentRecordDao = appDatabase.documentRecordDao,
        _jobTagDao = appDatabase.jobTagDao, // NEW
        _documentRecordApiService =
            DocumentRecordApiService(), // <<< สร้าง instance
        _appDatabase = appDatabase, // <<< Initialize AppDatabase
        _documentDao = appDatabase.documentDao; // <<< Initialize DocumentDao here
  /// Loads document records for a specific document and machine,
  /// joined with their corresponding job tags and problems.
  /// This provides data for the DocumentRecordScreen.
  ///
  Stream<List<DocumentRecordWithTagAndProblem>> loadRecordsForDocumentMachine({
    required String documentId,
    required String machineId,
  }) {
    print(
        'DocumentRecordRepository: Loading records for DocID=$documentId, MachineID=$machineId'); // <<< Debugging
    // Uses the join query defined in DocumentRecordDao.
    return _documentRecordDao.getDocumentRecordsList(documentId, machineId);
  }

  // NEW: Helper method to select value of a specific record (by tagId)
  // Equivalent to DbDocumentRecordCode.selectValue
  Future<String?> selectRecordValue(
      String tagId, String documentId, String machineId) async {
    final record = await _documentRecordDao.getDocumentRecord(
      documentId: documentId,
      machineId: machineId,
      tagId: tagId,
    );
    return record?.value;
  }

  Future<dynamic>? executeSqlCalculation(String sqlQuery,
      {required String documentId, required String machineId}) async {
    // <<< Add documentId, machineId
    try {
      print('Executing SQL calculation: $sqlQuery');
      // Use db.customSelect to execute raw SQL, passing parameters for '?' placeholders
      final result = await _appDatabase.customSelect(
        sqlQuery,
        variables: [
          drift.Variable.withString(
              documentId), // <<< Pass documentId as a SQL parameter
          drift.Variable.withString(
              machineId), // <<< Pass machineId as a SQL parameter
        ],
      ).getSingleOrNull();

      if (result != null && result.data.isNotEmpty) {
        return result.data.values.first;
      }
      return null;
    } catch (e) {
      print('Error executing SQL calculation: $e');
      throw Exception('SQL calculation failed: $e');
    }
  }

  // Corrected: Method to evaluate predefined formula
  Future<dynamic>? evaluateFormula(
    String formulaStr, {
    required String documentId,
    required String machineId,
    required String jobId,
    DbJobTag? jobTag,
  }) async {
    try {
      print('Evaluating formula: $formulaStr');
      if (jobTag == null ||
          jobTag.driftQueryStr == null ||
          jobTag.driftQueryStr!.isEmpty) {
        throw Exception(
            "Drift Query String (driftQueryStr) is missing for formula evaluation.");
      }
      final String formulaToEvaluate =
          jobTag.driftQueryStr!; // Use driftQueryStr for formula

      // Example predefined formulas:
      switch (formulaToEvaluate) {
        case 'SUM_LAST_3_VALUES':
          if (jobTag.tagId == null)
            throw Exception("Tag ID is missing for formula evaluation.");
          final records = await _documentRecordDao
              .watchRecordsForChart(jobId, machineId, jobTag.tagId!)
              .first;
          final values = records
              .map((r) => double.tryParse(r.value ?? ''))
              .whereType<double>()
              .toList();
          if (values.length >= 3) {
            return values.sublist(values.length - 3).sum;
          }
          return null;
        case 'CONVERT_C_TO_F(VALUE)':
          return 25.0 * 9 / 5 + 32; // Dummy calculation

        // NEW: Implement funtion1 logic here
        case '1': // Assuming 'funtion1' is the formulaStr stored in driftQueryStr
          // Call selectRecordValue to get necessary inputs
          final coolingTowerTempRecordValue =
              await selectRecordValue("9", documentId, machineId); // TagId "9"
          final coolingTowerHuRecordValue = await selectRecordValue(
              "10", documentId, machineId); // TagId "10"

          print(
              'Cooling Tower Temp: $coolingTowerTempRecordValue, Humidity: $coolingTowerHuRecordValue');

          if (coolingTowerTempRecordValue != null &&
              coolingTowerTempRecordValue.isNotEmpty &&
              coolingTowerHuRecordValue != null &&
              coolingTowerHuRecordValue.isNotEmpty) {
            final double? coolingTowerTempValue =
                double.tryParse(coolingTowerTempRecordValue);
            final double? coolingTowerHuValue =
                double.tryParse(coolingTowerHuRecordValue);

            if (coolingTowerTempValue != null && coolingTowerHuValue != null) {
              // Implement the complex formula from Kotlin here:
              // return coolingTowerTempValue * atan(0.152 * (coolingTowerHuValue + 8.3136).pow(0.5)) + atan(
              //     coolingTowerTempValue + coolingTowerHuValue
              // ) - atan(coolingTowerHuValue - 1.6763) + 0.00391838 * coolingTowerHuValue.pow(
              //     1.5
              // ) * atan(0.0231 * coolingTowerHuValue) - 4.686

              // Equivalent of Kotlin's .pow(0.5) is Dart's sqrt() or pow(x, 0.5)
              // Equivalent of Kotlin's .pow(1.5) is Dart's pow(x, 1.5)
              // Math.atan is atan() in Dart's 'dart:math'

              return coolingTowerTempValue *
                      atan(0.152 * pow((coolingTowerHuValue + 8.3136), 0.5)) +
                  atan(coolingTowerTempValue + coolingTowerHuValue) -
                  atan(coolingTowerHuValue - 1.6763) +
                  0.00391838 *
                      pow(coolingTowerHuValue, 1.5) *
                      atan(0.0231 * coolingTowerHuValue) -
                  4.686;
            }
          }
          return 0.0; // Return 0.0 if inputs are missing or invalid
        default:
          return null; // Formula not recognized
      }
    } catch (e) {
      print('Error evaluating formula: $e');
      throw Exception('Formula evaluation failed: $e');
    }
  }

// Get chart data from local database
  // Corrected: Get chart data as a stream of FlSpot
  Stream<List<FlSpot>> getChartDataStream(
      String jobId, String machineId, String tagId) {
    // <<< Changed documentId to jobId
    // Watch the records for the chart
    return _documentRecordDao
        .watchRecordsForChart(jobId, machineId, tagId)
        .map((records) {
      // <<< Changed documentId to jobId
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
  Stream<List<FlSpot>> getOnlineChartDataStream(
      String jobId, String machineId, String tagId) {
    // Since API calls are one-time fetches, we return a Future that then converts to a Stream.
    // Or, more simply, just map the Future to a Stream.
    return Stream.fromFuture(_documentRecordApiService
        .fetchHistoricalRecords(
      jobId: jobId,
      machineId: machineId,
      tagId: tagId,
    )
        .then((historicalData) {
      final List<FlSpot> spots = [];
      int spotIndex = 0;
      for (var i = 0; i < historicalData.length; i++) {
        final data = historicalData[i];
        final double? value = double.tryParse(
            data['Value']?.toString() ?? ''); // Assuming 'Value' key
        // You might want to parse 'CreateDate' for X-axis if it's a date-time chart
        // For now, use index for X.
        if (value != null) {
          spots.add(FlSpot(spotIndex.toDouble(), value));
          spotIndex++;
        }
      }
      print(
          'DocumentRecordRepository: Generated ${spots.length} online chart spots.');
      return spots;
    }).catchError((error) {
      print(
          'DocumentRecordRepository: Error fetching online chart data: $error');
      throw error; // Re-throw to be caught by ViewModel
    }));
  }

  /// NEW: Initializes document records from job tags if they don't exist yet.
  /// Equivalent to DbDocumentRecordCode.initFirstRun
  Future<void> initializeRecordsFromJobTags({
    required String jobId,
    required String documentId,
    required String machineId,
  }) async {
    try {
      print(
          'DocumentRecordRepository: Initializing records for JobID=$jobId, DocID=$documentId, MachineID=$machineId'); // <<< Debugging
      // 1. Get relevant job tags for this jobId and machineId
      final List<DbJobTag> jobTags = await _jobTagDao.getJobTagsByJobAndMachine(
          jobId, machineId); // Assuming you add this method to JobTagDao
      print(
          'DocumentRecordRepository: Found ${jobTags.length} job tags for initialization.'); // <<< Debugging
      if (jobTags.isEmpty) {
        print(
            'No job tags found for Job ID: $jobId, Machine ID: $machineId. Cannot initialize records.');
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
            //status: drift.Value(jobTag.status), // Default status from tag
            status: drift.Value(0), // Default status from tag
            value: const drift.Value(''), // Default empty value
            remark: const drift.Value(''), // Default empty remark
            unReadable: const drift.Value('false'),
            lastSync: drift.Value(DateTime.now().toIso8601String()),
          );
          await _documentRecordDao.insertDocumentRecord(newRecordEntry);
          print('Created new record for Tag ID: ${jobTag.tagId}');
        }
      }
      print(
          'Records initialization complete for Doc: $documentId, Machine: $machineId');
    } catch (e) {
      print('Error initializing records from JobTags: $e');
      throw Exception('Failed to initialize records: $e');
    }
  }

  /// Updates the 'value', 'remark', 'unReadable', and 'createBy' of a specific document record locally.
  /// This single method handles all updates for a record, including unReadable status.
  Future<bool> updateRecordValue({
    required int uid,
    String? newValue, // Optional value update
    String? newRemark, // Optional remark update
    String?
        newUnReadable, // Optional unReadable status update ('true' or 'false')
    String? userId, // Optional userId for createBy update
    int? newStatus, // <<< NEW: Optional status update (0, 1, 2)
  }) async {
    try {
      final existingRecord =
          await _documentRecordDao.getDocumentRecordByUid(uid);
      if (existingRecord == null) {
        throw Exception("Record with UID $uid not found for update.");
      }

      // Determine the final status to apply
      int finalStatus = newStatus ??
          existingRecord
              .status; // Use newStatus if provided, else keep existing

      // Build a Companion object for updating fields.
      final updatedCompanion = DocumentRecordsCompanion(
        uid: drift.Value(uid), // Specify UID for update (primary key)

        // Update value only if newValue is explicitly provided (not null, different from existing)
        value: newValue != null
            ? drift.Value(newValue)
            : drift.Value(existingRecord.value),

        // Update remark only if newRemark is explicitly provided
        remark: newRemark != null
            ? drift.Value(newRemark)
            : drift.Value(existingRecord.remark),

        // Update unReadable only if newUnReadable is explicitly provided
        unReadable: newUnReadable != null
            ? drift.Value(newUnReadable)
            : drift.Value(existingRecord.unReadable),

        // Always update lastSync and createBy on any change to the record
        lastSync: drift.Value(DateTime.now().toIso8601String()),
        createBy:
            drift.Value(userId ?? existingRecord.createBy), // Update createBy

        status: drift.Value(finalStatus), // <<< Update status
      );

      // Perform update using the DAO's update method directly.
      // It will update the record identified by its primary key (uid).
      final success =
          await _documentRecordDao.updateDocumentRecord(updatedCompanion);
      print(
          'Record UID $uid updated: Value=${newValue ?? existingRecord.value}, '
          'Remark=${newRemark ?? existingRecord.remark}, '
          'UnReadable=${newUnReadable ?? existingRecord.unReadable}, '
          'CreateBy=${userId ?? existingRecord.createBy}, '
          'Status=$finalStatus'); // <<< Add Status to log
      return success;
    } catch (e) {
      print('Error updating record UID $uid: $e');
      throw Exception('Failed to update record: $e');
    }
  }

  // NEW: Helper method to get a record by UID for comparison in ViewModel
  Future<DbDocumentRecord?> getRecordByUid(int uid) {
    return _documentRecordDao.getDocumentRecordByUid(uid);
  }

  /// Deletes a specific document record locally.
  Future<void> deleteRecord({
    required int uid,
  }) async {
    try {
      final recordToDelete =
          await _documentRecordDao.getDocumentRecordByUid(uid);
      if (recordToDelete == null) {
        throw Exception('Record with UID $uid not found for deletion.');
      }

      await _documentRecordDao.deleteDocumentRecord(
          recordToDelete); // Corrected: Use deleteRecord on DAO
      print('Record UID $uid deleted.');
    } catch (e) {
      print('Error deleting record UID $uid: $e');
      throw Exception('Failed to delete record: $e');
    }
  }

  /// Uploads records with Status 1 (Locally Validated) to the server.
  /// After successful upload, updates their status to 2 (Posted).
  Future<bool> uploadRecordsToServer({required String documentId, required String machineId, required String jobId,  String? documentCreateDate, 
    String? documentUserId     }) async {
    try {
      // 1. Get records that are ready for upload (Status 1 or 2)
      final allRecordsForDocMachine = await _documentRecordDao.getDocumentRecordsList(documentId, machineId).first;
      final recordsToUpload = allRecordsForDocMachine.where((r) => r.documentRecord.status == 1 || r.documentRecord.status == 2).map((r) => r.documentRecord).toList();


      if (recordsToUpload.isEmpty) {
        print('No records found with Status 1 or 2 for DocID=$documentId, MachineID=$machineId to upload.');
        return true; // Nothing to upload, consider it successful
      }

      // 2. Get the main document details (createDate, userId)
      final DbDocument? mainDocument = await _documentDao.getDocumentById(documentId);
      if (mainDocument == null) {
        throw Exception('Main document not found for documentId: $documentId. Cannot upload records.');
      }

      // 3. Call API service to upload these records
      // CRUCIAL FIX: Expect List<UploadRecordResult> from API service
      final List<UploadRecordResult> uploadResults = await _documentRecordApiService.uploadRecords(
        recordsToUpload,
        documentCreateDate: mainDocument.createDate,
        documentUserId: mainDocument.userId,
      );

      // 4. Process upload results and update syncStatus in local DB
      bool overallUploadSuccess = true;
      for (final apiResult in uploadResults) {
        final int recordUid = apiResult.uid;
        final int apiResultCode = apiResult.result; // Assuming 3 for success

        // Determine new syncStatus based on API result
        int newSyncStatus = 0; // Default to 0 (failed/not synced)
        if (apiResultCode == 3) { // Assuming 3 means success from API
          newSyncStatus = 1; // Set to 1 (Synced)
        }

        // Update record's status to 2 and syncStatus based on API response
        final success = await _documentRecordDao.updateDocumentRecord(
          DocumentRecordsCompanion(
            uid: drift.Value(recordUid),
            status: const drift.Value(2), // Always set to 2 (Posted) after attempting upload
            syncStatus: drift.Value(newSyncStatus), // Update syncStatus based on API result
            lastSync: drift.Value(DateTime.now().toIso8601String()), // Update last sync timestamp
          ),
        );
        if (!success) {
          overallUploadSuccess = false; // If any local DB update fails, mark overall as failed
          print('Failed to update local syncStatus for UID $recordUid');
        }
      }

      print('Processed ${uploadResults.length} upload results. Overall success: $overallUploadSuccess');
      return overallUploadSuccess;
    } catch (e) {
      print('Error during records upload to server: $e');
      throw Exception('Records upload failed: $e');
    }
  }
   /// NEW: Gets DocumentRecords that are ready for upload (status = 2 and syncStatus = 0).
  Future<List<DbDocumentRecord>> getRecordsForUpload() async {
    return _documentRecordDao.watchRecordsForUpload().first;
  }


  /// NEW: Updates the status and syncStatus of a DocumentRecord by UID.
  Future<bool> updateRecordStatusAndSyncStatus(
      int uid, int newStatus, int newSyncStatus) async {
    return _documentRecordDao.updateDocumentRecordStatusAndSyncStatus(
        uid, newStatus, newSyncStatus);
  }

 /// NEW: Uploads a list of DbDocumentRecord to the API.
  /// Returns a list of UploadRecordResult indicating success/failure for each record.
  Future<List<UploadRecordResult>> uploadDocumentRecordsToServer(
    List<DbDocumentRecord> recordsToUpload,
    {String? documentCreateDate, String? documentUserId} // <<< CRUCIAL FIX: Add these parameters
  ) async {
    return _documentRecordApiService.uploadDocumentRecords(
      recordsToUpload,
      documentCreateDate: documentCreateDate,
      documentUserId: documentUserId,
    );
  }

}
