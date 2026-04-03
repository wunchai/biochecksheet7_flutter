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

  Future<DbDraftJob> getDraftJob(int draftJobId) {
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

  Future<bool> updateDraftJob(DraftJobsCompanion entry) {
    return update(draftJobs).replace(entry);
  }

  Future<void> deleteDraftJob(int draftJobId) async {
    return transaction(() async {
      await (delete(draftTags)..where((tbl) => tbl.draftJobId.equals(draftJobId))).go();
      await (delete(draftMachines)..where((tbl) => tbl.draftJobId.equals(draftJobId))).go();
      await (delete(draftJobs)..where((tbl) => tbl.uid.equals(draftJobId))).go();
    });
  }

  // --- Machines ---
  Stream<List<DbDraftMachine>> watchMachinesForJob(int draftJobId) {
    return (select(draftMachines)..where((tbl) => tbl.draftJobId.equals(draftJobId))).watch();
  }
  
  Future<List<DbDraftMachine>> getMachinesForJob(int draftJobId) {
    return (select(draftMachines)..where((tbl) => tbl.draftJobId.equals(draftJobId))).get();
  }

  Future<int> insertDraftMachine(DraftMachinesCompanion entry) {
    return into(draftMachines).insert(entry);
  }

  Future<void> deleteDraftMachine(int draftMachineId) async {
    return transaction(() async {
      await (delete(draftTags)..where((tbl) => tbl.draftMachineId.equals(draftMachineId))).go();
      await (delete(draftMachines)..where((tbl) => tbl.uid.equals(draftMachineId))).go();
    });
  }

  // --- Tags ---
  Stream<List<DbDraftTag>> watchTagsForMachine(int draftMachineId) {
    return (select(draftTags)..where((tbl) => tbl.draftMachineId.equals(draftMachineId))).watch();
  }
  
  Future<List<DbDraftTag>> getTagsForMachine(int draftMachineId) {
    return (select(draftTags)..where((tbl) => tbl.draftMachineId.equals(draftMachineId))).get();
  }

  Future<int> insertDraftTag(DraftTagsCompanion entry) {
    return into(draftTags).insert(entry);
  }

  Future<bool> updateDraftTag(DraftTagsCompanion entry) {
    return update(draftTags).replace(entry);
  }

  Future<void> deleteDraftTag(int draftTagId) {
    return (delete(draftTags)..where((tbl) => tbl.uid.equals(draftTagId))).go();
  }

  // --- Auto-complete Sources ---
  Future<List<String>> getDistinctGroupNames(int draftJobId) async {
    final query = '''
      SELECT DISTINCT tagGroupName as name FROM draft_tags WHERE draftJobId = ? AND tagGroupName IS NOT NULL AND tagGroupName != ''
      UNION
      SELECT DISTINCT TagGroupName as name FROM job_tags WHERE TagGroupName IS NOT NULL AND TagGroupName != ''
    ''';
    final result = await customSelect(query, variables: [Variable.withInt(draftJobId)]).get();
    return result.map((row) => row.read<String>('name')).toList();
  }

  Future<List<String>> getDistinctTagNames(int draftJobId) async {
    final query = '''
      SELECT DISTINCT tagName as name FROM draft_tags WHERE draftJobId = ? AND tagName IS NOT NULL AND tagName != ''
      UNION
      SELECT DISTINCT TagName as name FROM job_tags WHERE TagName IS NOT NULL AND TagName != ''
    ''';
    final result = await customSelect(query, variables: [Variable.withInt(draftJobId)]).get();
    return result.map((row) => row.read<String>('name')).toList();
  }
}
