// lib/data/database/daos/job_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';

part 'job_dao.g.dart';

@DriftAccessor(tables: [Jobs])
class JobDao extends DatabaseAccessor<AppDatabase> with _$JobDaoMixin {
  JobDao(AppDatabase db) : super(db);

  // Inserts a new job record.
  Future<int> insertJob(JobsCompanion entry) => into(jobs).insert(entry);

  // Updates an existing job record.
  Future<bool> updateJob(DbJob entry) => update(jobs).replace(entry);

  // Deletes a specific job record.
  Future<int> deleteJob(DbJob entry) => delete(jobs).delete(entry);

  /// NEW: Gets the latest lastSync timestamp from the jobs table.
  Future<String?> getLastSync() async {
    final result =
        await customSelect('SELECT MAX(lastSync) FROM jobs').getSingleOrNull();
    return result?.data.values.first?.toString();
  }

  // NEW: Watches a stream of all job records, optionally filtered by a search query.
  Stream<List<DbJob>> watchAllJobs({String? searchQuery}) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = '%${searchQuery.toLowerCase()}%';
      return (select(jobs)
            ..where((tbl) =>
                tbl.jobName.lower().like(query) |
                tbl.jobId.lower().like(query) |
                tbl.machineName.lower().like(query)))
          .watch();
    }
    return select(jobs).watch();
  }

  // NEW: Gets a single job record by its jobId.
  Future<DbJob?> getJobById(String jobId) {
    return (select(jobs)..where((tbl) => tbl.jobId.equals(jobId)))
        .getSingleOrNull();
  }

  // NEW: Deletes all job records.
  Future<int> deleteAllJobs() {
    return delete(jobs).go();
  }

  // NEW: Inserts multiple job records in a single batch.
  Future<void> insertAllJobs(List<JobsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(jobs, entries);
    });
  }
}
