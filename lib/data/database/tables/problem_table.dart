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
  TextColumn get description => text().named('Description').nullable()();

  // @ColumnInfo(name = "ProblemStatus") var problemStatus: Int = 0
  IntColumn get problemStatus => integer().named('ProblemStatus').withDefault(const Constant(0))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()();
}