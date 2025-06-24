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
import 'package:biochecksheet7_flutter/data/network/document_api_service.dart'; // <<< เพิ่ม import นี้

// Import all DAOs
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_tag_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/sync_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart'; // <<< เพิ่ม import นี้

// Import table companions for insertion
import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // <<< เพิ่ม import นี้
import 'package:drift/drift.dart' as drift;

class DataSyncService {
  // API Services
  final UserApiService _userApiService;
  final JobApiService _jobApiService;
  final JobMachineApiService _jobMachineApiService;
  final JobTagApiService _jobTagApiService;
  final ProblemApiService _problemApiService;
  final SyncMetadataApiService _syncMetadataApiService;
  final DocumentApiService _documentApiService; // <<< เพิ่ม Dependency

  // DAOs (now direct instances)
  final UserDao _userDao;
  final JobDao _jobDao;
  final DocumentMachineDao _documentMachineDao;
  final JobTagDao _jobTagDao;
  final ProblemDao _problemDao;
  final SyncDao _syncDao;
  final DocumentDao _documentDao; // <<< เพิ่ม Dependency นี้

  // Constructor now takes a resolved AppDatabase instance
  DataSyncService({
    required AppDatabase appDatabase, // <<< Change to AppDatabase
    UserApiService? userApiService,
    JobApiService? jobApiService,
    JobMachineApiService? jobMachineApiService,
    JobTagApiService? jobTagApiService,
    ProblemApiService? problemApiService,
    SyncMetadataApiService? syncMetadataApiService,
    DocumentApiService? documentApiService,
  })  : _userApiService = userApiService ?? UserApiService(),
        _jobApiService = jobApiService ?? JobApiService(),
        _jobMachineApiService = jobMachineApiService ?? JobMachineApiService(),
        _jobTagApiService = jobTagApiService ?? JobTagApiService(),
        _problemApiService = problemApiService ?? ProblemApiService(),
        _syncMetadataApiService =
            syncMetadataApiService ?? SyncMetadataApiService(),
        _documentApiService =
            documentApiService ?? DocumentApiService(), // <<< สร้าง instance
        _userDao = appDatabase.userDao, // Access dao directly
        _jobDao = appDatabase.jobDao, // Access dao directly
        _documentMachineDao =
            appDatabase.documentMachineDao, // Access dao directly
        _jobTagDao = appDatabase.jobTagDao, // Access dao directly
        _problemDao = appDatabase.problemDao, // Access dao directly
        _syncDao = appDatabase.syncDao, // Access dao directly
        _documentDao = appDatabase.documentDao; // <<< สร้าง instance

  // Removed old unused imports for tables as they are handled by DAO imports now
  // Removed unused methods (`_syncJobMachinesData`, `_syncJobTagsData`, `_syncProblemsData`, `_syncMetadataData`)
  // As they are called directly in performFullSync

  Future<SyncStatus> performFullSync() async {
    try {
      await _syncUsersData();
      await _syncJobsData();
      await syncDocumentsData();
      await _syncJobMachinesData();
      await _syncJobTagsData();
      //await _syncProblemsData();
      //await _syncMetadataData(); // Added the call for sync metadata

      return const SyncSuccess();
    } on Exception catch (e) {
      return SyncError(e);
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

  Future<void> _syncJobMachinesData() async {
    final machines = await _jobMachineApiService.syncJobMachines();
    await _documentMachineDao.deleteAllDocumentMachines();
    final machinesToInsert = machines.map((machine) {
      return DocumentMachinesCompanion(
        jobId: drift.Value(machine.jobId),
        documentId: drift.Value(machine.documentId),
        machineId: drift.Value(machine.machineId),
        machineName: drift.Value(machine.machineName),
        machineType: drift.Value(machine.machineType),
        description: drift.Value(machine.description),
        specification: drift.Value(machine.specification),
        status: drift.Value(machine.status),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );
    }).toList();
    await _documentMachineDao.insertAllDocumentMachines(machinesToInsert);
  }

  Future<void> _syncJobTagsData() async {
    final tags = await _jobTagApiService.syncJobTags();
    await _jobTagDao.deleteAllJobTags();
    final tagsToInsert = tags.map((tag) {
      return JobTagsCompanion(
        tagId: drift.Value(tag.tagId),
        jobId: drift.Value(tag.jobId),
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
      );
    }).toList();
    await _jobTagDao.insertAllJobTags(tagsToInsert);
  }

  Future<void> _syncProblemsData() async {
    final problems = await _problemApiService.syncProblems();
    await _problemDao.deleteAllProblems();
    final problemsToInsert = problems.map((problem) {
      return ProblemsCompanion(
        problemId: drift.Value(problem.problemId),
        problemName: drift.Value(problem.problemName),
        description: drift.Value(problem.description),
        problemStatus: drift.Value(problem.problemStatus),
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );
    }).toList();
    await _problemDao.insertAllProblems(problemsToInsert);
  }

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
}
