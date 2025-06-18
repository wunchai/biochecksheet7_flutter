// lib/data/database/daos/job_tag_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // Import your table

part 'job_tag_dao.g.dart';

@DriftAccessor(tables: [JobTags])
class JobTagDao extends DatabaseAccessor<AppDatabase> with _$JobTagDaoMixin {
  JobTagDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertJobTag(jobTag: DbJobTag) in DaoJobTag.kt
  Future<int> insertJobTag(JobTagsCompanion entry) => into(jobTags).insert(entry);

  // Equivalent to suspend fun insertAll(jobTags: List<DbJobTag>)
  Future<void> insertAllJobTags(List<JobTagsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(jobTags, entries);
    });
  }

  // Equivalent to suspend fun getJobTag(tagId: String, jobId: String): DbJobTag?
  Future<DbJobTag?> getJobTag(String tagId, String jobId) {
    return (select(jobTags)
          ..where((tbl) => tbl.tagId.equals(tagId) & tbl.jobId.equals(jobId)))
        .getSingleOrNull();
  }

  // Equivalent to suspend fun getAllJobTag(): List<DbJobTag>
  Stream<List<DbJobTag>> watchAllJobTags() => select(jobTags).watch();
  Future<List<DbJobTag>> getAllJobTags() => select(jobTags).get();

  // Equivalent to suspend fun updateJobTag(jobTag: DbJobTag)
  Future<bool> updateJobTag(DbJobTag entry) => update(jobTags).replace(entry);

  // Equivalent to suspend fun deleteJobTag(jobTag: DbJobTag)
  Future<int> deleteJobTag(DbJobTag entry) => delete(jobTags).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllJobTags() => delete(jobTags).go();
}