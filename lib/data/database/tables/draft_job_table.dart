// lib/data/database/tables/draft_job_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDraftJob')
class DraftJobs extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();
  TextColumn get jobName => text().named('jobName')();
  TextColumn get location => text().named('location')();
  
  // Optional Tracking Fields
  TextColumn get machineName => text().named('machineName').nullable()();
  TextColumn get documentId => text().named('documentId').nullable()();
  
  // Status: 0 = Draft (editing), 1 = Ready/Submitted
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();
  
  TextColumn get createDate => text().named('createDate').nullable()();
  TextColumn get updatedAt => text().named('updatedAt').nullable()();
}
