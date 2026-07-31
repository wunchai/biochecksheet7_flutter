import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

class DemoSeeder {
  final AppDatabase _db;

  DemoSeeder(this._db);

  Future<void> seedDemoData() async {
    // 1. Seed Demo User
    await _seedUser();

    // 2. Seed Jobs
    await _seedJobs();

    // 3. Seed Documents
    await _seedDocuments();

    // 4. Seed Job Machines
    await _seedJobMachines();

    // 5. Seed Job Tags
    await _seedJobTags();

    // 6. Seed Document Machines
    await _seedDocumentMachines();
  }

  Future<void> _seedUser() async {
    final existingUser = await (_db.select(_db.users)
          ..where((t) => t.userId.equals('demo')))
        .getSingleOrNull();

    if (existingUser == null) {
      await _db.into(_db.users).insert(
            UsersCompanion(
              userId: const Value('demo'),
              userCode: const Value('D001'),
              password: const Value('demo1234'),
              userName: const Value('Demo User'),
              position: const Value('Inspector'),
              status: const Value(1),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }

    final existingAppleReviewer = await (_db.select(_db.users)
          ..where((t) => t.userId.equals('000000')))
        .getSingleOrNull();

    if (existingAppleReviewer == null) {
      await _db.into(_db.users).insert(
            UsersCompanion(
              userId: const Value('000000'),
              userCode: const Value('000000'),
              password: const Value('demo00'),
              userName: const Value('Apple Reviewer'),
              position: const Value('Reviewer'),
              status: const Value(1),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }
  }

  Future<void> _seedJobs() async {
    final existingJob = await (_db.select(_db.jobs)
          ..where((t) => t.jobId.equals('JOB-DEMO-001')))
        .getSingleOrNull();

    if (existingJob == null) {
      await _db.into(_db.jobs).insert(
            JobsCompanion(
              jobId: const Value('JOB-DEMO-001'),
              jobName: const Value('Daily Inspection - Area A'),
              machineName: const Value('Conveyor Belt 1'),
              documentId: const Value('DOC-DEMO-001'),
              location: const Value('Factory Floor 1'),
              jobStatus: const Value(0), // Pending
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );

      await _db.into(_db.jobs).insert(
            JobsCompanion(
              jobId: const Value('JOB-DEMO-002'),
              jobName: const Value('Weekly Maintenance'),
              machineName: const Value('Hydraulic Press'),
              documentId: const Value('DOC-DEMO-002'),
              location: const Value('Factory Floor 2'),
              jobStatus: const Value(1), // In Progress
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }
  }

  Future<void> _seedDocuments() async {
    final existingDoc = await (_db.select(_db.documents)
          ..where((t) => t.documentId.equals('DOC-DEMO-001')))
        .getSingleOrNull();

    if (existingDoc == null) {
      await _db.into(_db.documents).insert(
            DocumentsCompanion(
              documentId: const Value('DOC-DEMO-001'),
              jobId: const Value('JOB-DEMO-001'),
              documentName: const Value('Conveyor Inspection Sheet'),
              userId: const Value('demo'),
              createDate: Value(DateTime.now().toIso8601String()),
              status: const Value(0),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );

      await _db.into(_db.documents).insert(
            DocumentsCompanion(
              documentId: const Value('DOC-DEMO-002'),
              jobId: const Value('JOB-DEMO-002'),
              documentName: const Value('Press Maintenance Log'),
              userId: const Value('demo'),
              createDate: Value(DateTime.now().toIso8601String()),
              status: const Value(1),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }
  }

  Future<void> _seedJobMachines() async {
    final existingMachine = await (_db.select(_db.jobMachines)
          ..where((t) => t.jobId.equals('JOB-DEMO-001')))
        .getSingleOrNull();

    if (existingMachine == null) {
      await _db.into(_db.jobMachines).insert(
            JobMachinesCompanion(
              id: const Value(9991),
              jobId: const Value('JOB-DEMO-001'),
              machineId: const Value('MACH-DEMO-001'),
              machineName: const Value('Conveyor Belt 1'),
              machineType: const Value('Conveyor'),
              status: const Value(1),
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
      await _db.into(_db.jobMachines).insert(
            JobMachinesCompanion(
              id: const Value(9992),
              jobId: const Value('JOB-DEMO-002'),
              machineId: const Value('MACH-DEMO-002'),
              machineName: const Value('Hydraulic Press'),
              machineType: const Value('Press'),
              status: const Value(1),
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }
  }

  Future<void> _seedJobTags() async {
    final existingTag = await (_db.select(_db.jobTags)
          ..where((t) => t.jobId.equals('JOB-DEMO-001')))
        .getSingleOrNull();

    if (existingTag == null) {
      // Tags for JOB 1
      await _db.into(_db.jobTags).insert(
            JobTagsCompanion(
              jobId: const Value('JOB-DEMO-001'),
              machineId: const Value('MACH-DEMO-001'),
              tagId: const Value('TAG-DEMO-001'),
              tagName: const Value('Temperature Check'),
              tagType: const Value('INPUT'),
              tagGroupId: const Value('GROUP-1'),
              tagGroupName: const Value('General Checks'),
              valueType: const Value('NUMBER'),
              unit: const Value('Celsius'),
              status: const Value(1),
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
      // Tags for JOB 2
      await _db.into(_db.jobTags).insert(
            JobTagsCompanion(
              jobId: const Value('JOB-DEMO-002'),
              machineId: const Value('MACH-DEMO-002'),
              tagId: const Value('TAG-DEMO-002'),
              tagName: const Value('Pressure Check'),
              tagType: const Value('INPUT'),
              tagGroupId: const Value('GROUP-2'),
              tagGroupName: const Value('Hydraulic Checks'),
              valueType: const Value('NUMBER'),
              unit: const Value('PSI'),
              status: const Value(1),
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }
  }

  Future<void> _seedDocumentMachines() async {
    final existingDocMachine = await (_db.select(_db.documentMachines)
          ..where((t) => t.documentId.equals('DOC-DEMO-001')))
        .getSingleOrNull();

    if (existingDocMachine == null) {
      await _db.into(_db.documentMachines).insert(
            DocumentMachinesCompanion(
              id: const Value(9991),
              documentId: const Value('DOC-DEMO-001'),
              jobId: const Value('JOB-DEMO-001'),
              machineId: const Value('MACH-DEMO-001'),
              machineName: const Value('Conveyor Belt 1'),
              status: const Value(0),
              uiType: const Value(0),
              totalTags: const Value(1),
              savedTags: const Value(0),
              aggregateStatus: const Value(0),
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );

      await _db.into(_db.documentMachines).insert(
            DocumentMachinesCompanion(
              id: const Value(9992),
              documentId: const Value('DOC-DEMO-002'),
              jobId: const Value('JOB-DEMO-002'),
              machineId: const Value('MACH-DEMO-002'),
              machineName: const Value('Hydraulic Press'),
              status: const Value(0),
              uiType: const Value(0),
              totalTags: const Value(1),
              savedTags: const Value(0),
              aggregateStatus: const Value(0),
              createDate: Value(DateTime.now().toIso8601String()),
              createBy: const Value('System'),
              lastSync: Value(DateTime.now().toIso8601String()),
            ),
          );
    }
  }
}
