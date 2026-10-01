// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_machine_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentMachineDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentMachinesTable get documentMachines =>
      attachedDatabase.documentMachines;
  DocumentMachineDaoManager get managers => DocumentMachineDaoManager(this);
}

class DocumentMachineDaoManager {
  final _$DocumentMachineDaoMixin _db;
  DocumentMachineDaoManager(this._db);
  $$DocumentMachinesTableTableManager get documentMachines =>
      $$DocumentMachinesTableTableManager(
          _db.attachedDatabase, _db.documentMachines);
}
