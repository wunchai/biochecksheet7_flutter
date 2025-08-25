// lib/ui/documentmachine/document_machine_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
//import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:drift/drift.dart' as drift;

class DocumentMachineViewModel extends ChangeNotifier {
  final DocumentMachineDao _documentMachineDao;
  final DataSyncService _dataSyncService;

  String? _documentId;
  String? get documentId => _documentId;
  String? _jobId;
  String? get jobId => _jobId;

  Stream<List<DbDocumentMachine>>? _machinesStream;
  Stream<List<DbDocumentMachine>>? get machinesStream => _machinesStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
        _dataSyncService = DataSyncService(appDatabase: appDatabase);

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
          ..where((tbl) => tbl.jobId.equals(jobId));

        _statusMessage =
            "Machines for Document ID: $documentId (Job ID: $jobId) loaded.";
      } else {
        // For all machines, select from the db instance directly
        baseQuery = _documentMachineDao.select(_documentMachineDao
            .db.documentMachines); // Access table via db instance
        _statusMessage = "All machines loaded.";
      }

      _machinesStream = baseQuery.watch();
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
}
