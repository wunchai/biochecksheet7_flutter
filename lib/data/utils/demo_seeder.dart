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

    // 4. Seed Document Machines (optional but good for realism)
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
              // isLocalSessionActive will be handled by logic repository login flow
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

  Future<void> _seedDocumentMachines() async {
    // Basic machine info if needed
    // Assuming machineId links to job or document, though checked schema implies table DocumentMachines
    // Let's leave this simple API for now.
  }
}
