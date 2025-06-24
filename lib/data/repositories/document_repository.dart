// lib/data/repositories/document_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // For DbDocument
import 'package:drift/drift.dart' as drift;

// TODO: หากมี API สำหรับสร้าง/คัดลอก/ลบเอกสารบนเซิร์ฟเวอร์ ให้เพิ่ม DocumentApiService ที่นี่
// import 'package:biochecksheet7_flutter/data/network/document_api_service.dart';

/// Repository for managing document data.
/// This class abstracts data operations from UI/ViewModels.
class DocumentRepository {
  final DocumentDao _documentDao;
  // TODO: หากมี DocumentApiService ก็เพิ่มที่นี่
  // final DocumentApiService _documentApiService;

  DocumentRepository({required AppDatabase appDatabase})
      : _documentDao = appDatabase.documentDao;
      // _documentApiService = documentApiService ?? DocumentApiService(); // หากมี API

  /// Equivalent to DbDocumentCode.initNewDocument
  Future<void> newDocument({
    required String documentName,
    required String jobId,
    required String userId,
    // TODO: เพิ่ม parameters อื่นๆ ที่จำเป็นสำหรับการสร้างเอกสารใหม่
  }) async {
    try {
      final newDocId = _generateUniqueDocumentId(jobId); // สร้าง Document ID ใหม่ (ตัวอย่าง)

      final newDocumentEntry = DocumentsCompanion(
        documentId: drift.Value(newDocId),
        documentName: drift.Value(documentName),
        jobId: drift.Value(jobId),
        userId: drift.Value(userId),
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: const drift.Value(0), // Default status for new document
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );

      await _documentDao.insertDocument(newDocumentEntry);
      // TODO: หากมี API สำหรับ Sync เอกสารใหม่ขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.uploadNewDocument(newDocumentEntry);

      print('New document created: $documentName (ID: $newDocId)');
    } catch (e) {
      print('Error creating new document: $e');
      throw Exception('Failed to create new document: $e');
    }
  }

  /// Equivalent to DbDocumentCode.initCopyDocument
  Future<void> copyDocument({
    required String originalDocumentId,
    required String newDocumentName,
    required String newJobId, // JobId ของเอกสารใหม่
    required String userId,
  }) async {
    try {
      final originalDoc = await _documentDao.getDocument(originalDocumentId);

      if (originalDoc == null) {
        throw Exception('Original document not found: $originalDocumentId');
      }

      final newDocId = _generateUniqueDocumentId(newJobId); // สร้าง Document ID ใหม่

      final copiedDocumentEntry = DocumentsCompanion(
        documentId: drift.Value(newDocId),
        documentName: drift.Value(newDocumentName),
        jobId: drift.Value(newJobId), // New jobId for the copied document
        userId: drift.Value(userId),
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: drift.Value(originalDoc.status), // Copy status from original
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );

      await _documentDao.insertDocument(copiedDocumentEntry);
      // TODO: หากมี API สำหรับ Sync เอกสารที่คัดลอกขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.uploadCopiedDocument(copiedDocumentEntry);

      print('Document $originalDocumentId copied to $newDocumentName (ID: $newDocId)');
    } catch (e) {
      print('Error copying document: $e');
      throw Exception('Failed to copy document: $e');
    }
  }

  /// Equivalent to DbDocumentCode.deleteDocument
  Future<void> deleteDocument({
    required int uid, // Use local uid for deletion
    required String documentId, // Use documentId for server sync if applicable
    // TODO: job ID อาจจำเป็นสำหรับการอัปเดต UI หรือ server
  }) async {
    try {
      final docToDelete = await _documentDao.getDocument(documentId);
      if (docToDelete == null) {
        throw Exception('Document not found for deletion: $documentId');
      }

      await _documentDao.deleteDocument(docToDelete); // Delete from local DB
      // TODO: หากมี API สำหรับ Sync การลบเอกสารขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.deleteDocumentOnServer(documentId);

      print('Document deleted: $documentId');
    } catch (e) {
      print('Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  // Helper function to generate a unique document ID (example, adjust as needed)
  String _generateUniqueDocumentId(String jobId) {
    return '${jobId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}