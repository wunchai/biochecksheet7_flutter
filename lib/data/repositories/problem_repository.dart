// lib/data/repositories/problem_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart'; // For ProblemDao
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem and ProblemsCompanion
import 'package:drift/drift.dart' as drift;

import 'package:biochecksheet7_flutter/data/network/problem_api_service.dart'; // For ProblemApiService
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // <<< NEW: Import api_response_models.dart


class ProblemRepository {
  final ProblemDao _problemDao;
  final ProblemApiService _problemApiService; // Add ProblemApiService

  ProblemRepository({required AppDatabase appDatabase})
      : _problemDao = appDatabase.problemDao,
      _problemApiService = ProblemApiService();

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

  /// NEW: Uploads problems with problemStatus 2 (Posted) to the server.
  /// After successful upload for a problem, updates its problemStatus to 3 (Uploaded) and syncStatus to 1.
  Future<bool> uploadProblemsToServer() async {
    try {
      // 1. Get problems that are ready for upload (ProblemStatus 2)
      final problemsToUpload = await _problemDao.watchProblemsByStatus([2]).first; // Get all problems that are status 2

      if (problemsToUpload.isEmpty) {
        print('No problems found with ProblemStatus 2 to upload.');
        return true; // Nothing to upload, consider it successful
      }

      // 2. Call API service to upload these problems
      // Expect List<UploadRecordResult> from API service
      final List<UploadRecordResult> uploadResults = await _problemApiService.uploadProblems(problemsToUpload);

      // 3. Process upload results and update problemStatus / syncStatus in local DB
      bool overallUploadSuccess = true;
      for (final apiResult in uploadResults) {
        final int problemUid = apiResult.uid;
        final int apiResultCode = apiResult.result; // Assuming 3 for success

        // Determine new problemStatus and syncStatus based on API result
        int newProblemStatusToSet = 2; // Default to keeping 2 if API didn't confirm success
        int newSyncStatusToSet = 0; // Default to 0 (failed/not synced)

        if (apiResultCode == 3) { // Assuming 3 means success from API
          newProblemStatusToSet = 3; // Set to 3 (Uploaded)
          newSyncStatusToSet = 1; // Set syncStatus to 1 (Synced)
        }

        // Update problem's status and syncStatus based on API response
        final success = await _problemDao.updateProblem(
          ProblemsCompanion(
            uid: drift.Value(problemUid),
            problemStatus: drift.Value(newProblemStatusToSet), // Update problemStatus
            syncStatus: drift.Value(newSyncStatusToSet), // Update syncStatus
            lastSync: drift.Value(DateTime.now().toIso8601String()), // Update last sync timestamp
          ),
        );
        if (!success) {
          overallUploadSuccess = false; // If any local DB update fails, mark overall as failed
          print('Failed to update local status/syncStatus for Problem UID $problemUid');
        }
      }

      print('Processed ${uploadResults.length} upload results for problems. Overall success: $overallUploadSuccess');
      return overallUploadSuccess;
    } catch (e) {
      print('Error during problem upload to server: $e');
      throw Exception('Problem upload failed: $e');
    }
  }
}