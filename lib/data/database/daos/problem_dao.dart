// lib/data/database/daos/problem_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // Import your table

part 'problem_dao.g.dart';

@DriftAccessor(tables: [Problems])
class ProblemDao extends DatabaseAccessor<AppDatabase> with _$ProblemDaoMixin {
  ProblemDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertProblem(problem: DbProblem) in DaoProblem.kt
  Future<int> insertProblem(ProblemsCompanion entry) => into(problems).insert(entry);

  // Equivalent to suspend fun insertAll(problems: List<DbProblem>)
  Future<void> insertAllProblems(List<ProblemsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(problems, entries);
    });
  }

  // Equivalent to suspend fun getProblem(problemId: String): DbProblem?
  Future<DbProblem?> getProblem(String problemId) {
    return (select(problems)..where((tbl) => tbl.problemId.equals(problemId))).getSingleOrNull();
  }

  // Equivalent to suspend fun getAllProblem(): List<DbProblem>
  Stream<List<DbProblem>> watchAllProblems() => select(problems).watch();
  Future<List<DbProblem>> getAllProblems() => select(problems).get();

  // Equivalent to suspend fun updateProblem(problem: DbProblem)
  Future<bool> updateProblem(DbProblem entry) => update(problems).replace(entry);

  // Equivalent to suspend fun deleteProblem(problem: DbProblem)
  Future<int> deleteProblem(DbProblem entry) => delete(problems).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllProblems() => delete(problems).go();
}