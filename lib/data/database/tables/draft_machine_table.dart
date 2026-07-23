// lib/data/database/tables/draft_machine_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDraftMachine')
class DraftMachines extends Table {
  TextColumn get uid => text().named('uid')();
  @override
  Set<Column> get primaryKey => {uid};
  
  // Link back to DraftJobs
  TextColumn get draftJobId => text().named('draftJobId')();
  
  // Custom Running ID generated app-side
  TextColumn get machineId => text().named('machineId').nullable()();
  
  TextColumn get machineName => text().named('machineName').nullable()();
  TextColumn get machineType => text().named('machineType').nullable()();
  
  // Link documentId for easy syncing
  TextColumn get documentId => text().named('documentId').nullable()();
  
  // MT System Code
  TextColumn get machineCode => text().named('machineCode').nullable()();
  
  // Status (1 = Active, 4 = Deleted)
  IntColumn get status => integer().named('status').withDefault(const Constant(1))();
  
  // Record Version (for sync updates)
  IntColumn get recordVersion => integer().named('recordVersion').withDefault(const Constant(1))();
}
