// lib/presentation/screens/draft_job/draft_job_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/repositories/draft_job_repository.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

class DraftJobViewModel extends ChangeNotifier {
  final DraftJobRepository _repository;

  DraftJobViewModel({required DraftJobRepository repository}) : _repository = repository;

  Stream<List<DbDraftJob>> get allDraftJobs => _repository.watchAllDraftJobs();
  
  Stream<List<DbDraftMachine>> watchMachines(String jobId) => _repository.watchMachinesForJob(jobId);
  
  Stream<List<DbDraftTag>> watchTags(String machineId) => _repository.watchTagsForMachine(machineId);

  Future<String> createNewJob({
    required String jobName,
    required String location,
    String? machineName,
    String? documentId,
  }) async {
    return await _repository.createDraftJob(
      jobName: jobName,
      location: location,
      machineName: machineName,
      documentId: documentId,
    );
  }

  Future<void> deleteJobAndSync(String jobId) async {
    // 1. Update status to 4 for deleting on server
    await _repository.updateDraftJobStatus(jobId, 4);
    // 2. Sync to API (only the job)
    await _repository.syncDraftJobDeleteToApi(jobId);
    // 3. Delete from local database
    await _repository.deleteDraftJob(jobId);
  }

  Future<void> updateJobDetails({
    required String draftJobId,
    required String jobName,
    required String location,
    String? machineName,
    String? documentId,
  }) async {
    await _repository.updateDraftJobDetails(
      draftJobId: draftJobId,
      jobName: jobName,
      location: location,
      machineName: machineName,
      documentId: documentId,
    );
  }

  Future<void> syncJobToApi(String jobId) async {
    await _repository.syncDraftJobToApi(jobId);
  }

  Future<void> syncFromApi() async {
    await _repository.downloadAndSyncDraftsFromApi();
    notifyListeners();
  }

  Future<String> addMachine(String jobId, String machineName, {String? machineCode}) async {
    return await _repository.createDraftMachine(jobId, machineName, machineCode: machineCode);
  }

  Future<void> updateMachineDetails(String draftMachineId, String draftJobId, String machineName, {String? machineCode}) async {
    await _repository.updateDraftMachineDetails(
      draftMachineId: draftMachineId,
      draftJobId: draftJobId,
      machineName: machineName,
      machineCode: machineCode,
    );
  }

  Future<void> deleteMachine(String machineId) async {
    await _repository.deleteDraftMachine(machineId);
  }

  Future<String> addTag({
    required String jobId,
    required String machineId,
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
    return await _repository.createDraftTag(
      draftJobId: jobId,
      draftMachineId: machineId,
      groupName: groupName,
      tagName: tagName,
      tagType: tagType,
      specMin: specMin,
      specMax: specMax,
      unit: unit,
      selectionValues: selectionValues,
      description: description,
      machineCode: machineCode,
    );
  }

  Future<void> updateTagDetails({
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
    await _repository.updateDraftTagDetails(
      draftTagId: draftTagId,
      draftJobId: draftJobId,
      groupName: groupName,
      tagName: tagName,
      tagType: tagType,
      specMin: specMin,
      specMax: specMax,
      unit: unit,
      selectionValues: selectionValues,
      description: description,
      machineCode: machineCode,
    );
  }

  Future<void> deleteTag(String tagId) async {
    await _repository.deleteDraftTag(tagId);
  }

  // --- Auto-complete queries ---
  Future<List<String>> getDistinctGroupNames(String draftJobId) => _repository.getDistinctGroupNames(draftJobId);
  Future<List<String>> getDistinctTagNames(String draftJobId) => _repository.getDistinctTagNames(draftJobId);
}
