// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_job_dao.dart';

// ignore_for_file: type=lint
mixin _$DraftJobDaoMixin on DatabaseAccessor<AppDatabase> {
  $DraftJobsTable get draftJobs => attachedDatabase.draftJobs;
  $DraftMachinesTable get draftMachines => attachedDatabase.draftMachines;
  $DraftTagsTable get draftTags => attachedDatabase.draftTags;
  DraftJobDaoManager get managers => DraftJobDaoManager(this);
}

class DraftJobDaoManager {
  final _$DraftJobDaoMixin _db;
  DraftJobDaoManager(this._db);
  $$DraftJobsTableTableManager get draftJobs =>
      $$DraftJobsTableTableManager(_db.attachedDatabase, _db.draftJobs);
  $$DraftMachinesTableTableManager get draftMachines =>
      $$DraftMachinesTableTableManager(_db.attachedDatabase, _db.draftMachines);
  $$DraftTagsTableTableManager get draftTags =>
      $$DraftTagsTableTableManager(_db.attachedDatabase, _db.draftTags);
}
