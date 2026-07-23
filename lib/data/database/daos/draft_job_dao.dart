// lib/data/database/daos/draft_job_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/draft_job_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/draft_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/draft_tag_table.dart';

part 'draft_job_dao.g.dart';

@DriftAccessor(tables: [DraftJobs, DraftMachines, DraftTags])
class DraftJobDao extends DatabaseAccessor<AppDatabase> with _$DraftJobDaoMixin {
  DraftJobDao(super.db);

  // --- Jobs ---
  Stream<List<DbDraftJob>> watchAllDraftJobs() {
    return select(draftJobs).watch();
  }

  Future<DbDraftJob> getDraftJob(String draftJobId) {
    return (select(draftJobs)..where((tbl) => tbl.uid.equals(draftJobId))).getSingle();
  }

  Future<int> countDraftJobsByStatus(int status) async {
    final countExp = draftJobs.uid.count();
    final query = selectOnly(draftJobs)
      ..addColumns([countExp])
      ..where(draftJobs.status.equals(status));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  Future<int> insertDraftJob(DraftJobsCompanion entry) {
    return into(draftJobs).insert(entry);
  }

  Future<void> upsertDraftJob(DraftJobsCompanion entry) {
    return into(draftJobs).insertOnConflictUpdate(entry);
  }

  Future<bool> updateDraftJob(DraftJobsCompanion entry) {
    return update(draftJobs).replace(entry);
  }

  Future<void> deleteDraftJob(String draftJobId) async {
    return transaction(() async {
      await (delete(draftTags)..where((tbl) => tbl.draftJobId.equals(draftJobId))).go();
      await (delete(draftMachines)..where((tbl) => tbl.draftJobId.equals(draftJobId))).go();
      await (delete(draftJobs)..where((tbl) => tbl.uid.equals(draftJobId))).go();
    });
  }

  // --- Machines ---
  Stream<List<DbDraftMachine>> watchMachinesForJob(String draftJobId) {
    return (select(draftMachines)..where((tbl) => tbl.draftJobId.equals(draftJobId))).watch();
  }
  
  Future<List<DbDraftMachine>> getMachinesForJob(String draftJobId) {
    return (select(draftMachines)..where((tbl) => tbl.draftJobId.equals(draftJobId))).get();
  }

  Future<DbDraftMachine> getDraftMachine(String draftMachineId) {
    return (select(draftMachines)..where((tbl) => tbl.uid.equals(draftMachineId))).getSingle();
  }

  Future<int> insertDraftMachine(DraftMachinesCompanion entry) {
    return into(draftMachines).insert(entry);
  }

  Future<void> upsertDraftMachine(DraftMachinesCompanion entry) {
    return into(draftMachines).insertOnConflictUpdate(entry);
  }

  Future<bool> updateDraftMachine(DraftMachinesCompanion entry) {
    return update(draftMachines).replace(entry);
  }

  Future<void> deleteDraftMachine(String draftMachineId) async {
    return transaction(() async {
      await (update(draftTags)..where((tbl) => tbl.draftMachineId.equals(draftMachineId)))
          .write(DraftTagsCompanion.custom(
              status: const Constant(4),
              recordVersion: draftTags.recordVersion + const Constant(1)));
      await (update(draftMachines)..where((tbl) => tbl.uid.equals(draftMachineId)))
          .write(DraftMachinesCompanion.custom(
              status: const Constant(4),
              recordVersion: draftMachines.recordVersion + const Constant(1)));
    });
  }

  // --- Tags ---
  Stream<List<DbDraftTag>> watchTagsForMachine(String draftMachineId) {
    return (select(draftTags)
          ..where((tbl) => tbl.draftMachineId.equals(draftMachineId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderId)]))
        .watch();
  }
  
  Future<List<DbDraftTag>> getTagsForMachine(String draftMachineId) {
    return (select(draftTags)
          ..where((tbl) => tbl.draftMachineId.equals(draftMachineId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderId)]))
        .get();
  }

  Future<DbDraftTag> getDraftTag(String draftTagId) {
    return (select(draftTags)..where((tbl) => tbl.uid.equals(draftTagId))).getSingle();
  }

  Future<int> insertDraftTag(DraftTagsCompanion entry) {
    return into(draftTags).insert(entry);
  }

  Future<void> upsertDraftTag(DraftTagsCompanion entry) {
    return into(draftTags).insertOnConflictUpdate(entry);
  }

  Future<bool> updateDraftTag(DraftTagsCompanion entry) {
    return update(draftTags).replace(entry);
  }

  Future<void> deleteDraftTag(String draftTagId) {
    return (update(draftTags)..where((tbl) => tbl.uid.equals(draftTagId)))
        .write(DraftTagsCompanion.custom(
            status: const Constant(4),
            recordVersion: draftTags.recordVersion + const Constant(1)));
  }

  Future<void> shiftDraftTagOrderIdsUp(String draftMachineId, int fromOrderId) async {
    await (update(draftTags)..where((t) => t.draftMachineId.equals(draftMachineId) & t.orderId.isBiggerOrEqualValue(fromOrderId))).write(
      DraftTagsCompanion.custom(orderId: draftTags.orderId + const Constant(1))
    );
  }

  // --- Auto-complete Sources ---
  Future<List<String>> getDistinctGroupNames(String draftJobId) async {
    final query = '''
      SELECT DISTINCT tagGroupName as name FROM draft_tags WHERE draftJobId = ? AND tagGroupName IS NOT NULL AND tagGroupName != ''
      UNION
      SELECT DISTINCT TagGroupName as name FROM job_tags WHERE TagGroupName IS NOT NULL AND TagGroupName != ''
    ''';
    final result = await customSelect(query, variables: [Variable.withString(draftJobId)]).get();
    return result.map((row) => row.read<String>('name')).toList();
  }

  Future<List<String>> getDistinctTagNames(String draftJobId) async {
    final query = '''
      SELECT DISTINCT tagName as name FROM draft_tags WHERE draftJobId = ? AND tagName IS NOT NULL AND tagName != ''
      UNION
      SELECT DISTINCT TagName as name FROM job_tags WHERE TagName IS NOT NULL AND TagName != ''
    ''';
    final result = await customSelect(query, variables: [Variable.withString(draftJobId)]).get();
    return result.map((row) => row.read<String>('name')).toList();
  }
}
