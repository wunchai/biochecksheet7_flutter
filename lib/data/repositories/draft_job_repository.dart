// lib/data/repositories/draft_job_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/draft_job_dao.dart';
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/network/draft_api_service.dart';
import 'package:uuid/uuid.dart';

class DraftJobRepository {
  final DraftJobDao _dao;
  final DraftApiService _apiService;

  DraftJobRepository(this._dao, this._apiService);

  // --- Job ---
  Stream<List<DbDraftJob>> watchAllDraftJobs() => _dao.watchAllDraftJobs();

  Future<DbDraftJob> getDraftJob(String draftJobId) => _dao.getDraftJob(draftJobId);

  Future<String> createDraftJob({
    required String jobName,
    required String location,
    String? machineName,
    String? documentId,
  }) async {
    final jobUid = const Uuid().v4();
    await _dao.insertDraftJob(DraftJobsCompanion(
      uid: Value(jobUid),
      jobName: Value(jobName),
      location: Value(location),
      machineName: Value(machineName),
      documentId: Value(documentId),
      status: const Value(0),
      createDate: Value(DateTime.now().toIso8601String()),
    ));
    return jobUid;
  }

  Future<void> updateDraftJobStatus(String draftJobId, int status) async {
    final job = await _dao.getDraftJob(draftJobId);
    await _dao.updateDraftJob(job.copyWith(status: status).toCompanion(true));
  }

  Future<void> _bumpJobVersionAndResetStatus(String draftJobId) async {
    final job = await _dao.getDraftJob(draftJobId);
    await _dao.updateDraftJob(job.copyWith(
      status: 0,
      recordVersion: job.recordVersion + 1,
    ).toCompanion(true));
  }

  Future<void> updateDraftJobDetails({
    required String draftJobId,
    required String jobName,
    required String location,
    String? machineName,
    String? documentId,
  }) async {
    final job = await _dao.getDraftJob(draftJobId);
    await _dao.updateDraftJob(job.copyWith(
      jobName: jobName,
      location: location,
      machineName: Value(machineName),
      documentId: Value(documentId),
      status: 0, // Reset status to draft on edit
      recordVersion: job.recordVersion + 1, // Increment version
    ).toCompanion(true));
  }

  Future<void> deleteDraftJob(String draftJobId) => _dao.deleteDraftJob(draftJobId);

  // --- Machine ---
  Stream<List<DbDraftMachine>> watchMachinesForJob(String draftJobId) => _dao.watchMachinesForJob(draftJobId);

  Future<String> createDraftMachine(String draftJobId, String machineName, {String? machineCode}) async {
    final machineUid = const Uuid().v4();
    final machineIdStr = const Uuid().v4();
    final job = await _dao.getDraftJob(draftJobId);

    await _dao.insertDraftMachine(DraftMachinesCompanion(
      uid: Value(machineUid),
      draftJobId: Value(draftJobId),
      documentId: Value(job.documentId),
      machineName: Value(machineName),
      machineId: Value(machineIdStr),
      machineType: const Value('Custom'),
      machineCode: Value(machineCode),
    ));
    return machineUid;
  }
  
  Future<void> updateDraftMachineDetails({
    required String draftMachineId,
    required String draftJobId,
    required String machineName,
    String? machineCode,
  }) async {
    final machine = await _dao.getDraftMachine(draftMachineId);
    await _dao.updateDraftMachine(machine.copyWith(
      machineName: Value(machineName),
      machineCode: Value(machineCode),
    ).toCompanion(true));
    await _bumpJobVersionAndResetStatus(draftJobId);
  }
  
  Future<void> deleteDraftMachine(String draftMachineId) => _dao.deleteDraftMachine(draftMachineId);

  // --- Tag ---
  Stream<List<DbDraftTag>> watchTagsForMachine(String draftMachineId) => _dao.watchTagsForMachine(draftMachineId);

