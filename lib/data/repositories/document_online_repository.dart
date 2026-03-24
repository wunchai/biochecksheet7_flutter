// lib/data/repositories/document_online_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_online_dao.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';
import 'package:drift/drift.dart' as drift;

class DocumentOnlineRepository {
  final DocumentOnlineDao _documentOnlineDao;
  final DocumentOnlineApiService _apiService;

  DocumentOnlineRepository({
    required AppDatabase appDatabase,
    DocumentOnlineApiService? apiService,
  })  : _documentOnlineDao = appDatabase.documentOnlineDao,
        _apiService = apiService ?? DocumentOnlineApiService();

  /// Watch local document online records
  Stream<List<DbDocumentOnline>> watchAllDocumentOnlines() {
    return _documentOnlineDao.watchAllDocumentOnlines();
  }

  /// Sync data from server and replace local database
  Future<bool> syncDocumentOnlineData({
    required String userId,
    required String jobId,
    required String start,
    required String stop,
  }) async {
    try {
      // 1. Fetch from API
      final apiData = await _apiService.fetchDocumentOnline(
        userId: userId,
        jobId: jobId,
        start: start,
        stop: stop,
      );

      // 2. Convert to companions
      final companions = apiData.map((doc) => DocumentOnlinesCompanion(
        uid: const drift.Value.absent(), // Let DB autoincrement
        documentId: drift.Value(doc.documentId),
        jobId: drift.Value(doc.jobId),
        documentName: drift.Value(doc.documentName),
        userId: drift.Value(doc.userId),
        createDate: drift.Value(doc.createDate),
        status: drift.Value(doc.status),
        lastSync: drift.Value(doc.lastSync),
        // updated_at is handled by trigger
      )).toList();

      // 3. Replace all local records
      await _documentOnlineDao.replaceAllDocumentOnlines(companions);

      return true;
    } catch (e) {
      print('Error syncing DocumentOnline data: $e');
      return false;
    }
  }

  Future<void> clearAllDocumentOnlines() async {
    await _documentOnlineDao.deleteAllDocumentOnlines();
  }
}
