// lib/data/database/daos/sync_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart'; // Import your table

part 'sync_dao.g.dart';

@DriftAccessor(tables: [Syncs])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertSync(sync: DbSync) in DaoSync.kt
  Future<int> insertSync(SyncsCompanion entry) => into(syncs).insert(entry);

  // Equivalent to suspend fun insertAll(syncs: List<DbSync>)
  Future<void> insertAllSyncs(List<SyncsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(syncs, entries);
    });
  }

  // Equivalent to suspend fun getSync(syncId: String): DbSync?
  Future<DbSync?> getSync(String syncId) {
    return (select(syncs)..where((tbl) => tbl.syncId.equals(syncId))).getSingleOrNull();
  }

  // Equivalent to suspend fun getSyncList(): List<DbSync>
  Stream<List<DbSync>> watchSyncList() => select(syncs).watch();
  Future<List<DbSync>> getSyncList() => select(syncs).get();

  // Equivalent to suspend fun updateSync(sync: DbSync)
  Future<bool> updateSync(DbSync entry) => update(syncs).replace(entry);

  // Equivalent to suspend fun deleteSync(sync: DbSync)
  Future<int> deleteSync(DbSync entry) => delete(syncs).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllSyncs() => delete(syncs).go();
}