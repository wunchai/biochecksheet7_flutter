// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checksheet_master_image_dao.dart';

// ignore_for_file: type=lint
mixin _$ChecksheetMasterImageDaoMixin on DatabaseAccessor<AppDatabase> {
  $CheckSheetMasterImagesTable get checkSheetMasterImages =>
      attachedDatabase.checkSheetMasterImages;
  ChecksheetMasterImageDaoManager get managers =>
      ChecksheetMasterImageDaoManager(this);
}

class ChecksheetMasterImageDaoManager {
  final _$ChecksheetMasterImageDaoMixin _db;
  ChecksheetMasterImageDaoManager(this._db);
  $$CheckSheetMasterImagesTableTableManager get checkSheetMasterImages =>
      $$CheckSheetMasterImagesTableTableManager(
          _db.attachedDatabase, _db.checkSheetMasterImages);
}
