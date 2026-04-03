// lib/presentation/screens/draft_job/draft_job_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/repositories/draft_job_repository.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

class DraftJobViewModel extends ChangeNotifier {
  final DraftJobRepository _repository;

  DraftJobViewModel({required DraftJobRepository repository}) : _repository = repository;

  Stream<List<DbDraftJob>> get allDraftJobs => _repository.watchAllDraftJobs();
  
  Stream<List<DbDraftMachine>> watchMachines(int jobId) => _repository.watchMachinesForJob(jobId);
  
  Stream<List<DbDraftTag>> watchTags(int machineId) => _repository.watchTagsForMachine(machineId);

  Future<int> createNewJob({
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

  Future<void> deleteJob(int jobId) async {
    await _repository.deleteDraftJob(jobId);
  }

  Future<void> syncJobToApi(int jobId) async {
    await _repository.syncDraftJobToApi(jobId);
  }

  Future<int> addMachine(int jobId, String machineName) async {
    return await _repository.createDraftMachine(jobId, machineName);
  }

  Future<void> deleteMachine(int machineId) async {
    await _repository.deleteDraftMachine(machineId);
  }

  Future<int> addTag({
    required int jobId,
    required int machineId,
    required String groupName,
    required String tagName,
    required String tagType,
    String? specMin,
    String? specMax,
    String? unit,
    String? selectionValues,
    String? description,
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
    );
  }

  Future<void> deleteTag(int tagId) async {
    await _repository.deleteDraftTag(tagId);
  }

  // --- Auto-complete queries ---
  Future<List<String>> getDistinctGroupNames(int draftJobId) => _repository.getDistinctGroupNames(draftJobId);
  Future<List<String>> getDistinctTagNames(int draftJobId) => _repository.getDistinctTagNames(draftJobId);
}
