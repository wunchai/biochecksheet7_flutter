// lib/data/database/tables/document_record_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "documentRecord")
@DataClassName('DbDocumentRecord')
class DocumentRecords extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "documentId") var documentId: String? = null
  TextColumn get documentId => text().named('documentId').nullable()();

  // @ColumnInfo(name = "machineId") var machineId: String? = null
  TextColumn get machineId => text().named('machineId').nullable()();

  // @ColumnInfo(name = "jobId") var jobId: String? = null
  TextColumn get jobId => text().named('jobId').nullable()();

  // @ColumnInfo(name = "tagId") var tagId: String? = null
  TextColumn get tagId => text().named('tagId').nullable()();

  // @ColumnInfo(name = "tagName") var tagName: String? = null
  TextColumn get tagName => text().named('tagName').nullable()();

  // @ColumnInfo(name = "tagType") var tagType: String? = null
  TextColumn get tagType => text().named('tagType').nullable()();

  // @ColumnInfo(name = "TagGroupId") var tagGroupId: String? = null
  TextColumn get tagGroupId => text().named('TagGroupId').nullable()();

  // @ColumnInfo(name = "TagGroupName") var tagGroupName: String? = null
  TextColumn get tagGroupName => text().named('TagGroupName').nullable()();

  // @ColumnInfo(name = "tagSelectionValue") var tagSelectionValue: String? = null
  TextColumn get tagSelectionValue => text().named('tagSelectionValue').nullable()();

  // @ColumnInfo(name = "description") var description: String? = null
  TextColumn get description => text().named('description').nullable()();

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

  // @ColumnInfo(name = "queryStr") var queryStr: String? = null
  TextColumn get queryStr => text().named('queryStr').nullable()();

  // @ColumnInfo(name = "value") var value: String? = null
  TextColumn get value => text().named('value').nullable()();

  // @ColumnInfo(name = "valueType") var valueType: String? = null
  TextColumn get valueType => text().named('valueType').nullable()();

  // @ColumnInfo(name = "remark") var remark: String? = null
  TextColumn get remark => text().named('remark').nullable()();

  // @ColumnInfo(name = "status") var status: Int = 0
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();

  // @ColumnInfo(name = "unReadable") var unReadable: String = "false"
  // In Kotlin, it's a String "false". In Dart, we can map it to a BoolColumn.
  // If you strictly need "true"/"false" strings in DB, use TextColumn.
  // For now, let's keep it as TextColumn to match the exact string storage.
  TextColumn get unReadable => text().named('unReadable').withDefault(const Constant('false'))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()();

  TextColumn get createBy => text().named('CreateBy').nullable()(); 

  IntColumn get syncStatus => integer().named('syncStatus').withDefault(const Constant(0))(); // Default to 0

   TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}