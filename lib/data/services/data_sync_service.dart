// lib/data/services/data_sync_service.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';

// Import all API Services
import 'package:biochecksheet7_flutter/data/network/user_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/job_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/job_machine_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/job_tag_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/problem_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_metadata_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/document_api_service.dart';

// Import all DAOs
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_tag_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/sync_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart';

// Import all Repositories (for DataSyncService to use them)
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart'; // <<< NEW: Import DocumentRecordRepository

// Import table companions for insertion
import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // <<< เพิ่ม import นี้
import 'package:biochecksheet7_flutter/data/network/document_record_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import api_response_models.dart
import 'package:biochecksheet7_flutter/data/network/api_request_models.dart'; // For SyncMetadataRequest
import 'package:biochecksheet7_flutter/data/services/database_maintenance_service.dart';
import 'package:biochecksheet7_flutter/data/services/data_cleanup_service.dart'; // Make sure this is imported





import 'package:drift/drift.dart' as drift;

class DataSyncService {
  // API Services
  final UserApiService _userApiService;
  final JobApiService _jobApiService;
  final JobMachineApiService _jobMachineApiService;
  final JobTagApiService _jobTagApiService;
  final ProblemApiService _problemApiService;
  final SyncMetadataApiService _syncMetadataApiService; // <<< Use this
  final DocumentApiService _documentApiService; // <<< เพิ่ม Dependency
  final DocumentRecordApiService
      _documentRecordApiService; // <<< เพิ่ม Dependency นี้
  // DAOs (now direct instances)
  final UserDao _userDao;
  final JobDao _jobDao;
  final DocumentMachineDao _documentMachineDao;
  final JobTagDao _jobTagDao;
  final ProblemDao _problemDao;
  final SyncDao _syncDao;
  final DocumentDao _documentDao; // <<< เพิ่ม Dependency นี้
  final DocumentRecordDao _documentRecordDao; // <<< เพิ่ม Dependency นี้

  // Repositories (for DataSyncService to orchestrate)
  final DocumentRecordRepository
      _documentRecordRepository; // <<< CRUCIAL FIX: Declare here
  final DatabaseMaintenanceService _databaseMaintenanceService;

  final DataCleanupService _dataCleanupService; // <<< Declare here
  // NEW: Public getters for services used by HomeViewModel
  DatabaseMaintenanceService get databaseMaintenanceService => _databaseMaintenanceService; // <<< NEW GETTER
  DataCleanupService get dataCleanupService => _dataCleanupService; // <<< NEW GETTER


  // Constructor now takes a resolved AppDatabase instance
  DataSyncService({
    required AppDatabase appDatabase, // <<< Change to AppDatabase
    UserApiService? userApiService,
    JobApiService? jobApiService,
    JobMachineApiService? jobMachineApiService,
    JobTagApiService? jobTagApiService,
    ProblemApiService? problemApiService,
    SyncMetadataApiService? syncMetadataApiService, // <<< Add to constructor
    DocumentApiService? documentApiService,
    DocumentRecordApiService?
        documentRecordApiService, // <<< เพิ่มใน Constructor
    DocumentRecordRepository? documentRecordRepository,
    DatabaseMaintenanceService? databaseMaintenanceService,
    DataCleanupService? dataCleanupService, // <<< Add to constructor
  })  : _userApiService = userApiService ?? UserApiService(),
        _jobApiService = jobApiService ?? JobApiService(),
        _jobMachineApiService = jobMachineApiService ?? JobMachineApiService(),
        _jobTagApiService = jobTagApiService ?? JobTagApiService(),
        _problemApiService = problemApiService ?? ProblemApiService(),
          _syncMetadataApiService = syncMetadataApiService ?? SyncMetadataApiService(), // <<< Initialize here
        _documentApiService =
            documentApiService ?? DocumentApiService(), // <<< สร้าง instance

