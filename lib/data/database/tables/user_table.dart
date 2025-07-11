// lib/data/database/tables/user_table.dart
import 'package:drift/drift.dart';

// @Entity(tableName = "user")
@DataClassName('DbUser')
class Users extends Table {
  // @PrimaryKey(autoGenerate = true) var uid = 0
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // @ColumnInfo(name = "userId") var userId: String? = null
  TextColumn get userId => text().named('userId').nullable()();

  // @ColumnInfo(name = "userCode") var userCode: String? = null
  TextColumn get userCode => text().named('userCode').nullable()();

  // @ColumnInfo(name = "password") var password: String? = null
  TextColumn get password => text().named('password').nullable()();

  // @ColumnInfo(name = "userName") var userName: String? = null
  TextColumn get userName => text().named('userName').nullable()();

  // @ColumnInfo(name = "position") var position: String? = null
  TextColumn get position => text().named('position').nullable()();

  // @ColumnInfo(name = "Status") var status: Int = 0
  IntColumn get status =>
      integer().named('Status').withDefault(const Constant(0))();

  // @ColumnInfo(name = "lastSync") var lastSync: String? = null
  TextColumn get lastSync => text().named('lastSync').nullable()();
  TextColumn get updatedAt =>
      text().named('updatedAt').nullable()(); // Stores ISO 8601 string

  // NEW: Add isLocalSessionActive column
  BoolColumn get isLocalSessionActive => boolean()
      .named('isLocalSessionActive')
      .withDefault(const Constant(false))(); // Default to false
}
