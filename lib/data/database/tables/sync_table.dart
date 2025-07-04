// lib/data/database/tables/sync_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "sync")
@DataClassName('DbSync')
class Syncs extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "SyncId") var syncId: String? = null
  TextColumn get syncId => text().named('SyncId').nullable()();

  // @ColumnInfo(name = "SyncName") var syncName: String? = null
  TextColumn get syncName => text().named('SyncName').nullable()();

  // @ColumnInfo(name = "LastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('LastSync').nullable()(); // Stored as String (ISO 8601)

  // @ColumnInfo(name = "SyncStatus") var syncStatus: Int = 0
  IntColumn get syncStatus => integer().named('SyncStatus').withDefault(const Constant(0))();

  // @ColumnInfo(name = "NextSync") var nextSync: String? = null
  TextColumn get nextSync => text().named('NextSync').nullable()(); // Stored as String (ISO 8601)
  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}