        _documentRecordApiService = documentRecordApiService ??
            DocumentRecordApiService(), // <<< สร้าง instance
        _userDao = appDatabase.userDao, // Access dao directly
        _jobDao = appDatabase.jobDao, // Access dao directly
        _documentMachineDao =
            appDatabase.documentMachineDao, // Access dao directly
        _jobTagDao = appDatabase.jobTagDao, // Access dao directly
        _problemDao = appDatabase.problemDao, // Access dao directly
        _syncDao = appDatabase.syncDao, // Access dao directly
        _documentDao = appDatabase.documentDao, // <<< สร้าง instance
        _documentRecordDao =
            appDatabase.documentRecordDao, // Ensure this is initialized
        _documentRecordRepository = documentRecordRepository ??
            DocumentRecordRepository(
                appDatabase: appDatabase), // <<< CRUCIAL FIX: Initialize here
        _databaseMaintenanceService = databaseMaintenanceService ??
            DatabaseMaintenanceService(
                appDatabase: appDatabase),// <<< NEW: Initialize here
        _dataCleanupService = dataCleanupService ?? DataCleanupService(appDatabase: appDatabase); // <<< Initialize here

  // Removed old unused imports for tables as they are handled by DAO imports now
  // Removed unused methods (`_syncJobMachinesData`, `_syncJobTagsData`, `_syncProblemsData`, `_syncMetadataData`)
  // As they are called directly in performFullSync

  Future<SyncStatus> performFullSync() async {
    try {
      await _syncUsersData();
      await _syncJobsData();
      //await syncDocumentsData();
      await syncJobMachinesData();
      await _syncJobTagsData();
      await _syncProblemsData(); // <<< NEW: Call sync problems
      //await _syncMetadataData(); // Added the call for sync metadata

      return const SyncSuccess();
    } on Exception catch (e) {
      return SyncError(
          exception:
              'ข้อผิดพลาดในการซิงค์ผู้ใช้: $e'); // <<< CRUCIAL FIX: Use named parameter
    }
  }

  Future<SyncStatus> performProblemsSync() async {
    try {
      await _syncProblemsData(); // <<< NEW: Call sync problems

      return const SyncSuccess();
    } on Exception catch (e) {
      return SyncError(
          exception:
              'ข้อผิดพลาดในการซิงค์ผู้ใช้: $e'); // <<< CRUCIAL FIX: Use named parameter
    }
  }

  Future<void> _syncUsersData() async {
    final users = await _userApiService.syncUsers();
    await _userDao.deleteAllUsers();
    final usersToInsert = users.map((user) {
      return UsersCompanion(
        userId: drift.Value(user.userId),
        userCode: drift.Value(user.userCode),
        password: drift.Value(user.password),
        userName: drift.Value(user.displayName),
        position: drift.Value(user.position),
        status: drift.Value(user.status!),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );
    }).toList();
    await _userDao.insertAllUsers(usersToInsert);
  }

  Future<void> _syncJobsData() async {
    final jobs = await _jobApiService.syncJobs();
    await _jobDao.deleteAllJobs();
    final jobsToInsert = jobs.map((job) {
      return JobsCompanion(
        jobId: drift.Value(job.jobId),
        jobName: drift.Value(job.jobName),
        machineName: drift.Value(job.machineName),
        documentId: drift.Value(job.documentId),
        location: drift.Value(job.location),
        jobStatus: drift.Value(job.jobStatus),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );
    }).toList();
    await _jobDao.insertAllJobs(jobsToInsert);
  }

  Future<void> syncJobMachinesData() async {
    final machines = await _jobMachineApiService
        .syncJobMachines(); // This returns List<DbDocumentMachine>
    await _documentMachineDao.deleteAllDocumentMachines();
    final machinesToInsert = machines.map((machine) {
      return DocumentMachinesCompanion(
        // This is the companion object being built
        // CRITICAL FIX: Map 'id', 'createDate', 'createBy'
        id: drift.Value(machine.id), // <<< Map 'id' (int)
        jobId: drift.Value(machine.jobId),
        documentId: drift.Value(machine.documentId),
        machineId: drift.Value(machine.machineId),
        machineName: drift.Value(machine.machineName),
        machineType: drift.Value(machine.machineType),
        description: drift.Value(machine.description),
        specification: drift.Value(machine.specification),
        status: drift.Value(machine.status),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
        createDate: drift.Value(machine.createDate), // <<< Map 'createDate'
        createBy: drift.Value(machine.createBy), // <<< Map 'createBy'
      );
    }).toList();
    await _documentMachineDao.insertAllDocumentMachines(machinesToInsert);
  }

