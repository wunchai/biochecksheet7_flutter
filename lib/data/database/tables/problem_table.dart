// lib/data/database/tables/problem_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "problem")
@DataClassName('DbProblem')
class Problems extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "ProblemId") var problemId: String? = null
  TextColumn get problemId => text().named('ProblemId').nullable()();

  // @ColumnInfo(name = "ProblemName") var problemName: String? = null
  TextColumn get problemName => text().named('ProblemName').nullable()();

  // @ColumnInfo(name = "Description") var description: String? = null
  TextColumn get problemDescription => text().named('ProblemDescription').nullable()();

  // @ColumnInfo(name = "ProblemStatus") var problemStatus: Int = 0
  IntColumn get problemStatus => integer().named('ProblemStatus').withDefault(const Constant(0))();

  // @ColumnInfo(name = "SolvingDescription") var description: String? = null
  TextColumn get problemSolvingDescription => text().named('SolvingDescription').nullable()();

 // NEW: Add documentId column
  TextColumn get documentId => text().named('documentId').nullable()(); // <<< NEW: documentId

 // @ColumnInfo(name = "machineId") var machineId: String? = null
  TextColumn get machineId => text().named('machineId').nullable()();
  
  // @ColumnInfo(name = "machineName") var machineName: String? = null
  TextColumn get machineName => text().named('machineName').nullable()();

  // @ColumnInfo(name = "jobId") var jobId: String? = null
  TextColumn get jobId => text().named('jobId').nullable()();
 

  // @ColumnInfo(name = "tagId") var tagId: String? = null
  TextColumn get tagId => text().named('tagId').nullable()();

  // @ColumnInfo(name = "tagName") var tagName: String? = null
  TextColumn get tagName => text().named('tagName').nullable()();

  // @ColumnInfo(name = "tagType") var tagType: String? = null
  TextColumn get tagType => text().named('tagType').nullable()();

  // @ColumnInfo(name = "description") var description: String? = null
  TextColumn get description => text().named('TagDescription').nullable()();

  // @ColumnInfo(name = "Note") var note: String? = null
  TextColumn get note => text().named('Note').nullable()();

  // @ColumnInfo(name = "specification") var specification : String? = null
  TextColumn get specification => text().named('specification').nullable()();

  // @ColumnInfo(name = "specMin") var specMin : String? = null
  TextColumn get specMin => text().named('specMin').nullable()();

  // @ColumnInfo(name = "specMax") var specMax : String? = null
  TextColumn get specMax => text().named('specMax').nullable()();

  // @ColumnInfo(name = "unit") var unit: String? = null
  TextColumn get unit => text().named('unit').nullable()();

  // @ColumnInfo(name = "value") var value: String? = null
  TextColumn get value => text().named('value').nullable()();

  // @ColumnInfo(name = "remark") var remark: String? = null
  TextColumn get remark => text().named('remark').nullable()();
  
  TextColumn get unReadable => text().named('unReadable').withDefault(const Constant('false'))();

  TextColumn get lastSync => text().named('lastSync').nullable()();

  TextColumn get problemSolvingBy => text().named('SolvingBy').nullable()(); 

  IntColumn get syncStatus => integer().named('syncStatus').withDefault(const Constant(0))(); // Default to 0
  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}