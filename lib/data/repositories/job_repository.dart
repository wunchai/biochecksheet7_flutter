// lib/data/repositories/job_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart'; // For JobDao
//import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart'; // For DbJob

// TODO: Import JobApiService for sync in future phase
// import 'package:biochecksheet7_flutter/data/network/job_api_service.dart';

/// Repository for managing Job data.
/// This class abstracts data operations for jobs from UI/ViewModels.
class JobRepository {
  final JobDao _jobDao;
  // TODO: Add JobApiService if needed for sync
  // final JobApiService _jobApiService;

  JobRepository({required AppDatabase appDatabase})
      : _jobDao = appDatabase.jobDao;
  // _jobApiService = jobApiService ?? JobApiService();

  /// Watches a stream of all job records from the local database.
  Stream<List<DbJob>> watchAllJobs() {
    return _jobDao.watchAllJobs();
  }

  /// Gets a single job by its jobId.
  Future<DbJob?> getJobById(String jobId) {
    return _jobDao.getJobById(jobId);
  }

  // TODO: Add other methods as needed (e.g., insertJob, updateJob, deleteJob)
  // TODO: Add sync methods with JobApiService in future phase
}