  Future<String> createDraftTag({
    required String draftJobId,
    required String draftMachineId,
    required String groupName,
    required String tagName,
    required String tagType,
    String? specMin,
    String? specMax,
    String? unit,
    String? selectionValues,
    String? description,
    String? machineCode,
  }) async {
    final existingTags = await _dao.getTagsForMachine(draftMachineId);
    final job = await _dao.getDraftJob(draftJobId);
    
    // Auto-assign existing group ID if group name exists
    String? groupIdAssigned;
    for (var t in existingTags) {
      if (t.tagGroupName == groupName) {
        groupIdAssigned = t.tagGroupId;
        break;
      }
    }
    
    // Assign a new group ID sequence if new group
    groupIdAssigned ??= const Uuid().v4();

    final tagUid = const Uuid().v4();

    await _dao.insertDraftTag(DraftTagsCompanion(
      uid: Value(tagUid),
      draftJobId: Value(draftJobId),
      draftMachineId: Value(draftMachineId),
      tagGroupId: Value(groupIdAssigned),
      tagGroupName: Value(groupName),
      tagName: Value(tagName),
      tagType: Value(tagType),
      specMin: Value(specMin),
      specMax: Value(specMax),
      unit: Value(unit),
      tagSelectionValue: Value(selectionValues),
      description: Value(description),
      documentId: Value(job.documentId), 
      machineCode: Value(machineCode),
    ));
    return tagUid;
  }

  Future<void> updateDraftTagDetails({
    required String draftTagId,
    required String draftJobId,
    required String groupName,
    required String tagName,
    required String tagType,
    String? specMin,
    String? specMax,
    String? unit,
    String? selectionValues,
    String? description,
    String? machineCode,
  }) async {
    final tag = await _dao.getDraftTag(draftTagId);
    await _dao.updateDraftTag(tag.copyWith(
      tagGroupName: Value(groupName),
      tagName: Value(tagName),
      tagType: Value(tagType),
      specMin: Value(specMin),
      specMax: Value(specMax),
      unit: Value(unit),
      tagSelectionValue: Value(selectionValues),
      description: Value(description),
      machineCode: Value(machineCode),
    ).toCompanion(true));
    await _bumpJobVersionAndResetStatus(draftJobId);
  }

  Future<void> deleteDraftTag(String draftTagId) => _dao.deleteDraftTag(draftTagId);
  
  // Future: generateJsonPayload(String draftJobId) -> will be used to sync to API
  Future<void> syncDraftJobToApi(String draftJobId) async {
    // 1. Get the Job
    final job = await _dao.getDraftJob(draftJobId);
    
    // 2. Get Machines
    final machines = await _dao.getMachinesForJob(draftJobId);
    
    // 3. Get all Tags for those machines
    final List<DbDraftTag> allTags = [];
    for (var m in machines) {
      final tags = await _dao.getTagsForMachine(m.uid);
      allTags.addAll(tags);
    }

    // 4. Upload to API
    await _apiService.uploadDraftJobs([job]);
    if (machines.isNotEmpty) {
      await _apiService.uploadDraftMachines(machines, recordVersion: job.recordVersion);
    }
    if (allTags.isNotEmpty) {
      await _apiService.uploadDraftTags(allTags, recordVersion: job.recordVersion);
    }

    // 5. Update local status to Submitted (1)
    // 5. Update local status to Submitted (1)
    await updateDraftJobStatus(draftJobId, 1);
  }

  Future<void> syncDraftJobDeleteToApi(String draftJobId) async {
    final job = await _dao.getDraftJob(draftJobId);
    await _apiService.uploadDraftJobs([job]);
  }

  Future<void> downloadAndSyncDraftsFromApi() async {
    // 1. Download Jobs
    final jobs = await _apiService.downloadDraftJobs();
    for (var job in jobs) {
      await _dao.upsertDraftJob(job.toCompanion(true));
    }

    // 2. Download Machines
    final machines = await _apiService.downloadDraftMachines();
    for (var machine in machines) {
      await _dao.upsertDraftMachine(machine.toCompanion(true));
    }

    // 3. Download Tags
    final tags = await _apiService.downloadDraftTags();
    for (var tag in tags) {
      await _dao.upsertDraftTag(tag.toCompanion(true));
    }
  }

  // --- Auto-complete ---
  Future<List<String>> getDistinctGroupNames(String draftJobId) => _dao.getDistinctGroupNames(draftJobId);
  Future<List<String>> getDistinctTagNames(String draftJobId) => _dao.getDistinctTagNames(draftJobId);
}
