// lib/ui/documentmachine/document_machine_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_repository.dart'; // <<< NEW
//import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:drift/drift.dart' as drift;

class DocumentMachineViewModel extends ChangeNotifier {
  final DocumentMachineDao _documentMachineDao;
  final DataSyncService _dataSyncService;
  final DocumentRepository _documentRepository; // <<< NEW: Injected Repository

  String? _documentId;
  String? get documentId => _documentId;
  String? get jobId => _jobId;
  String? _jobId;

  Stream<List<DbDocumentMachine>>? _machinesStream;
  Stream<List<DbDocumentMachine>>? get machinesStream => _machinesStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isJobClosed = false;
  bool get isJobClosed => _isJobClosed;

  String _statusMessage = "Loading machines...";
  String get statusMessage => _statusMessage;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  DocumentMachineViewModel({required AppDatabase appDatabase})
      : _documentMachineDao = appDatabase.documentMachineDao,
        _dataSyncService = DataSyncService(appDatabase: appDatabase),
        _documentRepository = DocumentRepository(
            appDatabase: appDatabase); // <<< NEW: Initialize Repository

  /// Loads machines from the local database based on documentId and jobId.
  Future<void> loadMachines(String? documentId, String? jobId) async {
    _isLoading = true;
    _documentId = documentId;
    _jobId = jobId;
    _statusMessage = "Fetching machines...";
    notifyListeners();

    try {
      print("Loading machines for Document ID: $documentId, Job ID: $jobId");

      drift.SimpleSelectStatement<$DocumentMachinesTable, DbDocumentMachine>
          baseQuery;

      if (documentId != null &&
          documentId.isNotEmpty &&
          jobId != null &&
          jobId.isNotEmpty) {
        // Use the DAO's instance of select and where
        print("if statement : $documentId and Job ID: $jobId");

        baseQuery = _documentMachineDao.select(_documentMachineDao
            .db.documentMachines) // Access table via db instance
          ..where((tbl) =>
              tbl.documentId.equals(documentId) & tbl.jobId.equals(jobId));

        _statusMessage =
            "Machines for Document ID: $documentId (Job ID: $jobId) loaded.";
      } else {
        // For all machines, select from the db instance directly
        baseQuery = _documentMachineDao.select(_documentMachineDao
            .db.documentMachines); // Access table via db instance
        _statusMessage = "All machines loaded.";
      }

      _machinesStream = baseQuery.watch();

      // NEW: Check global document status to see if it's already closed
      if (documentId != null) {
        final doc = await _documentRepository
            .getDocument(documentId); // Corrected method name
        _isJobClosed = (doc != null && doc.status >= 2);
        print('DocumentMachineViewModel: Job Closed = $_isJobClosed');
      }
    } catch (e) {
      _statusMessage = "Failed to load machines: $e";
      print("Error loading machines: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes machine data by triggering an API sync and then reloading from local DB.
  Future<void> refreshMachines() async {
    _isLoading = true;
    _syncMessage = "Syncing machine data...";
    _statusMessage = "Syncing machine data...";
    notifyListeners();

    try {
      await _dataSyncService.syncJobMachinesData();

      _syncMessage = "Machine data synced successfully!";
      _statusMessage = "Machine data synced successfully!";
      await loadMachines(_documentId, _jobId); // Reload machines after sync
    } on Exception catch (e) {
      _syncMessage = "An unexpected error occurred during machine sync: $e";
      _statusMessage = "An unexpected error occurred during machine sync: $e";
      print("Error during machine sync: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Closes the current job (Document) after validation.
  /// Returns null on success, or an error message on failure.
  Future<String?> closeJob() async {
    if (_documentId == null) return "Common error: Document ID is null";

    _isLoading = true;
    notifyListeners();

    try {
      // Call repository to validate and close
      final error = await _documentRepository.closeDocument(_documentId!);

      if (error == null) {
        // Success
        _statusMessage = "Job closed successfully.";
        _isJobClosed = true; // NEW: Update state immediately
        notifyListeners(); // Refresh UI to disable button
        // You might want to refresh the machine list or navigation status here
      } else {
        // Validation failed
        _statusMessage = error;
      }
      return error;
    } catch (e) {
      _statusMessage = "Error closing job: $e";
      return "Error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
