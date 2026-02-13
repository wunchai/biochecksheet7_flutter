// สร้างไฟล์ใหม่ที่: lib/data/database/daos/checksheet_master_image_dao.dart
import 'package:drift/drift.dart';

import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/checksheet_master_image_table.dart';

part 'checksheet_master_image_dao.g.dart';

@DriftAccessor(tables: [CheckSheetMasterImages])
class ChecksheetMasterImageDao extends DatabaseAccessor<AppDatabase>
    with _$ChecksheetMasterImageDaoMixin {
  ChecksheetMasterImageDao(AppDatabase db) : super(db);

  /// เพิ่มหรืออัปเดตข้อมูลรูปภาพทั้งหมด (ใช้ตอน Sync)
  Future<void> insertOrUpdateAll(
      List<CheckSheetMasterImagesCompanion> entries) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(checkSheetMasterImages, entries);
    });
  }

  Future<List<DbCheckSheetMasterImage>> getAllImages() {
    return select(checkSheetMasterImages).get();
  }

  /// ดึงข้อมูลรูปภาพสำหรับ Tag ที่ระบุ
  Future<DbCheckSheetMasterImage?> getImageForTag({
    required int jobId,
    required int machineId,
    required int tagId,
  }) async {
    return (select(checkSheetMasterImages)
          ..where((tbl) => tbl.jobId.equals(jobId))
          ..where((tbl) => tbl.machineId.equals(machineId))
          ..where((tbl) => tbl.tagId.equals(tagId)))
        .getSingleOrNull();
  }

  /// ค้นหารายการรูปภาพทั้งหมดที่ยังไม่ได้ดาวน์โหลด (path is null)
  Future<List<DbCheckSheetMasterImage>> getImagesToDownload() {
    return (select(checkSheetMasterImages)..where((tbl) => tbl.path.isNull()))
        .get();
  }

  /// อัปเดตที่อยู่ไฟล์ (path) ในเครื่องหลังจากดาวน์โหลดสำเร็จ
  Future<void> updateImagePath(int imageId, String localPath) {
    return (update(checkSheetMasterImages)
          ..where((tbl) => tbl.id.equals(imageId)))
        .write(CheckSheetMasterImagesCompanion(
      path: Value(localPath),
      lastSync: Value(DateTime.now()),
    ));
  }

  /// === ฟังก์ชันที่เพิ่มเข้ามาเพื่อแก้ Error ===
  /// ค้นหาทุก record ที่ยังไม่มี Path (ยังไม่ได้ดาวน์โหลด)
  Future<List<DbCheckSheetMasterImage>> getRecordsWithNullPath() {
    return (select(checkSheetMasterImages)..where((tbl) => tbl.path.isNull()))
        .get();
  }

  /// ล้างข้อมูลทั้งหมดในตาราง
  Future<void> clearAll() => delete(checkSheetMasterImages).go();

  /// === ฟังก์ชันใหม่: จัดการการบันทึกรูปที่ถ่ายในแอป (ทั้ง Insert และ Update) ===
  /// ตรวจสอบว่ามีข้อมูลสำหรับ tag นี้อยู่แล้วหรือไม่
  /// - ถ้ามี: อัปเดต path และตั้งค่า newImage = 1
  /// - ถ้าไม่มี: สร้าง record ใหม่ทั้งหมด
  Future<void> saveNewLocalImage({
    required int jobId,
    required int machineId,
    required int tagId,
    required String localPath,
    required String createBy,
  }) async {
    // 1. เตรียมข้อมูลที่จะบันทึก (Companion)
    final companion = CheckSheetMasterImagesCompanion(
      jobId: Value(jobId),
      machineId: Value(machineId),
      tagId: Value(tagId),
      path: Value(localPath), // Path ใหม่จากรูปที่ถ่าย
      createDate: Value(DateTime.now()), // วันที่ปัจจุบัน
      createBy: Value(createBy),
      newImage: const Value(1), // ตั้งสถานะเป็นรูปใหม่
      syncStatus: const Value(0), // สถานะยังไม่ Sync
      status: const Value(1), // สถานะ Active
    );

    // 2. บันทึกข้อมูลใหม่ (Insert Always) เพื่อรองรับหลายรูปภาพต่อ 1 Tag
    await into(checkSheetMasterImages).insert(companion);
  }

  /// ค้นหารูปภาพใหม่ทั้งหมดที่ต้องอัปโหลด (newImage = 1)
  Future<List<DbCheckSheetMasterImage>> getImagesToUpload() {
    return (select(checkSheetMasterImages)
          ..where((tbl) => tbl.newImage.equals(1)))
        .get();
  }

  // --- <<< จุดที่แก้ไขสำคัญ >>> ---
  /// เปลี่ยนชื่อฟังก์ชันเป็น watch... และเปลี่ยน Furture เป็น Stream
  /// โดยเปลี่ยน .getSingleOrNull() เป็น .watchSingleOrNull()
  Stream<List<DbCheckSheetMasterImage>> watchImagesForTag({
    required int jobId,
    required int machineId,
    required int tagId,
  }) {
    return (select(checkSheetMasterImages)
          ..where((tbl) =>
              tbl.jobId.equals(jobId) &
              tbl.machineId.equals(machineId) &
              tbl.tagId.equals(tagId)))
        .watch();
  }

  Stream<DbCheckSheetMasterImage?> watchImageForTag({
    required int jobId,
    required int machineId,
    required int tagId,
  }) {
    return (select(checkSheetMasterImages)
          ..where((tbl) =>
              tbl.jobId.equals(jobId) &
              tbl.machineId.equals(machineId) &
              tbl.tagId.equals(tagId)))
        .watchSingleOrNull();
  }

  // --- <<< ฟังก์ชันใหม่ที่เพิ่มเข้ามา >>> ---
  /// อัปเดตสถานะของรูปภาพหลังจากอัปโหลดสำเร็จ
  Future<void> updateStatusAfterUpload(int id) {
    return (update(checkSheetMasterImages)..where((tbl) => tbl.id.equals(id)))
        .write(const CheckSheetMasterImagesCompanion(
      newImage: Value(0), // ตั้งค่า newImage กลับเป็น 0
      syncStatus: Value(1), // ตั้งค่า syncStatus เป็น 1 (ซิงค์แล้ว)
    ));
  }

  /// ลบ record รูปภาพตาม ID (ใช้สำหรับกรณี Upload สำเร็จแล้วต้องการเคลียร์ทิ้ง)
  Future<int> deleteImage(int id) {
    return (delete(checkSheetMasterImages)..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
