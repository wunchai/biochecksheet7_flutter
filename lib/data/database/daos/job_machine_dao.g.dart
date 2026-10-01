// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_machine_dao.dart';

// ignore_for_file: type=lint
mixin _$JobMachineDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobMachinesTable get jobMachines => attachedDatabase.jobMachines;
  JobMachineDaoManager get managers => JobMachineDaoManager(this);
}

class JobMachineDaoManager {
  final _$JobMachineDaoMixin _db;
  JobMachineDaoManager(this._db);
  $$JobMachinesTableTableManager get jobMachines =>
      $$JobMachinesTableTableManager(_db.attachedDatabase, _db.jobMachines);
}
