// lib/data/database/app_database.dart

import 'package:drift/drift.dart';
//import 'package:biochecksheet7_flutter/data/database/shared.dart'; // สำหรับ connect()
//import 'package:drift/wasm.dart'; // สำหรับ WasmDatabase ใน connectWorker()
// Import the conditional connection.dart with an alias to avoid name conflicts
import 'package:biochecksheet7_flutter/data/database/connection/connection.dart'
    as platform_connection; // <<< เปลี่ยนเป็น platform_connection

// Import all table definitions (should be present from previous steps)
import 'package:biochecksheet7_flutter/data/database/tables/job_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_machine_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart'; // <<< NEW: Import Image table

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
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart'; // <<< NEW: Import ImageDao

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
    Images, // <<< NEW: Add Images table
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
    ImageDao, // <<< NEW: Add ImageDao
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(DatabaseConnection connection) : super(connection);

  static AppDatabase? _instance;

  static Future<AppDatabase> instance() async {
    _instance ??= AppDatabase._(await platform_connection.connect());
    return _instance!;
  }

  // NEW: Add getter for ImageDao
  ImageDao get imageDao => ImageDao(this); // <<< NEW: Add ImageDao getter

  @override
  int get schemaVersion => 6;

  // Define the migration strategy.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createAllUpdatedAtTriggers(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(documentRecords, documentRecords.updatedAt);
            // If you had other tables in v1 that need updatedAt, add them here.
          }
          if (from < 3) {
            // Add 'updatedAt' column to all *newly added* tables or tables that didn't have it before v3
            await m.addColumn(jobs, jobs.updatedAt);
            await m.addColumn(documents, documents.updatedAt);
            await m.addColumn(documentMachines, documentMachines.updatedAt);
            await m.addColumn(jobMachines, jobMachines.updatedAt);
            await m.addColumn(jobTags, jobTags.updatedAt);
            await m.addColumn(problems, problems.updatedAt);
            await m.addColumn(syncs, syncs.updatedAt);
            await m.addColumn(users, users.updatedAt);
            await m.addColumn(images, images.updatedAt);

            await _createAllUpdatedAtTriggers(m);
          }
          if (from < 4) {
            // <<< NEW: If upgrading from version 3 to 4
            // Re-create all triggers to include AFTER INSERT
            await _createAllUpdatedAtTriggers(m);
          }
          if (from < 5) {
            // <<< NEW: If upgrading from version 4 to 5
            // Add the new 'isLocalSessionActive' column to Users table
            await m.addColumn(users, users.isLocalSessionActive);
            // Optionally, set a default value for existing rows if needed (e.g., all existing users are active)
            // await m.customStatement('UPDATE users SET isLocalSessionActive = 1;');
          }
          // --- 2. เพิ่ม Logic การ Migration สำหรับเวอร์ชัน 6 ---
          if (from < 6) {
            // เพิ่มคอลัมน์ uiType เข้าไปในตาราง documentMachines
            await m.addColumn(documentMachines, documentMachines.uiType);
          }
        },
      );

  // Helper method to create a single SQL trigger for updatedAt column
  Future<void> _createUpdatedAtTrigger(
      Migrator m, String tableName, String columnName) async {
    final triggerName = 'update_${tableName}_${columnName}';
    // CRUCIAL FIX: Access customStatement via m.database (which is the AppDatabase instance)
    await m.database.customStatement(
        // <<< CRUCIAL FIX: Changed m.customStatement to m.database.customStatement
        '''
      CREATE TRIGGER IF NOT EXISTS $triggerName
      AFTER UPDATE ON $tableName
      FOR EACH ROW
      BEGIN
        UPDATE $tableName SET $columnName = STRFTIME('%Y-%m-%dT%H:%M:%f', 'now') WHERE uid = OLD.uid;
      END;
      ''');
    print('SQL Trigger "$triggerName" created/ensured.');

    // NEW: Trigger for AFTER INSERT
    final insertTriggerName = 'update_${tableName}_${columnName}_on_insert';
    await m.database.customStatement('''
      CREATE TRIGGER IF NOT EXISTS $insertTriggerName
      AFTER INSERT ON $tableName
      FOR EACH ROW
      BEGIN
        UPDATE $tableName SET $columnName = STRFTIME('%Y-%m-%dT%H:%M:%f', 'now') WHERE uid = NEW.uid;
      END;
      ''');
    print('SQL Trigger "$insertTriggerName" created/ensured.');
  }

  // Helper method to create triggers for all tables
  Future<void> _createAllUpdatedAtTriggers(Migrator m) async {
    await _createUpdatedAtTrigger(m, 'jobs', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'documents', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'document_machines', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'document_records', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'job_machines', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'job_tags', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'problems', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'syncs', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'users', 'updatedAt');
    await _createUpdatedAtTrigger(m, 'images', 'updatedAt');
  }
}
