// lib/ui/document/document_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';

class DocumentViewModel extends ChangeNotifier {
  final DocumentDao _documentDao;
  final DataSyncService _dataSyncService;

  String? _jobId;
  String? get jobId => _jobId;

  Stream<List<DbDocument>>? _documentsStream;
  Stream<List<DbDocument>>? get documentsStream => _documentsStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusMessage = "Loading documents...";
  String get statusMessage => _statusMessage;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  DocumentViewModel({required AppDatabase appDatabase})
      : _documentDao = appDatabase.documentDao,
        _dataSyncService = DataSyncService(appDatabase: appDatabase);

  Future<void> loadDocuments(String? jobId) async {
    _isLoading = true;
    _jobId = jobId;
    _statusMessage = "Fetching documents...";
    notifyListeners();

    try {
      if (jobId != null && jobId.isNotEmpty) {
        _documentsStream = _documentDao.watchDocumentsByJobId(jobId);
        _statusMessage = "Documents for Job ID: $jobId loaded.";
      } else {
        _documentsStream = _documentDao.watchAllDocuments();
        _statusMessage = "All documents loaded.";
      }
    } catch (e) {
      _statusMessage = "Failed to load documents: $e";
      print("Error loading documents: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDocuments() async {
    _isLoading = true;
    _syncMessage = "Syncing document data...";
    _statusMessage = "Syncing document data...";
    notifyListeners();

    try {
      final result =
          await _dataSyncService.syncDocumentsData(); // <<< เรียก public method

      // Note: syncDocumentsData returns Future<void>, not SyncStatus directly
      // So, handle based on success/failure of the Future itself, not SyncStatus.
      // If any exception occurs in syncDocumentsData, it will be caught by the catch block.
      _syncMessage = "Document data synced successfully!";
      _statusMessage = "Document data synced successfully!";
      await loadDocuments(_jobId); // Reload from local DB after sync
    } on Exception catch (e) {
      _syncMessage = "An unexpected error occurred during document sync: $e";
      _statusMessage = "An unexpected error occurred during document sync: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
