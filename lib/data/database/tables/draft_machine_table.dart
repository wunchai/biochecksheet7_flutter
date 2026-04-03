// lib/data/database/tables/draft_machine_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDraftMachine')
class DraftMachines extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();
  
  // Link back to DraftJobs
  IntColumn get draftJobId => integer().named('draftJobId')();
  
  // Custom Running ID generated app-side
  TextColumn get machineId => text().named('machineId').nullable()();
  
  // User entered free-text
  TextColumn get machineName => text().named('machineName').nullable()();
  TextColumn get machineType => text().named('machineType').nullable()();
}
