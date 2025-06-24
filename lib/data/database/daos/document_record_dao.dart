// lib/data/database/daos/document_record_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // Import your table
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // Needed for joins
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // Needed for joins

part 'document_record_dao.g.dart';

@DriftAccessor(tables: [DocumentRecords, JobTags, Problems])
class DocumentRecordDao extends DatabaseAccessor<AppDatabase> with _$DocumentRecordDaoMixin {
  DocumentRecordDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertDocumentRecord(documentRecord: DbDocumentRecord) in DaoDocumentRecord.kt
  Future<int> insertDocumentRecord(DocumentRecordsCompanion entry) => into(documentRecords).insert(entry);

  // Equivalent to suspend fun insertAll(documentRecords: List<DbDocumentRecord>)
  Future<void> insertAllDocumentRecords(List<DocumentRecordsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(documentRecords, entries);
    });
  }

// NEW: Method to get a single document record by its local UID
  Future<DbDocumentRecord?> getDocumentRecordByUid(int uid) {
    return (select(documentRecords)..where((tbl) => tbl.uid.equals(uid))).getSingleOrNull();
  }
  
  // Equivalent to suspend fun getDocumentRecord(documentId: String, machineId: String, tagId: String): DbDocumentRecord?
   Future<DbDocumentRecord?> getDocumentRecord({ // <<< เพิ่ม { } ตรงนี้
    required String documentId,
    required String machineId,
    required String tagId,
  }) {
    return (select(documentRecords)
          ..where((tbl) =>
              tbl.documentId.equals(documentId) &
              tbl.machineId.equals(machineId) &
              tbl.tagId.equals(tagId)))
        .getSingleOrNull();
  }

  // Equivalent to suspend fun getAllDocumentRecord(): List<DbDocumentRecord>
  Stream<List<DbDocumentRecord>> watchAllDocumentRecords() => select(documentRecords).watch();
  Future<List<DbDocumentRecord>> getAllDocumentRecords() => select(documentRecords).get();


  // Equivalent to suspend fun updateDocumentRecord(documentRecord: DbDocumentRecord)
  Future<bool> updateDocumentRecord(DbDocumentRecord entry) => update(documentRecords).replace(entry);

  // Equivalent to suspend fun deleteDocumentRecord(documentRecord: DbDocumentRecord)
  Future<int> deleteDocumentRecord(DbDocumentRecord entry) => delete(documentRecords).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllDocumentRecords() => delete(documentRecords).go();

  // Equivalent to fun getDocumentRecordsList(documentId: String, machineId: String): LiveData<List<DbDocumentRecord>>
  // This function will need to join with JobTags and Problems, similar to the Room query.
  // For LiveData equivalent, we return a Stream.
  Stream<List<DocumentRecordWithTagAndProblem>> getDocumentRecordsList(String documentId, String machineId) {
    final query = select(documentRecords).join([
      leftOuterJoin(jobTags, jobTags.tagId.equalsExp(documentRecords.tagId)),
      leftOuterJoin(problems, problems.problemId.equalsExp(documentRecords.value)), // Assuming value holds problemId for problem tags
    ])
      ..where(documentRecords.documentId.equals(documentId) & documentRecords.machineId.equals(machineId))
      ..orderBy([
        // Corrected lines: Pass OrderingTerm directly, not a function returning it
        OrderingTerm(expression: jobTags.tagGroupId),
        OrderingTerm(expression: documentRecords.tagType),
        OrderingTerm(expression: documentRecords.tagName),
      ]);

    return query.map((row) {
      final documentRecord = row.readTable(documentRecords);
      final jobTag = row.readTableOrNull(jobTags);
      final problem = row.readTableOrNull(problems);
      return DocumentRecordWithTagAndProblem(
        documentRecord: documentRecord,
        jobTag: jobTag,
        problem: problem,
      );
    }).watch();
  }

  // TODO: Implement getDocumentRecordsChart(documentId: String, machineId: String, tagId: String): LiveData<List<DbDocumentRecord>>
  // This will involve complex queries and possibly custom data structures for chart data.
  // We will need to define a custom query with `@Query()` or build it using `select` and `where` clauses.
  // For now, let's just put a placeholder.
  Future<List<DbDocumentRecord>> getDocumentRecordsChart(
      String documentId, String machineId, String tagId) async {
    return (select(documentRecords)
          ..where((tbl) =>
              tbl.documentId.equals(documentId) &
              tbl.machineId.equals(machineId) &
              tbl.tagId.equals(tagId)))
        .get();
  }
}

// This class is a helper to combine data from multiple tables for the UI,
// similar to how Room handles return types for joins.
class DocumentRecordWithTagAndProblem {
  final DbDocumentRecord documentRecord;
  final DbJobTag? jobTag; // Nullable if leftOuterJoin
  final DbProblem? problem; // Nullable if leftOuterJoin

  DocumentRecordWithTagAndProblem({
    required this.documentRecord,
    this.jobTag,
    this.problem,
  });
}