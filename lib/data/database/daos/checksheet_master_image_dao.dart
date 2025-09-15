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
}
