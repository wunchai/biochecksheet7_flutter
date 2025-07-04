// lib/data/database/tables/job_machine_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "jobMachine")
@DataClassName('DbJobMachine')
class JobMachines extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "JobId") var jobId: String? = null
  TextColumn get jobId => text().named('JobId').nullable()();

  // @ColumnInfo(name = "MachineId") var machineId: String? = null
  TextColumn get machineId => text().named('MachineId').nullable()();

  // @ColumnInfo(name = "MachineName") var machineName: String? = null
  TextColumn get machineName => text().named('MachineName').nullable()();

  // @ColumnInfo(name = "MachineType") var machineType: String? = null
  TextColumn get machineType => text().named('MachineType').nullable()();

  // @ColumnInfo(name = "Description") var description: String? = null
  TextColumn get description => text().named('Description').nullable()();

  // @ColumnInfo(name = "Specification") var specification : String? = null
  TextColumn get specification => text().named('Specification').nullable()();

  // @ColumnInfo(name = "Status") var status: Int = 0
  IntColumn get status => integer().named('Status').withDefault(const Constant(0))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()();
  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}