// lib/data/database/tables/job_tag_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "jobTag")
@DataClassName('DbJobTag')
class JobTags extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "tagId") var tagId: String? = null
  TextColumn get tagId => text().named('TagId').nullable()(); // NEW: Will map int to String

  // @ColumnInfo(name = "jobId") var jobId: String? = null
  TextColumn get jobId => text().named('JobId').nullable()(); // NEW: Will map int to String

  TextColumn get machineId => text().named('MachineId').nullable()(); // NEW: Add this field and map int to String

  // @ColumnInfo(name = "tagName") var tagName: String? = null
  TextColumn get tagName => text().named('tagName').nullable()();

  // @ColumnInfo(name = "tagType") var tagType: String? = null
  TextColumn get tagType => text().named('tagType').nullable()();

  // @ColumnInfo(name = "tagGroupId") var tagGroupId: String? = null
  TextColumn get tagGroupId => text().named('TagGroupId').nullable()(); // NEW: Will map int to String

  // @ColumnInfo(name = "TagGroupName") var tagGroupName: String? = null
  TextColumn get tagGroupName => text().named('TagGroupName').nullable()();

  // @ColumnInfo(name = "description") var description: String? = null
  TextColumn get description => text().named('description').nullable()();

  // @ColumnInfo(name = "specification") var specification : String? = null
  TextColumn get specification => text().named('specification').nullable()();

  // @ColumnInfo(name = "specMin") var specMin : String? = null
  TextColumn get specMin => text().named('SpecMin').nullable()(); // NEW: Will map double to String

  // @ColumnInfo(name = "specMax") var specMax : String? = null
  TextColumn get specMax => text().named('SpecMax').nullable()(); // NEW: Will map double to String

  // @ColumnInfo(name = "unit") var unit: String? = null
  TextColumn get unit => text().named('unit').nullable()();

  // @ColumnInfo(name = "queryStr") var queryStr: String? = null
  TextColumn get queryStr => text().named('queryStr').nullable()();

  // @ColumnInfo(name = "status") var status: Int = 0
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()();

  // NEW: Add driftQueryStr for raw SQL queries with snake_case table/column names
  TextColumn get driftQueryStr => text().named('driftQueryStr').nullable()();
   // NEW: Add fields from API response
  TextColumn get note => text().named('Note').nullable()();
  TextColumn get value => text().named('Value').nullable()(); // API has 'Value' as null
  TextColumn get remark => text().named('Remark').nullable()();
  TextColumn get createDate => text().named('CreateDate').nullable()();
  TextColumn get createBy => text().named('CreateBy').nullable()();
  TextColumn get valueType => text().named('ValueType').nullable()(); // API has 'ValueType'
  TextColumn get tagSelectionValue => text().named('TagSelectionValue').nullable()(); // API has 'TagSelectionValue'

  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}