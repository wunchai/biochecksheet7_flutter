// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_record_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentRecordsTable get documentRecords => attachedDatabase.documentRecords;
  $JobTagsTable get jobTags => attachedDatabase.jobTags;
  DocumentRecordDaoManager get managers => DocumentRecordDaoManager(this);
}

class DocumentRecordDaoManager {
  final _$DocumentRecordDaoMixin _db;
  DocumentRecordDaoManager(this._db);
  $$DocumentRecordsTableTableManager get documentRecords =>
      $$DocumentRecordsTableTableManager(
          _db.attachedDatabase, _db.documentRecords);
  $$JobTagsTableTableManager get jobTags =>
      $$JobTagsTableTableManager(_db.attachedDatabase, _db.jobTags);
}
