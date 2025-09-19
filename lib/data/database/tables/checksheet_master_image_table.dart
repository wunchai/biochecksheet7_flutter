// สร้างไฟล์ใหม่ที่: lib/data/database/tables/checksheet_master_image_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbCheckSheetMasterImage')
class CheckSheetMasterImages extends Table {
  @override
  String get tableName => 'checksheet_master_images';

  // ใช้ IntColumn สำหรับ id ที่มาจาก Server
  IntColumn get id => integer().named('id')();
  IntColumn get machineId => integer().nullable().named('machineId')();
  IntColumn get jobId => integer().nullable().named('jobId')();
  IntColumn get tagId => integer().nullable().named('tagId')();

  // PATH ในแอปจะเก็บที่อยู่ไฟล์ในมือถือ
  TextColumn get path => text().nullable().named('path')();

  IntColumn get status => integer().nullable().named('status')();
  DateTimeColumn get createDate => dateTime().nullable().named('createDate')();
  TextColumn get createBy => text().nullable().named('createBy')();

  // คอลัมน์สำหรับจัดการสถานะการ Sync ในแอป
  DateTimeColumn get lastSync => dateTime().nullable().named('lastSync')();
  IntColumn get syncStatus => integer().nullable().named('syncStatus')();

  TextColumn get updatedAt =>
      text().named('updatedAt').nullable()(); // Stores ISO 8601 string

  IntColumn get newImage =>
      integer().named('newImage').withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}
