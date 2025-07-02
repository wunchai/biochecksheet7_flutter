// lib/data/database/daos/image_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For AppDatabase access
import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart'; // For Images table and DbImage

part 'image_dao.g.dart'; // This line tells drift to generate a file named image_dao.g.dart

@DriftAccessor(tables: [Images]) // กำหนดตารางที่ DAO นี้จะเข้าถึง
class ImageDao extends DatabaseAccessor<AppDatabase> with _$ImageDaoMixin {
  ImageDao(AppDatabase db) : super(db);

  // Inserts a new image record.
  Future<int> insertImage(ImagesCompanion entry) => into(images).insert(entry);

  // Updates an existing image record.
  Future<bool> updateImage(DbImage entry) => update(images).replace(entry);

  // Deletes a specific image record.
  Future<int> deleteImage(DbImage entry) => delete(images).delete(entry);

  // Gets all images for a specific document, machine, job, and tag.
  Stream<List<DbImage>> watchImagesForRecord({
    required String documentId,
    required String machineId,
    required String jobId,
    required String tagId,
    String? problemId, // <<< NEW: Optional problemId for filtering
  }) {
    // Start with the base query
    var query = select(images)
        ..where((tbl) =>
            tbl.documentId.equals(documentId) &
            tbl.machineId.equals(machineId) &
            tbl.jobId.equals(jobId) &
            tbl.tagId.equals(tagId));
    
    // Add problemId filter if provided
    if (problemId != null && problemId.isNotEmpty) {
      query = query..where((tbl) => tbl.problemId.equals(problemId));
    }
    
    return query.watch();
  }

  // Gets a single image by its UID.
  Future<DbImage?> getImageByUid(int uid) {
    return (select(images)..where((tbl) => tbl.uid.equals(uid))).getSingleOrNull();
  }

  // Deletes all images associated with a specific documentId (e.g., when document is deleted).
  Future<int> deleteAllImagesByDocumentId(String documentId) {
    return (delete(images)..where((tbl) => tbl.documentId.equals(documentId))).go();
  }
}