// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_tag_dao.dart';

// ignore_for_file: type=lint
mixin _$JobTagDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobTagsTable get jobTags => attachedDatabase.jobTags;
  JobTagDaoManager get managers => JobTagDaoManager(this);
}

class JobTagDaoManager {
  final _$JobTagDaoMixin _db;
  JobTagDaoManager(this._db);
  $$JobTagsTableTableManager get jobTags =>
      $$JobTagsTableTableManager(_db.attachedDatabase, _db.jobTags);
}
