// lib/data/database/daos/document_machine_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart'; // Import your table

part 'document_machine_dao.g.dart';

@DriftAccessor(tables: [DocumentMachines])
class DocumentMachineDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentMachineDaoMixin {
  DocumentMachineDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertDocumentMachine(documentMachine: DbDocumentMachine) in DaoDocumentMachine.kt
  Future<int> insertDocumentMachine(DocumentMachinesCompanion entry) =>
      into(documentMachines).insert(entry);

  // Equivalent to suspend fun insertAll(documentMachines: List<DbDocumentMachine>)
  Future<void> insertAllDocumentMachines(
      List<DocumentMachinesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(documentMachines, entries);
    });
  }

  /// NEW: Gets the latest lastSync timestamp from the document_machines table.
  Future<String?> getLastSync() async {
    final result =
        await customSelect('SELECT MAX(lastSync) FROM document_machines')
            .getSingleOrNull();
    return result?.data.values.first?.toString();
  }

  // Equivalent to suspend fun getDocumentMachine(documentId: String, machineId: String): DbDocumentMachine?
  Future<DbDocumentMachine?> getDocumentMachine(
      String documentId, String machineId) {
    return (select(documentMachines)
          ..where((tbl) =>
              tbl.documentId.equals(documentId) &
              tbl.machineId.equals(machineId)))
        .getSingleOrNull();
  }

  // Equivalent to suspend fun getAllDocumentMachine(): List<DbDocumentMachine>
  Stream<List<DbDocumentMachine>> watchAllDocumentMachines() =>
      select(documentMachines).watch();
  Future<List<DbDocumentMachine>> getAllDocumentMachines() =>
      select(documentMachines).get();

  // Equivalent to suspend fun getDocumentMachineList(documentId: String): List<DbDocumentMachine>
  Future<List<DbDocumentMachine>> getDocumentMachineList(String documentId) {
    return (select(documentMachines)
          ..where((tbl) => tbl.documentId.equals(documentId)))
        .get();
  }

  // Equivalent to suspend fun updateDocumentMachine(documentMachine: DbDocumentMachine)
  Future<bool> updateDocumentMachine(DbDocumentMachine entry) =>
      update(documentMachines).replace(entry);

  // Equivalent to suspend fun deleteDocumentMachine(documentMachine: DbDocumentMachine)
  Future<int> deleteDocumentMachine(DbDocumentMachine entry) =>
      delete(documentMachines).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllDocumentMachines() => delete(documentMachines).go();

  /// NEW: Updates the aggregated status of a machine based on its records.
  Future<void> updateMachineStatus(String documentId, String machineId) async {
    // 1. Calculate Aggregates using Custom Query
    final query = 'SELECT '
        'COUNT(*) as total, '
        'SUM(CASE WHEN status >= 1 THEN 1 ELSE 0 END) as saved, '
        'SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) as posted, '
        'SUM(CASE WHEN syncStatus = 1 THEN 1 ELSE 0 END) as synced '
        'FROM document_records '
        'WHERE documentId = ? AND machineId = ?';

    final result = await customSelect(query, variables: [
      Variable.withString(documentId),
      Variable.withString(machineId)
    ]).getSingleOrNull();

    if (result != null) {
      final total = result.data['total'] as int? ?? 0;
      final saved = result.data['saved'] as int? ??
          0; // Using double/int safe cast if needed, but drift usually returns int for Count/Sum
      final posted = result.data['posted'] as int? ?? 0;
      final synced = result.data['synced'] as int? ?? 0;

      // 2. Determine Aggregate Status
      int newStatus = 0; // Default: Pending
      if (total > 0) {
        if (synced == total) {
          newStatus = 4; // Fully Synced
        } else if (posted == total) {
          newStatus = 3; // All Posted
        } else if (saved == total) {
          newStatus = 2; // All Saved (Completed)
        } else if (saved > 0) {
          newStatus = 1; // In Progress
        }
      }

      // 3. Update DocumentMachine Table
      await (update(documentMachines)
            ..where((tbl) =>
                tbl.documentId.equals(documentId) &
                tbl.machineId.equals(machineId)))
          .write(DocumentMachinesCompanion(
        totalTags: Value(total),
        savedTags: Value(saved),
        postedTags: Value(posted),
        syncedTags: Value(synced),
        aggregateStatus: Value(newStatus),
      ));
    }
  }
}
