// lib/data/services/data_cleanup_service.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // For SyncStatus
import 'dart:io'; // For File.delete() in image cleanup

class DataCleanupService {
  final DocumentRecordDao _documentRecordDao;
  final DocumentDao _documentDao;
  final ImageDao _imageDao;
  final ProblemDao _problemDao;

  DataCleanupService({required AppDatabase appDatabase})
      : _documentRecordDao = appDatabase.documentRecordDao,
            _documentDao = appDatabase.documentDao,
            _imageDao = appDatabase.imageDao,
            _problemDao = appDatabase.problemDao;

  /// Cleans up data that has been fully synced to the server.
  /// This includes:
  /// 1. DocumentRecords with syncStatus = 1
  /// 2. Associated Images (for DocumentRecords and Problems)
  /// 3. Documents (if all their records are cleaned)
  /// 4. Problems with syncStatus = 1
  Future<SyncStatus> cleanEndData() async {
    try {
      print('DataCleanupService: Starting cleanEndData process...');

      // --- 1. Identify DocumentRecords to clean ---
      final recordsToClean = await _documentRecordDao.getRecordsBySyncStatus(1); // SyncStatus 1 means synced
      final List<String> documentIdsToClean = recordsToClean.map((r) => r.documentId!).where((id) => id.isNotEmpty).toList();
      
      // --- 2. Identify Problems to clean ---
      final problemsToClean = await _problemDao.getProblemsBySyncStatus(1); // SyncStatus 1 means synced
      final List<String> problemIdsToClean = problemsToClean.map((p) => p.problemId!).where((id) => id.isNotEmpty).toList();

      // --- 3. Delete associated Images ---
      if (documentIdsToClean.isNotEmpty) {
        // Delete actual image files from storage first
        for (final docId in documentIdsToClean.toSet()) {
          final imagesToDelete = await _imageDao.watchImagesForRecord(
            documentId: docId, machineId: '', jobId: '', tagId: '', problemId: null // Filter by documentId
          ).first;
          for (final img in imagesToDelete) {
            if (img.filepath != null && img.filepath!.isNotEmpty) {
              final file = File(img.filepath!);
              if (await file.exists()) {
                await file.delete();
                print('DataCleanupService: Deleted image file: ${img.filepath}');
              }
            }
          }
        }
        final deletedImagesByDoc = await _imageDao.deleteImagesByDocumentIds(documentIdsToClean);
        print('DataCleanupService: Deleted $deletedImagesByDoc image records associated with cleaned documents.');
      }
      if (problemIdsToClean.isNotEmpty) {
        // Delete actual image files from storage first
        for (final probId in problemIdsToClean.toSet()) {
          final imagesToDelete = await _imageDao.watchImagesForRecord(
            documentId: '', machineId: '', jobId: '', tagId: '', problemId: probId // Filter by problemId
          ).first;
          for (final img in imagesToDelete) {
            if (img.filepath != null && img.filepath!.isNotEmpty) {
              final file = File(img.filepath!);
              if (await file.exists()) {
                await file.delete();
                print('DataCleanupService: Deleted image file: ${img.filepath}');
              }
            }
          }
        }
        final deletedImagesByProblem = await _imageDao.deleteImagesByProblemIds(problemIdsToClean);
        print('DataCleanupService: Deleted $deletedImagesByProblem image records associated with cleaned problems.');
      }

      // --- 4. Delete DocumentRecords ---
      if (recordsToClean.isNotEmpty) {
        final deletedRecords = await _documentRecordDao.deleteRecordsBySyncStatus(1);
        print('DataCleanupService: Deleted $deletedRecords DocumentRecords with syncStatus 1.');
      }

      // --- 5. Delete Documents (only if ALL their records are cleaned) ---
      if (documentIdsToClean.isNotEmpty) {
        int deletedDocumentsCount = 0;
        for (final docId in documentIdsToClean.toSet()) {
          // CRUCIAL FIX: Await the stream to get the actual list of records
          final List<DocumentRecordWithTagAndProblem> remainingRecords = await _documentRecordDao.getDocumentRecordsList(docId, '').first; // <<< AWAIT HERE

          // Filter out records that are already cleaned (status 3, syncStatus 1)
          final pendingOrErrorRecords = remainingRecords.where((r) => r.documentRecord.status != 3 || r.documentRecord.syncStatus != 1).toList(); // <<< CRUCIAL FIX: Access .documentRecord

          if (pendingOrErrorRecords.isEmpty) {
            final deletedDoc = await _documentDao.deleteDocumentsByIds([docId]);
            if (deletedDoc > 0) {
              deletedDocumentsCount++;
            }
          }
        }
        print('DataCleanupService: Deleted $deletedDocumentsCount Documents whose records were all cleaned.');
      }

      // --- 6. Delete Problems ---
      if (problemsToClean.isNotEmpty) {
        final deletedProblems = await _problemDao.deleteProblemsBySyncStatus(1);
        print('DataCleanupService: Deleted $deletedProblems Problems with syncStatus 1.');
      }

      print('DataCleanupService: CleanEndData process completed successfully.');
      return const SyncSuccess(message: 'ล้างข้อมูลที่ซิงค์แล้วสำเร็จ!');
    } catch (e) {
      print('DataCleanupService: Error during cleanEndData: $e');
      return SyncError(exception: e, message: 'ข้อผิดพลาดในการล้างข้อมูลที่ซิงค์แล้ว: $e');
    }
  }
}