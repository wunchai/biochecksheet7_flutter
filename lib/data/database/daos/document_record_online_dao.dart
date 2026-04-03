// lib/data/database/daos/document_record_online_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_online_table.dart';

part 'document_record_online_dao.g.dart';

@DriftAccessor(tables: [DocumentRecordOnlines])
class DocumentRecordOnlineDao extends DatabaseAccessor<AppDatabase> with _$DocumentRecordOnlineDaoMixin {
  DocumentRecordOnlineDao(super.db);

  // Clear all for a specific document ID
  Future<void> deleteRecordsByDocumentId(String documentId) async {
    await (delete(documentRecordOnlines)..where((tbl) => tbl.documentId.equals(documentId))).go();
  }

  // Insert a large batch of records concurrently using batch
  Future<void> insertMultipleRecords(List<DocumentRecordOnlinesCompanion> records) async {
    await batch((batch) {
      batch.insertAll(documentRecordOnlines, records);
    });
  }

  // Get distinct machines for a document
  // We use db.customSelect to perform GROUP BY or DISTINCT efficiently if necessary, 
  // or simply use distinct on select.
  Stream<List<DbDocumentRecordOnline>> watchDistinctMachines(String documentId) {
    // A trick to get distinct machine configs is grouping by machineId
    final query = select(documentRecordOnlines)
      ..where((tbl) => tbl.documentId.equals(documentId));
      // Drift doesn't support GROUP BY easily in expression builder without custom queries sometimes,
      // but we can query it and process it. Or just use a custom query:
    
    return customSelect(
      '''
      SELECT d.uid, d.machineId, d.uiType, d.documentId, j.MachineName
      FROM document_record_onlines d
      LEFT JOIN job_machines j ON d.machineId = j.MachineId AND d.jobId = j.JobId
      WHERE d.documentId = ?
      GROUP BY d.machineId, d.uiType
      ''',
      variables: [Variable.withString(documentId)],
      readsFrom: {documentRecordOnlines, db.jobMachines},
    ).watch().map((rows) {
      return rows.map((row) {
        return DbDocumentRecordOnline(
          uid: row.read<int>('uid'),
          machineId: row.read<String>('machineId'),
          uiType: row.read<int>('uiType'),
          description: row.read<String?>('MachineName'), // Reusing description field to hold MachineName
          // dummy values for the rest as we only need machine info
          documentId: row.read<String>('documentId'),
          status: 0,
          unReadable: 'false',
        );
      }).toList();
    });
  }

  // Get records grouped by TagGroupId for AMChecksheetOnline Screen
  Stream<List<DbDocumentRecordOnline>> watchRecordsForMachine(String documentId, String machineId) {
    return (select(documentRecordOnlines)
      ..where((tbl) => tbl.documentId.equals(documentId) & tbl.machineId.equals(machineId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.tagGroupId, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.uid, mode: OrderingMode.asc), // Fallback order
      ])
    ).watch();
  }
}
