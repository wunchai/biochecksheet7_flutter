// lib/data/database/tables/draft_job_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDraftJob')
class DraftJobs extends Table {
  TextColumn get uid => text().named('uid')();
  @override
  Set<Column> get primaryKey => {uid};
  TextColumn get jobName => text().named('jobName')();
  TextColumn get location => text().named('location')();
  
  // Optional Tracking Fields
  TextColumn get userId => text().named('userId').nullable()();
  TextColumn get machineName => text().named('machineName').nullable()();
  TextColumn get documentId => text().named('documentId').nullable()();
  
  // Status: 0 = Draft (editing), 1 = Ready/Submitted
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();
  
  // StatusSync: 0 = Not Synced, 1 = Synced
  IntColumn get statusSync => integer().named('statusSync').withDefault(const Constant(0))();
  
  IntColumn get recordVersion => integer().named('recordVersion').withDefault(const Constant(1))();
  
  TextColumn get createDate => text().named('createDate').nullable()();
  TextColumn get updatedAt => text().named('updatedAt').nullable()();
}
