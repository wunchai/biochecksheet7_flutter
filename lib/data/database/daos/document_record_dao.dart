// lib/data/database/daos/document_record_dao.dart
import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // Import your table
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // Needed for joins

part 'document_record_dao.g.dart';

@DriftAccessor(tables: [DocumentRecords, JobTags])
class DocumentRecordDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentRecordDaoMixin {
  DocumentRecordDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertDocumentRecord(documentRecord: DbDocumentRecord) in DaoDocumentRecord.kt
  Future<int> insertDocumentRecord(DocumentRecordsCompanion entry) =>
      into(documentRecords).insert(entry);

  // Equivalent to suspend fun insertAll(documentRecords: List<DbDocumentRecord>)
  Future<void> insertAllDocumentRecords(
      List<DocumentRecordsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(documentRecords, entries);
    });
  }

  /// NEW: Counts DocumentRecords by a specific status and syncStatus.
  Future<int> countRecordsByStatusAndSyncStatus(
      int status, int syncStatus) async {
    // CRUCIAL FIX: Use customSelect to get the aggregated value directly.
    final result = await customSelect(
      'SELECT COUNT(*) FROM document_records WHERE status = ? AND syncStatus = ?',
      variables: [
        drift.Variable.withInt(status),
        drift.Variable.withInt(syncStatus),
      ],
    ).getSingleOrNull();

    // The result is a TypedResult, which contains a Map of data.
    // The count value will be in the first (and only) column.
    return result?.data.values.first as int? ?? 0; // Safely extract as int
  }

  /// NEW: Gets the latest lastSync timestamp for DocumentRecords
  /// matching a specific status and syncStatus.
  Future<String?> getLastSyncForRecordsByStatusAndSyncStatus(
      int status, int syncStatus) async {
    // Use customSelect with parameters for status and syncStatus
    final result = await customSelect(
      'SELECT MAX(lastSync) FROM document_records WHERE status = ? AND syncStatus = ?',
      variables: [
        drift.Variable.withInt(status),
        drift.Variable.withInt(syncStatus),
      ],
    ).getSingleOrNull();
    return result?.data.values.first?.toString();
  }

  // NEW: Method to get document records filtered by documentId, machineId, and status
  Future<List<DbDocumentRecord>> getRecordsByStatus(
      String documentId, String machineId, int status) {
    return (select(documentRecords)
          ..where((tbl) =>
              tbl.documentId.equals(documentId) &
              tbl.machineId.equals(machineId) &
              tbl.status.equals(status)))
        .get();
  }

  /// NEW: Watches DocumentRecords that are ready for upload (status = 2 and syncStatus = 0).
  Stream<List<DbDocumentRecord>> watchRecordsForUpload() {
    return (select(documentRecords)
          ..where((tbl) =>
              tbl.status.equals(2) & // Status 2: Ready for upload
              tbl.syncStatus.equals(0))) // SyncStatus 0: Not yet synced
        .watch();
  }

  /// NEW: Gets DocumentRecords filtered by syncStatus.
  Future<List<DbDocumentRecord>> getRecordsBySyncStatus(int syncStatus) {
    return (select(documentRecords)
          ..where((tbl) => tbl.syncStatus.equals(syncStatus)))
        .get();
  }

  /// NEW: Deletes DocumentRecords filtered by syncStatus.
  Future<int> deleteRecordsBySyncStatus(int syncStatus) {
    return (delete(documentRecords)
          ..where((tbl) => tbl.syncStatus.equals(syncStatus)))
        .go();
  }

  /// NEW: Updates the status and syncStatus of a DocumentRecord by UID.
  Future<bool> updateDocumentRecordStatusAndSyncStatus(
      int uid, int newStatus, int newSyncStatus) async {
    // CRUCIAL FIX: Use .write() for UpdateStatement
    final updatedRows = await (update(documentRecords)
          ..where((tbl) => tbl.uid.equals(uid)))
        .write(
      DocumentRecordsCompanion(
        status: drift.Value(newStatus),
        syncStatus: drift.Value(newSyncStatus),
        lastSync: drift.Value(
            DateTime.now().toIso8601String()), // Update last sync time
      ),
    );
    return updatedRows > 0; // Return true if at least one row was updated
  }

  // NEW: Delete all document records associated with a specific documentId
  Future<int> deleteAllRecordsByDocumentId(String documentId) {
    return (delete(documentRecords)
          ..where((tbl) => tbl.documentId.equals(documentId)))
        .go();
  }

  // Gets a single document record by its local UID.
  Future<DbDocumentRecord?> getDocumentRecordByUid(int uid) {
    return (select(documentRecords)..where((tbl) => tbl.uid.equals(uid)))
        .getSingleOrNull();
  }

  // NEW: Get all document records associated with a specific documentId (for copy operation)
  Future<List<DbDocumentRecord>> getRecordsByDocumentId(String documentId) {
    return (select(documentRecords)
          ..where((tbl) => tbl.documentId.equals(documentId)))
        .get();
  }

  // Equivalent to suspend fun getDocumentRecord(documentId: String, machineId: String, tagId: String): DbDocumentRecord?
  Future<DbDocumentRecord?> getDocumentRecord({
    // <<< เพิ่ม { } ตรงนี้
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
  Stream<List<DbDocumentRecord>> watchAllDocumentRecords() =>
      select(documentRecords).watch();
  Future<List<DbDocumentRecord>> getAllDocumentRecords() =>
      select(documentRecords).get();

  // Corrected: Update method to accept DocumentRecordsCompanion
  Future<bool> updateDocumentRecord(DocumentRecordsCompanion entry) {
    // <<< เปลี่ยน Type จาก DbDocumentRecord เป็น DocumentRecordsCompanion
    return update(documentRecords)
        .replace(entry); // .replace() works with Companion
  }

  // Equivalent to suspend fun deleteDocumentRecord(documentRecord: DbDocumentRecord)
  Future<int> deleteDocumentRecord(DbDocumentRecord entry) =>
      delete(documentRecords).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllDocumentRecords() => delete(documentRecords).go();

  // Equivalent to fun getDocumentRecordsList(documentId: String, machineId: String): LiveData<List<DbDocumentRecord>>
  // This function will need to join with JobTags and Problems, similar to the Room query.
  // For LiveData equivalent, we return a Stream.
  Stream<List<DocumentRecordWithTagAndProblem>> getDocumentRecordsList(
      String documentId, String machineId) {
    print(
        'DocumentRecordDao: Querying records for DocID=$documentId, MachineID=$machineId');
    final query = select(documentRecords).join([
      // CRUCIAL FIX: Add more conditions to the INNER JOIN to ensure uniqueness
      // Join on tagId AND jobId AND machineId to precisely match the record to its tag
      leftOuterJoin(
          jobTags,
          jobTags.tagId.equalsExp(documentRecords.tagId) & // Match by Tag ID
              jobTags.jobId.equalsExp(
                  documentRecords.jobId) & // Match by Job ID (from record)
              jobTags.machineId.equalsExp(documentRecords
                  .machineId) // Match by Machine ID (from record)
          ),
    ])
      ..where(documentRecords.documentId.equals(documentId) &
          documentRecords.machineId.equals(machineId))
      ..orderBy([
        drift.OrderingTerm(expression: jobTags.jobId),
        drift.OrderingTerm(expression: jobTags.machineId),
        drift.OrderingTerm(expression: jobTags.tagGroupId),
        drift.OrderingTerm(
            expression:
                drift.CustomExpression('CAST(job_tags.OrderId AS INTEGER)')),
      ]);

    print(
        'DocumentRecordDao: Generated SQL for getDocumentRecordsList: ${query.toString()}');

    return query.map((row) {
      final documentRecord = row.readTable(documentRecords);
      final jobTag = row.readTable(jobTags);
      return DocumentRecordWithTagAndProblem(
        documentRecord: documentRecord,
        jobTag: jobTag,
      );
    }).watch();
  }

  // Corrected: Method to watch document records specifically for chart plotting
  // Filters by jobId, machineId, and tagId, and orders by lastSync for time series.
  Stream<List<DbDocumentRecord>> watchRecordsForChart(
      String jobId, String machineId, String tagId) {
    // <<< Changed documentId to jobId
    print(
        'DocumentRecordDao: WatchRecordsForChart called for JobID=$jobId, MachineID=$machineId, TagID=$tagId'); // <<< Changed Log
    final query = select(documentRecords)
      ..where((tbl) =>
          tbl.jobId.equals(jobId) & // <<< Changed to jobId
          tbl.machineId.equals(machineId) &
          tbl.tagId.equals(tagId))
      ..orderBy([
        (tbl) => drift.OrderingTerm(
            expression: tbl.lastSync, mode: drift.OrderingMode.asc),
      ]);
    print(
        'DocumentRecordDao: Generated SQL for watchRecordsForChart: ${query.toString()}');
    return query.watch();
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

  DocumentRecordWithTagAndProblem({
    required this.documentRecord,
    this.jobTag,
  });
}
