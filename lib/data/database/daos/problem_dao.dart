// lib/data/database/daos/problem_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';

part 'problem_dao.g.dart';

@DriftAccessor(tables: [Problems])
class ProblemDao extends DatabaseAccessor<AppDatabase> with _$ProblemDaoMixin {
  ProblemDao(AppDatabase db) : super(db);

  // Inserts a new problem record.
  Future<int> insertProblem(ProblemsCompanion entry) => into(problems).insert(entry);

  // Updates an existing problem record.
  Future<bool> updateProblem(ProblemsCompanion entry) {
    return update(problems).replace(entry);
  }


  /// NEW: Deletes problem records filtered by syncStatus.
  Future<int> deleteProblemsBySyncStatus(int syncStatus) {
    return (delete(problems)..where((tbl) => tbl.syncStatus.equals(syncStatus))).go();
  }
  
  // Deletes a specific problem record.
  Future<int> deleteProblem(DbProblem entry) => delete(problems).delete(entry);

  // Watches a stream of problem records filtered by their status.
  Stream<List<DbProblem>> watchProblemsByStatus(List<int> statuses) {
    return (select(problems)..where((tbl) => tbl.problemStatus.isIn(statuses))).watch();
  }

  // Gets a single problem record by its UID.
  Future<DbProblem?> getProblemByUid(int uid) {
    return (select(problems)..where((tbl) => tbl.uid.equals(uid))).getSingleOrNull();
  }

  /// NEW: Gets problem records filtered by syncStatus.
  Future<List<DbProblem>> getProblemsBySyncStatus(int syncStatus) { // <<< NEW METHOD
    return (select(problems)..where((tbl) => tbl.syncStatus.equals(syncStatus))).get();
  }
  // NEW: Gets a single problem record by its problemId (from API/backend).
  Future<DbProblem?> getProblemByProblemId(String problemId) {
    return (select(problems)..where((tbl) => tbl.problemId.equals(problemId))).getSingleOrNull();
  }

  // Deletes all problem records.
  Future<int> deleteAllProblems() {
    return delete(problems).go();
  }

  // Inserts multiple problem records in a single batch.
  Future<void> insertAllProblems(List<ProblemsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(problems, entries);
    });
  }
}