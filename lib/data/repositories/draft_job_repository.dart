// lib/data/repositories/draft_job_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/draft_job_dao.dart';
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/network/draft_api_service.dart';

class DraftJobRepository {
  final DraftJobDao _dao;
  final DraftApiService _apiService;

  DraftJobRepository(this._dao, this._apiService);

  // --- Job ---
  Stream<List<DbDraftJob>> watchAllDraftJobs() => _dao.watchAllDraftJobs();

  Future<DbDraftJob> getDraftJob(int draftJobId) => _dao.getDraftJob(draftJobId);

  Future<int> createDraftJob({
    required String jobName,
    required String location,
    String? machineName,
    String? documentId,
  }) {
    return _dao.insertDraftJob(DraftJobsCompanion(
      jobName: Value(jobName),
      location: Value(location),
      machineName: Value(machineName),
      documentId: Value(documentId),
      status: const Value(0),
      createDate: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> updateDraftJobStatus(int draftJobId, int status) async {
    final job = await _dao.getDraftJob(draftJobId);
    await _dao.updateDraftJob(job.copyWith(status: status).toCompanion(true));
  }

  Future<void> deleteDraftJob(int draftJobId) => _dao.deleteDraftJob(draftJobId);

  // --- Machine ---
  Stream<List<DbDraftMachine>> watchMachinesForJob(int draftJobId) => _dao.watchMachinesForJob(draftJobId);

  Future<int> createDraftMachine(int draftJobId, String machineName) async {
    // Generate a simple running number mapping locally (e.g., MCH-001)
    final existingMachines = await _dao.getMachinesForJob(draftJobId);
    final nextId = (existingMachines.length + 1).toString().padLeft(3, '0');
    final machineIdStr = 'MCH-$nextId'; 

    return _dao.insertDraftMachine(DraftMachinesCompanion(
      draftJobId: Value(draftJobId),
      machineName: Value(machineName),
      machineId: Value(machineIdStr),
      machineType: const Value('Custom'),
    ));
  }
  
  Future<void> deleteDraftMachine(int draftMachineId) => _dao.deleteDraftMachine(draftMachineId);

  // --- Tag ---
  Stream<List<DbDraftTag>> watchTagsForMachine(int draftMachineId) => _dao.watchTagsForMachine(draftMachineId);

  Future<int> createDraftTag({
    required int draftJobId,
    required int draftMachineId,
    required String groupName,
    required String tagName,
    required String tagType,
    String? specMin,
    String? specMax,
    String? unit,
    String? selectionValues,
    String? description,
  }) async {
    final existingTags = await _dao.getTagsForMachine(draftMachineId);
    
    // Auto-assign existing group ID if group name exists
    String? groupIdAssigned;
    for (var t in existingTags) {
      if (t.tagGroupName == groupName) {
        groupIdAssigned = t.tagGroupId;
        break;
      }
    }
    
    // Assign a new group ID sequence if new group
    if (groupIdAssigned == null) {
       final groupList = existingTags.map((e) => e.tagGroupId).toSet();
       groupIdAssigned = 'GRP-${groupList.length + 1}';
    }

    return _dao.insertDraftTag(DraftTagsCompanion(
      draftJobId: Value(draftJobId),
      draftMachineId: Value(draftMachineId),
      tagGroupId: Value(groupIdAssigned),
      tagGroupName: Value(groupName),
      tagName: Value(tagName),
      tagType: Value(tagType),
      specMin: Value(specMin),
      specMax: Value(specMax),
      unit: Value(unit),
      description: Value(description),
      tagSelectionValue: Value(selectionValues),
    ));
  }

  Future<void> deleteDraftTag(int draftTagId) => _dao.deleteDraftTag(draftTagId);
  
  // Future: generateJsonPayload(int draftJobId) -> will be used to sync to API
  Future<void> syncDraftJobToApi(int draftJobId) async {
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
      await _apiService.uploadDraftMachines(machines);
    }
    if (allTags.isNotEmpty) {
      await _apiService.uploadDraftTags(allTags);
    }

    // 5. Update local status to Submitted (1)
    await updateDraftJobStatus(draftJobId, 1);
  }
  // --- Auto-complete ---
  Future<List<String>> getDistinctGroupNames(int draftJobId) => _dao.getDistinctGroupNames(draftJobId);
  Future<List<String>> getDistinctTagNames(int draftJobId) => _dao.getDistinctTagNames(draftJobId);
}
