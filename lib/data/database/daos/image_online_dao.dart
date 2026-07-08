import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/image_online_table.dart';

part 'image_online_dao.g.dart';

@DriftAccessor(tables: [DocumentImageOnlines])
class DocumentImageOnlineDao extends DatabaseAccessor<AppDatabase> with _$DocumentImageOnlineDaoMixin {
  DocumentImageOnlineDao(AppDatabase db) : super(db);

  // Get images for a specific document
  Future<List<DbDocumentImageOnline>> getImagesByDocumentId(String documentId) {
    return (select(documentImageOnlines)..where((t) => t.documentId.equals(documentId))).get();
  }

  // Get images for a specific tag
  Future<List<DbDocumentImageOnline>> getImagesForTag(String documentId, String machineId, String tagId) {
    return (select(documentImageOnlines)
      ..where((t) => t.documentId.equals(documentId))
      ..where((t) => t.machineId.equals(machineId))
      ..where((t) => t.tagId.equals(tagId))
    ).get();
  }

  // Insert a single image
  Future<int> insertImage(DocumentImageOnlinesCompanion image) {
    return into(documentImageOnlines).insert(image);
  }

  // Update a single image (e.g. adding base64 string later)
  Future<bool> updateImage(DbDocumentImageOnline image) {
    return update(documentImageOnlines).replace(image);
  }
  
  // Update base64 picture by uid
  Future<int> updatePictureBase64(int uid, String base64) {
    return (update(documentImageOnlines)..where((t) => t.uid.equals(uid)))
        .write(DocumentImageOnlinesCompanion(picture: Value(base64)));
  }

  // Delete all images for a specific document
  Future<int> deleteImagesByDocumentId(String documentId) {
    return (delete(documentImageOnlines)..where((t) => t.documentId.equals(documentId))).go();
  }

  // Clear all
  Future<int> clearAllImages() {
    return delete(documentImageOnlines).go();
  }
}
