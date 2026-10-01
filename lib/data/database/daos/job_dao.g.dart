// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_dao.dart';

// ignore_for_file: type=lint
mixin _$JobDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  JobDaoManager get managers => JobDaoManager(this);
}

class JobDaoManager {
  final _$JobDaoMixin _db;
  JobDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
}
