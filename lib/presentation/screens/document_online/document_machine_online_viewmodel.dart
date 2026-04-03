// lib/presentation/screens/document_online/document_machine_online_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_online_repository.dart';

class DocumentMachineOnlineViewModel extends ChangeNotifier {
  final DocumentRecordOnlineRepository _repository;
  
  bool isLoading = false;
  String? errorMessage;

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

  Stream<List<DbDocumentRecordOnline>> getMachinesForDocument(String documentId) {
    return _repository.watchDistinctMachines(documentId);
  }
}
