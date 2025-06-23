// lib/data/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/data/database/shared.dart'; // สำหรับ connect()
import 'connection/connection.dart' as impl;
import 'package:drift/wasm.dart'; // สำหรับ WasmDatabase ใน connectWorker()

// Import table definitions
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart';

// Import DAO definitions
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_tag_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/sync_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';

// This line tells drift to generate a file named app_database.g.dart
part 'app_database.g.dart';

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
    UserDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(DatabaseConnection connection) : super(connection);

  static AppDatabase? _instance;

  static Future<AppDatabase> instance() async {
    _instance ??= AppDatabase._(await impl.connect());
    return _instance!;
  }

  @override
  int get schemaVersion => 1;
}
