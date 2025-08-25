// lib/data/repositories/document_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // For DbDocument
import 'package:drift/drift.dart' as drift;

// NEW: Import for DocumentRecordDao and DocumentRecordTable
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';

/// Repository for managing document data.
/// This class abstracts data operations from UI/ViewModels.
class DocumentRepository {
  final DocumentDao _documentDao;
  final DocumentRecordDao _documentRecordDao;
  // TODO: หากมี DocumentApiService ก็เพิ่มที่นี่
  // final DocumentApiService _documentApiService;

  DocumentRepository({required AppDatabase appDatabase})
      : _documentDao = appDatabase.documentDao,
        _documentRecordDao = appDatabase.documentRecordDao;
  // _documentApiService = documentApiService ?? DocumentApiService(); // หากมี API
  // _documentApiService = documentApiService ?? DocumentApiService(); // หากมี API

  /// Equivalent to DbDocumentCode.initNewDocument
  Future<void> newDocument({
    required String documentName,
    required String jobId,
    required String userId,
    // TODO: เพิ่ม parameters อื่นๆ ที่จำเป็นสำหรับการสร้างเอกสารใหม่
  }) async {
    try {
      final newDocId =
          _generateUniqueDocumentId(jobId); // สร้าง Document ID ใหม่ (ตัวอย่าง)

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

      final newDocId =
          _generateUniqueDocumentId(newJobId); // สร้าง Document ID ใหม่

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

      // CRUCIAL ADDITION: Copy associated document records
      final originalRecords =
          await _documentRecordDao.getRecordsByDocumentId(originalDocumentId);
      if (originalRecords.isNotEmpty) {
        final List<DocumentRecordsCompanion> copiedRecords =
            originalRecords.map((record) {
          return DocumentRecordsCompanion(
            // Copy all fields from original record, but update documentId, jobId, userId, and timestamp
            documentId: drift.Value(newDocId), // New document ID
            machineId: drift.Value(record.machineId),
            jobId: drift.Value(newJobId), // New job ID
            tagId: drift.Value(record.tagId),
            tagName: drift.Value(record.tagName),
            tagType: drift.Value(record.tagType),
            tagGroupId: drift.Value(record.tagGroupId),
            tagGroupName: drift.Value(record.tagGroupName),
            tagSelectionValue: drift.Value(record.tagSelectionValue),
            description: drift.Value(record.description),
            specification: drift.Value(record.specification),
            specMin: drift.Value(record.specMin),
            specMax: drift.Value(record.specMax),
            unit: drift.Value(record.unit),
            queryStr: drift.Value(record.queryStr),
            value: drift.Value(record.value), // Copy existing value
            valueType: drift.Value(record.valueType),
            remark: drift.Value(record.remark), // Copy existing remark
            status: drift.Value(record.status),
            unReadable: drift.Value(record.unReadable),
            lastSync: drift.Value(
                DateTime.now().toIso8601String()), // New sync timestamp
          );
        }).toList();
        await _documentRecordDao.insertAllDocumentRecords(copiedRecords);
        print('Copied ${copiedRecords.length} records for new document.');
      }

      // TODO: หากมี API สำหรับ Sync เอกสารที่คัดลอกขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.uploadCopiedDocument(copiedDocumentEntry);

      print(
          'Document $originalDocumentId copied to $newDocumentName (ID: $newDocId)');
    } catch (e) {
      print('Error copying document: $e');
      throw Exception('Failed to copy document: $e');
    }
  }

  /// Equivalent to DbDocumentCode.deleteDocument
  Future<void> deleteDocument({
    required int uid, // Use local uid for deletion
    required String
        documentId, // Use documentId for server sync and record deletion
    // TODO: job ID อาจจำเป็นสำหรับการอัปเดต UI หรือ server
  }) async {
    try {
      final docToDelete = await _documentDao.getDocument(documentId);
      if (docToDelete == null) {
        throw Exception('Document not found for deletion: $documentId');
      }

      await _documentDao.deleteDocument(docToDelete); // Delete main document

      // CRUCIAL ADDITION: Delete associated document records
      await _documentRecordDao.deleteAllRecordsByDocumentId(documentId);
      print('Deleted all associated records for document $documentId.');

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
