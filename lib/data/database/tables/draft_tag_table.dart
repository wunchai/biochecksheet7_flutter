// lib/data/database/tables/draft_tag_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDraftTag')
class DraftTags extends Table {
  TextColumn get uid => text().named('uid')();
  @override
  Set<Column> get primaryKey => {uid};
  
  // Link back to DraftMachine and Job
  TextColumn get draftJobId => text().named('draftJobId')();
  TextColumn get draftMachineId => text().named('draftMachineId')();
  
  // Custom generated ID per machine (e.g., TagGroupId running number)
  TextColumn get tagGroupId => text().named('tagGroupId').nullable()();
  
  // Order ID
  IntColumn get orderId => integer().named('orderId').withDefault(const Constant(0))();
  
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
  
  // Link documentId for easy syncing
  TextColumn get documentId => text().named('documentId').nullable()();
  
  // Specific MT System Code for this Tag (in case it belongs to a different machine)
  TextColumn get machineCode => text().named('machineCode').nullable()();
  
  // Status (1 = Active, 4 = Deleted)
  IntColumn get status => integer().named('status').withDefault(const Constant(1))();
  
  // Record Version (for sync updates)
  IntColumn get recordVersion => integer().named('recordVersion').withDefault(const Constant(1))();
}
