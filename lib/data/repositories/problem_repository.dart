// lib/data/repositories/problem_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart'; // For ProblemDao
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem and ProblemsCompanion
import 'package:drift/drift.dart' as drift;

// TODO: Import ProblemApiService for sync in Phase 4
// import 'package:biochecksheet7_flutter/data/network/problem_api_service.dart';

class ProblemRepository {
  final ProblemDao _problemDao;
  // TODO: Add ProblemApiService if needed for sync
  // final ProblemApiService _problemApiService;

  ProblemRepository({required AppDatabase appDatabase})
      : _problemDao = appDatabase.problemDao;
      // _problemApiService = problemApiService ?? ProblemApiService();

  /// Watches a stream of problem records filtered by their status (0, 1, 2).
  Stream<List<DbProblem>> watchProblemsByStatus(List<int> statuses) {
    return _problemDao.watchProblemsByStatus(statuses);
  }

  /// Gets a single problem record by its UID.
  Future<DbProblem?> getProblemByUid(int uid) {
    return _problemDao.getProblemByUid(uid);
  }

 /// Updates a problem record locally.
  Future<bool> updateProblem({
    required int uid,
    String? problemSolvingDescription,
    int? newProblemStatus, // Status for the problem record itself
    String? problemSolvingBy, // User who solved it
    int? newSyncStatus, // Sync status for the problem record
  }) async {
    try {
      final existingProblem = await _problemDao.getProblemByUid(uid);
      if (existingProblem == null) {
        throw Exception("Problem with UID $uid not found for update.");
      }

      final updatedCompanion = ProblemsCompanion(
        uid: drift.Value(uid),
        problemSolvingDescription: problemSolvingDescription != null
            ? drift.Value(problemSolvingDescription)
            : drift.Value(existingProblem.problemSolvingDescription),
        problemStatus: newProblemStatus != null
            ? drift.Value(newProblemStatus)
            : drift.Value(existingProblem.problemStatus),
        problemSolvingBy: problemSolvingBy != null
            ? drift.Value(problemSolvingBy)
            : drift.Value(existingProblem.problemSolvingBy),
        syncStatus: newSyncStatus != null
            ? drift.Value(newSyncStatus)
            : drift.Value(existingProblem.syncStatus),
        lastSync: drift.Value(DateTime.now().toIso8601String()), // Update last sync timestamp
        // No need to update machineName or jobId here unless they are part of the update flow
      );

      final success = await _problemDao.updateProblem(updatedCompanion);
      print('Problem UID $uid updated: SolvingDesc=${problemSolvingDescription ?? existingProblem.problemSolvingDescription}, Status=${newProblemStatus ?? existingProblem.problemStatus}');
      return success;
    } catch (e) {
      print('Error updating problem UID $uid: $e');
      throw Exception('Failed to update problem: $e');
    }
  }

  // TODO: Add methods for creating new problems (if needed, e.g., from DocumentRecordScreen)
  // TODO: Add methods for deleting problems

  // TODO: Add method for syncing problems to API in Phase 4
  /*
  Future<bool> uploadProblemsToServer() async {
    // Fetch problems with syncStatus 0
    // Call ProblemApiService to upload
    // Update syncStatus to 1 after successful upload
  }
  */
}