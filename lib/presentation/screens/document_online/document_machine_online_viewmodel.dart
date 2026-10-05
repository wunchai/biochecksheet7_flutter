// lib/presentation/screens/document_online/document_machine_online_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_online_repository.dart';

import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';

class DocumentMachineOnlineViewModel extends ChangeNotifier {
  final DocumentRecordOnlineRepository _repository;
  
  bool isLoading = false;
  String? errorMessage;
  
  // To store parsed machine summary data
  List<MachineSummaryOnline> summaryMachines = [];

  DocumentMachineOnlineViewModel({required DocumentRecordOnlineRepository repository})
      : _repository = repository;

  Future<void> fetchOnlineRecords(String userId, String jobId, String documentId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.fetchAndSaveAllOnlineRecords(userId, jobId, documentId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMachineSummary(String userId, String jobId, String documentId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final dynamic rawData = await _repository.fetchMachineSummaryOnline(userId, jobId, documentId);
      if (rawData != null && rawData is Map<String, dynamic>) {
        final response = MachineSummaryOnlineResponse.fromJson(rawData);
        summaryMachines = response.machines;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<DbDocumentRecordOnline>> getMachinesForDocument(String documentId) {
    return _repository.watchDistinctMachines(documentId);
  }
}
