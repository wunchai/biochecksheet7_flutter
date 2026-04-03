// lib/data/database/tables/draft_tag_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDraftTag')
class DraftTags extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();
  
  // Link back to DraftMachine and Job
  IntColumn get draftJobId => integer().named('draftJobId')();
  IntColumn get draftMachineId => integer().named('draftMachineId')();
  
  // Custom generated ID per machine (e.g., TagGroupId running number)
  TextColumn get tagGroupId => text().named('tagGroupId').nullable()();
  
  // User entered Group Name
  TextColumn get tagGroupName => text().named('tagGroupName').nullable()();
  
  // Tag fields
  TextColumn get tagName => text().named('tagName').nullable()();
  TextColumn get tagType => text().named('tagType').nullable()();
  TextColumn get tagSelectionValue => text().named('tagSelectionValue').nullable()();
  TextColumn get specMin => text().named('specMin').nullable()();
  TextColumn get specMax => text().named('specMax').nullable()();
  TextColumn get unit => text().named('unit').nullable()();
  TextColumn get description => text().named('description').nullable()();
}
