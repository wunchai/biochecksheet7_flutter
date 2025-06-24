// lib/ui/documentrecord/document_record_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_repository.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart'; // For DocumentRecordWithTagAndProblem

/// Equivalent to DocumentRecordViewModel.kt
class DocumentRecordViewModel extends ChangeNotifier {
  final DocumentRecordRepository _documentRecordRepository;

  String? _documentId;
  String? get documentId => _documentId;
  String? _machineId;
  String? get machineId => _machineId;
  String? _jobId; // NEW: Need jobId to initialize records from job tags

  Stream<List<DocumentRecordWithTagAndProblem>>? _recordsStream;
  Stream<List<DocumentRecordWithTagAndProblem>>? get recordsStream => _recordsStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusMessage = "Loading records...";
  String get statusMessage => _statusMessage;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;
  set syncMessage(String? value) {
    _syncMessage = value;
    notifyListeners();
  }

  DocumentRecordViewModel({required AppDatabase appDatabase})
      : _documentRecordRepository = DocumentRecordRepository(appDatabase: appDatabase);

  /// Loads document records for the specified documentId and machineId.
  Future<void> loadRecords(String documentId, String machineId, String jobId) async {
    _isLoading = true;
    _documentId = documentId;
    _machineId = machineId;
     _jobId = jobId; // Store jobId
    _statusMessage = "Fetching records...";
    notifyListeners();

    try {
        await _documentRecordRepository.initializeRecordsFromJobTags(
        jobId: _jobId!, // Use stored jobId
        documentId: _documentId!, // Use stored documentId
        machineId: _machineId!, // Use stored machineId
      );
      _statusMessage = "Records initialized/checked.";
      
      _recordsStream = _documentRecordRepository.loadRecordsForDocumentMachine(
        documentId: documentId,
        machineId: machineId,
      );
      _statusMessage = "Records for Document ID: $documentId, Machine ID: $machineId loaded.";
    } catch (e) {
      _statusMessage = "Failed to load records: $e";
      print("Error loading records: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes records by re-loading them from the repository.
  Future<void> refreshRecords() async {
    _isLoading = true;
    _syncMessage = "Refreshing records...";
    _statusMessage = "Refreshing records...";
    notifyListeners();

    try {
      // TODO: Implement actual API sync for records here if needed
      // await _documentRecordRepository.syncRecords(documentId!, machineId!); // If you create a sync method

      if (_documentId != null && _machineId != null && _jobId != null) {
        await loadRecords(_documentId!, _machineId!, _jobId!); // Reload from local DB
      } else {
        _statusMessage = "Cannot refresh: documentId or machineId is missing.";
      }
      _syncMessage = "Records refreshed!";
    } on Exception catch (e) {
      _syncMessage = "Error refreshing records: $e";
      _statusMessage = "Error refreshing records.";
      print("Error refreshing records: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the value and/or remark of a specific record.
  Future<bool> updateRecordValue(int uid, String? newValue, String? newRemark) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "Updating record...";
    notifyListeners();
    try {
      final success = await _documentRecordRepository.updateRecordValue(
        uid: uid,
        newValue: newValue,
        newRemark: newRemark,
      );
      _syncMessage = success ? "Record updated successfully!" : "Failed to update record.";
      _statusMessage = success ? "Record updated." : "Update failed.";
      return success;
    } on Exception catch (e) {
      _syncMessage = "Error updating record: $e";
      _statusMessage = "Update failed: $e";
      print("Error updating record: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a specific record.
  Future<bool> deleteRecord(int uid) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "Deleting record...";
    notifyListeners();
    try {
      await _documentRecordRepository.deleteRecord(uid: uid);
      _syncMessage = "Record deleted successfully!";
      _statusMessage = "Record deleted.";
      return true;
    } on Exception catch (e) {
      _syncMessage = "Error deleting record: $e";
      _statusMessage = "Delete failed: $e";
      print("Error deleting record: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}