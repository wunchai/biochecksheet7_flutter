// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_dao.dart';

// ignore_for_file: type=lint
mixin _$ProblemDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProblemsTable get problems => attachedDatabase.problems;
  ProblemDaoManager get managers => ProblemDaoManager(this);
}

class ProblemDaoManager {
  final _$ProblemDaoMixin _db;
  ProblemDaoManager(this._db);
  $$ProblemsTableTableManager get problems =>
      $$ProblemsTableTableManager(_db.attachedDatabase, _db.problems);
}
