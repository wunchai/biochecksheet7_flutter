// lib/data/database/daos/job_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart'; // Import your table

// This line tells drift to generate a file named job_dao.g.dart
part 'job_dao.g.dart';

// This annotation marks the class as a DAO and specifies the tables it can access.
@DriftAccessor(tables: [Jobs])
class JobDao extends DatabaseAccessor<AppDatabase> with _$JobDaoMixin {
  JobDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertJob(job: DbJob) in DaoJob.kt
  Future<int> insertJob(JobsCompanion entry) => into(jobs).insert(entry);
  // Or if you pass DbJob directly and let drift convert
  // Future<int> insertJob(DbJob job) => into(jobs).insert(job); // This would require DbJob to be Convertible

  // Equivalent to suspend fun insertAll(jobs: List<DbJob>)
  Future<void> insertAllJobs(List<JobsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(jobs, entries);
    });
  }
  // Or for DbJob directly
  // Future<void> insertAllJobs(List<DbJob> jobsList) async {
  //   await batch((batch) {
  //     batch.insertAll(jobs, jobsList);
  //   });
  // }


  // Equivalent to suspend fun getJob(jobId: String): DbJob?
  Future<DbJob?> getJob(String jobId) {
    return (select(jobs)..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
  }

  // Equivalent to suspend fun getAllJobs(): List<DbJob>
  Stream<List<DbJob>> watchAllJobs() => select(jobs).watch();
  Future<List<DbJob>> getAllJobs() => select(jobs).get();


  // Equivalent to suspend fun updateJob(job: DbJob)
  Future<bool> updateJob(DbJob entry) => update(jobs).replace(entry);

  // Equivalent to suspend fun deleteJob(job: DbJob)
  Future<int> deleteJob(DbJob entry) => delete(jobs).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllJobs() => delete(jobs).go();
}