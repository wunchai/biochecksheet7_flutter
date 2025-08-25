// lib/ui/document/document_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/services/data_sync_service.dart';
//import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_repository.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // To get userId from LoggedInUser
import 'package:drift/drift.dart' as drift;

class DocumentViewModel extends ChangeNotifier {
  final DocumentDao _documentDao;
  final DataSyncService _dataSyncService;
  final DocumentRepository _documentRepository;
  final LoginRepository _loginRepository;

  String? _jobId;
  String? get jobId => _jobId;

  String? _searchQuery;
  String? get searchQuery => _searchQuery;

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

  DbDocument? _selectedDocument;
  DbDocument? get selectedDocument => _selectedDocument;
  void selectDocument(DbDocument doc) {
    _selectedDocument = doc;
    notifyListeners();
  }

  void clearSelection() {
    _selectedDocument = null;
    notifyListeners();
  }

  DocumentViewModel({required AppDatabase appDatabase})
      : _documentDao = appDatabase.documentDao,
        _dataSyncService = DataSyncService(appDatabase: appDatabase),
        _documentRepository = DocumentRepository(appDatabase: appDatabase),
        _loginRepository = LoginRepository();

  Future<void> loadDocuments(String? jobId, {String? searchQuery}) async {
    _isLoading = true;
    _jobId = jobId;
    _searchQuery = searchQuery;
    _statusMessage = "Fetching documents...";
    notifyListeners();

    try {
      drift.SimpleSelectStatement<$DocumentsTable, DbDocument> baseQuery;

      if (jobId != null && jobId.isNotEmpty) {
        baseQuery = _documentDao.select(_documentDao.documents)
          ..where((tbl) => tbl.jobId.equals(jobId));
      } else {
        baseQuery = _documentDao.select(_documentDao.documents);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        baseQuery = baseQuery
          ..where((tbl) =>
              tbl.documentName.contains(searchQuery) |
              tbl.documentId.contains(searchQuery));
      }

      _documentsStream = baseQuery.watch();

      if (jobId != null && jobId.isNotEmpty) {
        _statusMessage = "Documents for Job ID: $jobId loaded.";
      } else {
        _statusMessage = "All documents loaded.";
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        _statusMessage += " (filtered by '$searchQuery')";
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
      await _dataSyncService.syncDocumentsData();
      _syncMessage = "Document data synced successfully!";
      _statusMessage = "Document data synced successfully!";
      await loadDocuments(_jobId, searchQuery: _searchQuery);
    } on Exception catch (e) {
      _syncMessage = "An unexpected error occurred during document sync: $e";
      _statusMessage = "An unexpected error occurred during document sync: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadDocuments(_jobId, searchQuery: _searchQuery);
    }
  }

  Future<bool> createNewDocument(String documentName) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "Creating new document...";
    notifyListeners();

    try {
      if (_jobId == null || _jobId!.isEmpty) {
        throw Exception("Job ID is required to create a new document.");
      }
      final currentUser = _loginRepository.loggedInUser; // <<< แก้ไขตรงนี้
      if (currentUser == null) {
        throw Exception("No user logged in. Cannot create document.");
      }

      await _documentRepository.newDocument(
        documentName: documentName,
        jobId: _jobId!,
        userId: currentUser.userId,
        // Add other required parameters
      );
      _syncMessage = "New document '$documentName' created successfully!";
      _statusMessage = "New document created.";
      await loadDocuments(_jobId, searchQuery: _searchQuery);
      return true;
    } on Exception catch (e) {
      _syncMessage = "Failed to create document: $e";
      _statusMessage = "Failed to create document.";
      print("Error creating document: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> copySelectedDocument(String newDocumentName) async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "Copying document...";
    notifyListeners();

    try {
      if (_selectedDocument == null) {
        throw Exception("No document selected for copying.");
      }
      if (_jobId == null || _jobId!.isEmpty) {
        throw Exception("Job ID is required to copy a document.");
      }
      final currentUser = _loginRepository.loggedInUser; // <<< แก้ไขตรงนี้
      if (currentUser == null) {
        throw Exception("No user logged in. Cannot copy document.");
      }

      await _documentRepository.copyDocument(
        originalDocumentId: _selectedDocument!.documentId ?? '',
        newDocumentName: newDocumentName,
        newJobId: _jobId!,
        userId: currentUser.userId,
      );
      _syncMessage = "Document copied to '$newDocumentName' successfully!";
      _statusMessage = "Document copied.";
      await loadDocuments(_jobId, searchQuery: _searchQuery);
      clearSelection();
      return true;
    } on Exception catch (e) {
      _syncMessage = "Failed to copy document: $e";
      _statusMessage = "Failed to copy document.";
      print("Error copying document: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSelectedDocument() async {
    _isLoading = true;
    _syncMessage = null;
    _statusMessage = "Deleting document...";
    notifyListeners();

    try {
      if (_selectedDocument == null) {
        throw Exception("No document selected for deletion.");
      }

      await _documentRepository.deleteDocument(
        uid: _selectedDocument!.uid,
        documentId: _selectedDocument!.documentId ?? '',
      );
      _syncMessage =
          "Document '${_selectedDocument!.documentName}' deleted successfully!";
      _statusMessage = "Document deleted.";
      await loadDocuments(_jobId, searchQuery: _searchQuery);
      clearSelection();
      return true;
    } on Exception catch (e) {
      _syncMessage = "Failed to delete document: $e";
      _statusMessage = "Failed to delete document.";
      print("Error deleting document: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
