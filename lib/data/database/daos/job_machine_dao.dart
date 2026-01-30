// lib/data/database/daos/job_machine_dao.dart
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import your main database
import 'package:biochecksheet7_flutter/data/database/tables/job_machine_table.dart'; // Import your table

part 'job_machine_dao.g.dart';

@DriftAccessor(tables: [JobMachines])
class JobMachineDao extends DatabaseAccessor<AppDatabase>
    with _$JobMachineDaoMixin {
  JobMachineDao(AppDatabase db) : super(db);

  // Equivalent to suspend fun insertJobMachine(jobMachine: DbJobMachine) in DaoJobMachine.kt
  Future<int> insertJobMachine(JobMachinesCompanion entry) =>
      into(jobMachines).insert(entry);

  // Equivalent to suspend fun insertAll(jobMachines: List<DbJobMachine>)
  Future<void> insertAllJobMachines(List<JobMachinesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(jobMachines, entries);
    });
  }

  // Equivalent to suspend fun getJobMachine(jobId: String, machineId: String): DbJobMachine?
  Future<DbJobMachine?> getJobMachine(String jobId, String machineId) {
    return (select(jobMachines)
          ..where((tbl) =>
              tbl.jobId.equals(jobId) & tbl.machineId.equals(machineId)))
        .getSingleOrNull();
  }

  // NEW: Get all JobMachines for a specific JobId (Master Data)
  Future<List<DbJobMachine>> getJobMachinesByJobId(String jobId) {
    return (select(jobMachines)..where((tbl) => tbl.jobId.equals(jobId))).get();
  }

  // Equivalent to suspend fun getAllJobMachine(): List<DbJobMachine>
  Stream<List<DbJobMachine>> watchAllJobMachines() =>
      select(jobMachines).watch();
  Future<List<DbJobMachine>> getAllJobMachines() => select(jobMachines).get();

  // Equivalent to suspend fun updateJobMachine(jobMachine: DbJobMachine)
  Future<bool> updateJobMachine(DbJobMachine entry) =>
      update(jobMachines).replace(entry);

  // Equivalent to suspend fun deleteJobMachine(jobMachine: DbJobMachine)
  Future<int> deleteJobMachine(DbJobMachine entry) =>
      delete(jobMachines).delete(entry);

  // Equivalent to suspend fun deleteAll()
  Future<int> deleteAllJobMachines() => delete(jobMachines).go();
}
