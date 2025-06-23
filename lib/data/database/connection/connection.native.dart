// lib/data/database/connection/connection.native.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Removed unused import for sqlite3
// import 'package:sqlite3/sqlite3.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(
    Future(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));

      // The NativeDatabase constructor now correctly returns a QueryExecutor
      // which is then wrapped in a DatabaseConnection as required.
      // This resolves the 'return_of_invalid_type_from_closure' error.
      final executor = NativeDatabase(file, logStatements: false);
      return DatabaseConnection(executor);
    }),
  );
}
