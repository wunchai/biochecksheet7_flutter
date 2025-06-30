// lib/data/database/daos/document_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // Import your table

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentDao extends DatabaseAccessor<AppDatabase> with _$DocumentDaoMixin {
  DocumentDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertDocument(document: DbDocument) in DaoDocument.kt
  Future<int> insertDocument(DocumentsCompanion entry) => into(documents).insert(entry);

  // Equivalent to suspend fun insertAll(documents: List<DbDocument>)
  Future<void> insertAllDocuments(List<DocumentsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(documents, entries);
    });
  }

  // Equivalent to suspend fun getDocument(documentId: String): DbDocument?
  Future<DbDocument?> getDocument(String documentId) {
    return (select(documents)..where((tbl) => tbl.documentId.equals(documentId))).getSingleOrNull();
  }

  // Equivalent to suspend fun getAllDocument(): List<DbDocument>
  Stream<List<DbDocument>> watchAllDocuments() => select(documents).watch();
  Future<List<DbDocument>> getAllDocuments() => select(documents).get();
  
  // NEW: Method to get a single document by its documentId
  Future<DbDocument?> getDocumentById(String documentId) {
    return (select(documents)..where((tbl) => tbl.documentId.equals(documentId))).getSingleOrNull();
  }

  // Equivalent to suspend fun updateDocument(document: DbDocument)
  Future<bool> updateDocument(DbDocument entry) => update(documents).replace(entry);

  // Equivalent to suspend fun deleteDocument(document: DbDocument)
  Future<int> deleteDocument(DbDocument entry) => delete(documents).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllDocuments() => delete(documents).go();

  // NEW: Equivalent to suspend fun getDocumentList(jobId: String): LiveData<List<DbDocument>>
  Future<List<DbDocument>> getDocumentsByJobId(String jobId) {
    return (select(documents)..where((tbl) => tbl.jobId.equals(jobId))).get();
  }

  // Optional: If you need a stream of filtered documents (like LiveData)
  Stream<List<DbDocument>> watchDocumentsByJobId(String jobId) {
    return (select(documents)..where((tbl) => tbl.jobId.equals(jobId))).watch();
  }

  // You might have custom queries in your DaoDocument.kt,
  // for example, to get documents by jobId. You can add them here:
  // Future<List<DbDocument>> getDocumentsByJobId(String jobId) {
  //   return (select(documents)..where((tbl) => tbl.jobId.equals(jobId))).get();
  // }
}