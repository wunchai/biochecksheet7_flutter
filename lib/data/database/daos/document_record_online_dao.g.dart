// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_record_online_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentRecordOnlineDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentRecordOnlinesTable get documentRecordOnlines =>
      attachedDatabase.documentRecordOnlines;
  DocumentRecordOnlineDaoManager get managers =>
      DocumentRecordOnlineDaoManager(this);
}

class DocumentRecordOnlineDaoManager {
  final _$DocumentRecordOnlineDaoMixin _db;
  DocumentRecordOnlineDaoManager(this._db);
  $$DocumentRecordOnlinesTableTableManager get documentRecordOnlines =>
      $$DocumentRecordOnlinesTableTableManager(
          _db.attachedDatabase, _db.documentRecordOnlines);
}
