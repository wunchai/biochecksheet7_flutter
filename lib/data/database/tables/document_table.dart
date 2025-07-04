// lib/data/database/tables/document_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "document")
@DataClassName('DbDocument')
class Documents extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "documentId") var documentId: String? = null
  TextColumn get documentId => text().named('documentId').nullable()();

  // @ColumnInfo(name = "jobId") var jobId: String? = null
  TextColumn get jobId => text().named('jobId').nullable()();

  // @ColumnInfo(name = "documentName") var documentName: String? = null
  TextColumn get documentName => text().named('documentName').nullable()();

  // @ColumnInfo(name = "userId") var userId: String? = null
  TextColumn get userId => text().named('userId').nullable()();

  // @ColumnInfo(name = "createDate") var createDate: String? = null
  TextColumn get createDate => text().named('createDate').nullable()(); // Stored as String (ISO 8601)

  // @ColumnInfo(name = "status") var status: Int = 0
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()(); // Stored as String (ISO 8601)

  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}