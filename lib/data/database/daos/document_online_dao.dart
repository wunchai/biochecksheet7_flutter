// lib/data/database/daos/document_online_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_online_table.dart';

part 'document_online_dao.g.dart';

@DriftAccessor(tables: [DocumentOnlines])
class DocumentOnlineDao extends DatabaseAccessor<AppDatabase> with _$DocumentOnlineDaoMixin {
  DocumentOnlineDao(AppDatabase db) : super(db);

  /// Retrieves all document onlines.
  Future<List<DbDocumentOnline>> getAllDocumentOnlines() => select(documentOnlines).get();

  /// Watches a stream of document onlines, ordered by createDate descending.
  Stream<List<DbDocumentOnline>> watchAllDocumentOnlines() {
    return (select(documentOnlines)..orderBy([(t) => OrderingTerm(expression: t.createDate, mode: OrderingMode.desc)])).watch();
  }

  /// Retrieves a specific document online by its documentId.
  Future<DbDocumentOnline?> getDocumentOnlineById(String documentId) {
    return (select(documentOnlines)..where((t) => t.documentId.equals(documentId))).getSingleOrNull();
  }

  /// Inserts a new document online into the database.
  Future<int> insertDocumentOnline(DocumentOnlinesCompanion entry) => into(documentOnlines).insert(entry);

  /// Updates an existing document online in the database.
  Future<bool> updateDocumentOnline(DocumentOnlinesCompanion entry) {
    return update(documentOnlines).replace(entry);
  }

  /// Deletes a document online from the database.
  Future<int> deleteDocumentOnline(DbDocumentOnline documentOnline) {
    return delete(documentOnlines).delete(documentOnline);
  }

  /// Inserts a list of document onlines into the database.
  Future<void> insertAllDocumentOnlines(List<DocumentOnlinesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(documentOnlines, entries);
    });
  }

  /// Deletes all document onlines from the database.
  Future<int> deleteAllDocumentOnlines() {
    return delete(documentOnlines).go();
  }

  Future<void> replaceAllDocumentOnlines(List<DocumentOnlinesCompanion> entries) async {
    await transaction(() async {
      await deleteAllDocumentOnlines();
      await insertAllDocumentOnlines(entries);
    });
  }
}
