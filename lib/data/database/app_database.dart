// lib/data/database/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart'; // For native platforms (Android/iOS)
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import your table definitions
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
// TODO: You will add more table imports here as you convert them:
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart';

// Import your DAO definitions
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_tag_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/sync_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart'; // Add this line

// This line tells drift to generate a file named app_database.g.dart
part 'app_database.g.dart';

// This annotation tells drift which tables belong to this database.
// It's similar to @Database(entities = [...]) in Room.
@DriftDatabase(
  tables: [
    Jobs,
    Documents,
    DocumentMachines,
    DocumentRecords,
    JobMachines,
    JobTags,
    Problems,
    Syncs,
    Users,
  ],
    daos: [
    JobDao,
    DocumentDao,
    DocumentMachineDao,
    DocumentRecordDao,
    JobMachineDao,
    JobTagDao,
    ProblemDao,
    SyncDao,
    UserDao, // Add this line to list your DAOs
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // You can define a singleton instance if needed, similar to DatabaseMaster.kt
  static AppDatabase get instance => _instance;
  static final AppDatabase _instance = AppDatabase();


  @override
  int get schemaVersion => 1; // Increment this number when you change your table schema

  // Optional: If you need to handle migrations, define them here.
  // @override
  // MigrationStrategy get migration => MigrationStrategy(
  //       onCreate: (Migrator m) {
  //         return m.createAll();
  //       },
  //       onUpgrade: (Migrator m, int from, int to) async {
  //         // Define your migration logic here (similar to Room's Migration)
  //         // Example: if (from < 2) await m.addColumn(yourTable.newColumn);
  //       },
  //     );
}

// This function provides the underlying connection to the SQLite database file.
// It sets up where the database file will be stored on the device.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite')); // Name of your database file
    return NativeDatabase(file);
  });
}