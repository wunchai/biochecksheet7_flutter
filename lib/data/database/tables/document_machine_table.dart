// lib/data/database/tables/document_machine_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "documentMachine")
@DataClassName('DbDocumentMachine')
class DocumentMachines extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "JobId") var jobId: String? = null
  TextColumn get jobId => text().named('JobId').nullable()();

  // @ColumnInfo(name = "documentId") var documentId: String? = null
  TextColumn get documentId => text().named('documentId').nullable()();

  // @ColumnInfo(name = "MachineId") var machineId: String? = null
  TextColumn get machineId =>
      text().named('MachineId').nullable()(); // NEW: Will map int to String

  // @ColumnInfo(name = "MachineName") var machineName: String? = null
  TextColumn get machineName => text().named('MachineName').nullable()();

  // @ColumnInfo(name = "MachineType") var machineType: String? = null
  TextColumn get machineType => text().named('MachineType').nullable()();

  // @ColumnInfo(name = "Description") var description: String? = null
  TextColumn get description => text().named('Description').nullable()();

  // @ColumnInfo(name = "Specification") var specification : String? = null
  TextColumn get specification => text().named('Specification').nullable()();

  // @ColumnInfo(name = "Status") var status: Int = 0
  IntColumn get status =>
      integer().named('Status').withDefault(const Constant(0))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()();

  IntColumn get uiType =>
      integer().named('ui_type').withDefault(const Constant(0))();

  // NEW: Add fields from API response
  IntColumn get id => integer().named('id')(); // API has 'id' as int
  TextColumn get createDate => text().named('CreateDate').nullable()();
  TextColumn get createBy => text().named('CreateBy').nullable()();
  TextColumn get updatedAt =>
      text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}
