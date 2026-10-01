// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_online_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentOnlineDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentOnlinesTable get documentOnlines => attachedDatabase.documentOnlines;
  DocumentOnlineDaoManager get managers => DocumentOnlineDaoManager(this);
}

class DocumentOnlineDaoManager {
  final _$DocumentOnlineDaoMixin _db;
  DocumentOnlineDaoManager(this._db);
  $$DocumentOnlinesTableTableManager get documentOnlines =>
      $$DocumentOnlinesTableTableManager(
          _db.attachedDatabase, _db.documentOnlines);
}
