import 'package:drift/drift.dart'; // Using drift for Room equivalent

@DataClassName('DbJob') // To keep the name similar to Kotlin
class Jobs extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();
  TextColumn get jobId => text().named('jobId').nullable()();
  TextColumn get jobName => text().named('JobName').nullable()();
  TextColumn get machineName => text().named('MachineName').nullable()();
  TextColumn get documentId => text().named('DocumentId').nullable()();
  TextColumn get location => text().named('Location').nullable()();
  IntColumn get jobStatus => integer().named('JobStatus').withDefault(const Constant(0))();
  TextColumn get lastSync => text().named('lastSync').nullable()(); // Consider using DateTime in Dart directly
}

// In your database file (e.g., app_database.dart)
// @DriftDatabase(tables: [Jobs, Documents, DocumentMachines, DocumentRecords, JobMachines, JobTags, Problems, Syncs, Users])
// class AppDatabase extends _$AppDatabase { ... }