  Future<void> _syncJobTagsData() async {
    final tags = await _jobTagApiService.syncJobTags();
    await _jobTagDao.deleteAllJobTags();
    final tagsToInsert = tags.map((tag) {
      /*
    print('Processing DbJobTag for insertion:');
    print('  TagId: ${tag.tagId} (Type: ${tag.tagId.runtimeType})');
    print('  JobId: ${tag.jobId} (Type: ${tag.jobId.runtimeType})');
    print('  MachineId: ${tag.machineId} (Type: ${tag.machineId.runtimeType})');
    print('  TagGroupId: ${tag.tagGroupId} (Type: ${tag.tagGroupId.runtimeType})');
    print('  SpecMin: ${tag.specMin} (Type: ${tag.specMin.runtimeType})');
    print('  SpecMax: ${tag.specMax} (Type: ${tag.specMax.runtimeType})');
    print('  Status: ${tag.status} (Type: ${tag.status.runtimeType})');
    print('  Value: ${tag.value} (Type: ${tag.value.runtimeType})');
    print('  Remark: ${tag.remark} (Type: ${tag.remark.runtimeType})');
    print('----------------------------------------');
*/

      return JobTagsCompanion(
        uid: drift.Value.absent(), // <<< เพิ่ม uid (auto-increment)
        tagId: drift.Value(tag.tagId),
        jobId: drift.Value(tag.jobId),
        machineId: drift.Value(tag.machineId),
        tagName: drift.Value(tag.tagName),
        tagType: drift.Value(tag.tagType),
        tagGroupId: drift.Value(tag.tagGroupId),
        tagGroupName: drift.Value(tag.tagGroupName),
        description: drift.Value(tag.description),
        specification: drift.Value(tag.specification),
        specMin: drift.Value(tag.specMin),
        specMax: drift.Value(tag.specMax),
        unit: drift.Value(tag.unit),
        queryStr: drift.Value(tag.queryStr),
        status: drift.Value(tag.status),
        lastSync: drift.Value(DateTime.now().toIso8601String()),

        // CRUCIAL ADDITIONS: Map the missing fields
        note: drift.Value(tag.note), // <<< เพิ่ม
        value: drift.Value(tag.value), // <<< เพิ่ม
        remark: drift.Value(tag.remark), // <<< เพิ่ม
        createDate: drift.Value(tag.createDate), // <<< เพิ่ม
        createBy: drift.Value(tag.createBy), // <<< เพิ่ม
        valueType: drift.Value(tag.valueType), // <<< เพิ่ม
        tagSelectionValue: drift.Value(tag.tagSelectionValue), // <<< เพิ่ม
        driftQueryStr:
            drift.Value(tag.driftQueryStr), // <<< NEW: Map driftQueryStr
      );
    }).toList();
    await _jobTagDao.insertAllJobTags(tagsToInsert);
    print('Successfully inserted ${tagsToInsert.length} JobTags into DB.');
  }

