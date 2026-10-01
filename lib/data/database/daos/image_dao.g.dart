// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_dao.dart';

// ignore_for_file: type=lint
mixin _$ImageDaoMixin on DatabaseAccessor<AppDatabase> {
  $ImagesTable get images => attachedDatabase.images;
  ImageDaoManager get managers => ImageDaoManager(this);
}

class ImageDaoManager {
  final _$ImageDaoMixin _db;
  ImageDaoManager(this._db);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db.attachedDatabase, _db.images);
}
