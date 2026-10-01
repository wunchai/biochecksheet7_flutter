// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_online_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentImageOnlineDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentImageOnlinesTable get documentImageOnlines =>
      attachedDatabase.documentImageOnlines;
  DocumentImageOnlineDaoManager get managers =>
      DocumentImageOnlineDaoManager(this);
}

class DocumentImageOnlineDaoManager {
  final _$DocumentImageOnlineDaoMixin _db;
  DocumentImageOnlineDaoManager(this._db);
  $$DocumentImageOnlinesTableTableManager get documentImageOnlines =>
      $$DocumentImageOnlinesTableTableManager(
          _db.attachedDatabase, _db.documentImageOnlines);
}