  // Corrected: Private method for Problem sync - now handles conditional update/insert
  Future<void> _syncProblemsData() async {
    final problemsFromApi =
        await _problemApiService.syncProblems(); // Gets all problems from API

    for (final apiProblem in problemsFromApi) {
      print(
          'DataSyncService: Processing API problem for ProblemId: "${apiProblem.problemId}", DocumentId: "${apiProblem.documentId}"'); // <<< Debugging
      // Try to find the existing local problem by problemId
      final existingLocalProblem =
          await _problemDao.getProblemByProblemId(apiProblem.problemId ?? '');

      if (existingLocalProblem != null) {
        // If local problem exists, check its status
        if (existingLocalProblem.problemStatus == 0) {
          // Only update if local status is 0 (pending/initial)
          print(
              'DataSyncService: Updating local problem UID ${existingLocalProblem.uid} (Status 0) with API data for ProblemId: ${apiProblem.problemId}, DocumentId: ${apiProblem.documentId}'); // <<< Debuggingawait _problemDao.updateProblem(
          await _problemDao.updateProblem(
            ProblemsCompanion(
              uid: drift.Value(
                  existingLocalProblem.uid), // Specify UID for update
              problemId: drift.Value(apiProblem.problemId),
              problemName: drift.Value(apiProblem.problemName),
              problemDescription: drift.Value(apiProblem.problemDescription),
              problemStatus: drift.Value(
                  apiProblem.problemStatus), // Use API status (should be 0)
              problemSolvingDescription:
                  drift.Value(apiProblem.problemSolvingDescription),
              machineId: drift.Value(apiProblem.machineId),
              machineName: drift.Value(apiProblem.machineName),
              jobId: drift.Value(apiProblem.jobId),
              documentId: drift.Value(
                  apiProblem.documentId), // <<< Ensure this is passed
              tagId: drift.Value(apiProblem.tagId),
              tagName: drift.Value(apiProblem.tagName),
              tagType: drift.Value(apiProblem.tagType),
              description: drift.Value(apiProblem.description),
              note: drift.Value(apiProblem.note),
              specification: drift.Value(apiProblem.specification),
              specMin: drift.Value(apiProblem.specMin),
              specMax: drift.Value(apiProblem.specMax),
              unit: drift.Value(apiProblem.unit),
              value: drift.Value(apiProblem.value),
              remark: drift.Value(apiProblem.remark),
              unReadable: drift.Value(apiProblem.unReadable),
              lastSync: drift.Value(
                  DateTime.now().toIso8601String()), // Update last sync
              problemSolvingBy: drift.Value(apiProblem.problemSolvingBy),
              syncStatus:
                  drift.Value(apiProblem.syncStatus), // Use API syncStatus
            ),
          );
        } else {
          print(
              'DataSyncService: Skipping update for local problem UID ${existingLocalProblem.uid} (ProblemId: ${apiProblem.problemId}) because its status is ${existingLocalProblem.problemStatus} (not 0).'); // <<< Debugging
        }
      } else {
        // If local problem does not exist, insert it as a new record
        print(
            'Inserting new local problem for ProblemId: ${apiProblem.problemId}');
        await _problemDao.insertProblem(
          ProblemsCompanion(
            uid: drift.Value.absent(), // Auto-increment
            problemId: drift.Value(apiProblem.problemId),
            problemName: drift.Value(apiProblem.problemName),
            problemDescription: drift.Value(apiProblem.problemDescription),
            problemStatus:
                drift.Value(apiProblem.problemStatus), // Use API status
            problemSolvingDescription:
                drift.Value(apiProblem.problemSolvingDescription),
            documentId:
                drift.Value(apiProblem.documentId), // <<< Ensure this is passed
            machineId: drift.Value(apiProblem.machineId),
            machineName: drift.Value(apiProblem.machineName),
            jobId: drift.Value(apiProblem.jobId),
            tagId: drift.Value(apiProblem.tagId),
            tagName: drift.Value(apiProblem.tagName),
            tagType: drift.Value(apiProblem.tagType),
            description: drift.Value(apiProblem.description),
            note: drift.Value(apiProblem.note),
            specification: drift.Value(apiProblem.specification),
            specMin: drift.Value(apiProblem.specMin),
            specMax: drift.Value(apiProblem.specMax),
            unit: drift.Value(apiProblem.unit),
            value: drift.Value(apiProblem.value),
            remark: drift.Value(apiProblem.remark),
            unReadable: drift.Value(apiProblem.unReadable),
            lastSync:
                drift.Value(DateTime.now().toIso8601String()), // Set last sync
            problemSolvingBy: drift.Value(apiProblem.problemSolvingBy),
            syncStatus:
                drift.Value(apiProblem.syncStatus), // Use API syncStatus
          ),
        );
      }
    }
    print(
        'Problem sync complete. Processed ${problemsFromApi.length} problems from API.');
  }

