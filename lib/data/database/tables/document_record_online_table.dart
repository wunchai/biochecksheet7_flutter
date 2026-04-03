// lib/data/database/tables/document_record_online_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDocumentRecordOnline')
class DocumentRecordOnlines extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // Mapped from API
  TextColumn get documentId => text().named('documentId').nullable()();
  TextColumn get documentCreateDate => text().named('documentCreateDate').nullable()();
  TextColumn get documentCreateUser => text().named('documentCreateUser').nullable()();
  TextColumn get machineId => text().named('machineId').nullable()();
  TextColumn get jobId => text().named('jobId').nullable()();
  TextColumn get tagId => text().named('tagId').nullable()();
  TextColumn get tagName => text().named('tagName').nullable()();
  TextColumn get tagGroupId => text().named('tagGroupId').nullable()();
  TextColumn get tagGroupName => text().named('tagGroupName').nullable()();
  TextColumn get tagType => text().named('tagType').nullable()();
  TextColumn get tagSelectionValue => text().named('tagSelectionValue').nullable()();
  TextColumn get description => text().named('description').nullable()();
  TextColumn get specification => text().named('specification').nullable()();
  TextColumn get specMin => text().named('specMin').nullable()();
  TextColumn get specMax => text().named('specMax').nullable()();
  TextColumn get unit => text().named('unit').nullable()();
  TextColumn get valueType => text().named('valueType').nullable()();
  TextColumn get value => text().named('value').nullable()();
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();
  TextColumn get unReadable => text().named('unReadable').withDefault(const Constant('false'))();
  TextColumn get remark => text().named('remark').nullable()();
  TextColumn get syncDate => text().named('syncDate').nullable()();
  
  // Custom API additions
  IntColumn get uiType => integer().named('uiType').nullable()(); // Added in API

  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}