 /// NEW: Checks sync metadata from API and retrieves actions/commands.
  Future<List<SyncMetadataResponse>> checkSyncMetadata({
    required String username,
    required String deviceId,
    required String serialNo,
    required String version,
    required String ipAddress,
    required String wifiStrength,
  }) async {
    return _syncMetadataApiService.checkSyncStatus(
      username: username,
      deviceId: deviceId,
      serialNo: serialNo,
      version: version,
      ipAddress: ipAddress,
      wifiStrength: wifiStrength,
    );
  }
  
/*
  Future<void> _syncMetadataData() async {
    final syncs = await _syncMetadataApiService.checkSyncStatus();
    await _syncDao.deleteAllSyncs();
    final syncsToInsert = syncs.map((s) {
      return SyncsCompanion(
        syncId: drift.Value(s.syncId),
        syncName: drift.Value(s.syncName),
        lastSync: drift.Value(s.lastSync),
        syncStatus: drift.Value(s.syncStatus),
        nextSync: drift.Value(s.nextSync),
      );
    }).toList();
    await _syncDao.insertAllSyncs(syncsToInsert);
  }
*/
  // NEW: Public method for Document sync (removed underscore)
  Future<void> syncDocumentsData() async {
    // <<< เปลี่ยนชื่อเมธอด (ลบ _ ออก)
    final documents = await _documentApiService.syncDocuments();
    await _documentDao.deleteAllDocuments();
    final documentsToInsert = documents.map((doc) {
      return DocumentsCompanion(
        documentId: drift.Value(doc.documentId),
        jobId: drift.Value(doc.jobId),
        documentName: drift.Value(doc.documentName),
        userId: drift.Value(doc.userId),
        createDate: drift.Value(doc.createDate),
        status: drift.Value(doc.status),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );
    }).toList();
    await _documentDao.insertAllDocuments(documentsToInsert);
  }

  /// Updates status to 3 and syncStatus to 1 upon successful API response.
  Future<SyncStatus> performDocumentRecordUploadSync() async {
    try {
      // 1. Get records ready for upload
      final recordsToUpload =
          await _documentRecordRepository.getRecordsForUpload();

      if (recordsToUpload.isEmpty) {
        print(
            'No DocumentRecords found with status 2 and syncStatus 0 for upload.');
        return const SyncSuccess(
            message: 'ไม่มีข้อมูล DocumentRecord ที่ต้องอัปโหลด.');
      }

      // We need documentCreateDate and documentUserId for the upload API.
      // These should come from the main document associated with these records.
      // Assuming all records in recordsToUpload belong to the same documentId.
      final String? documentId = recordsToUpload.first.documentId;
      final DbDocument? mainDocument = documentId != null
          ? await _documentDao.getDocumentById(documentId)
          : null;

      if (mainDocument == null) {
        throw Exception(
            'Main document not found for DocumentRecords. Cannot upload.');
      }

      final List<UploadRecordResult> uploadResults =
          await _documentRecordRepository.uploadDocumentRecordsToServer(
        recordsToUpload,
        documentCreateDate: mainDocument.createDate,
        documentUserId: mainDocument.userId,
      );

      // 3. Process results and update local DB
      bool allUploadsSuccessful = true;
      for (final result in uploadResults) {
        final int recordUid = result.uid;
        final int apiResultCode = result.result; // Assuming 3 for success

        if (apiResultCode == 3) {
          // Success from API
          final success =
              await _documentRecordRepository.updateRecordStatusAndSyncStatus(
                  recordUid,
                  3,
                  1); // Status 3 (Uploaded), SyncStatus 1 (Synced)
          if (!success) {
            allUploadsSuccessful = false;
            print(
                'Failed to update local status for DocumentRecord UID $recordUid after successful API upload.');
          }
        } else {
          allUploadsSuccessful = false;
          print(
              'API reported failure for DocumentRecord UID $recordUid. Result code: $apiResultCode, Message: ${result.message ?? 'No message provided'}');
        }
      }

      if (allUploadsSuccessful) {
        return const SyncSuccess(
            message: 'อัปโหลด DocumentRecord สำเร็จทั้งหมด.');
      } else {
        return const SyncError(
            exception:
                'มีบาง DocumentRecord ที่อัปโหลดไม่สำเร็จ.'); // <<< Corrected: Use named parameter
      }
    } catch (e) {
      print('Error during DocumentRecord upload sync: $e');
      return SyncError(
          exception:
              'ข้อผิดพลาดในการซิงค์ DocumentRecord: $e'); // <<< Corrected: Use named parameters
    }
  }
}
