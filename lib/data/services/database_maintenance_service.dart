// lib/data/services/database_maintenance_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart'; // For zipping files
import 'package:http/http.dart' as http; // For uploading files
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For database access
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // For SyncStatus, SyncError, SyncSuccess
import 'package:http_parser/http_parser.dart'; // <<< CRUCIAL FIX: Import MediaType

// TODO: Define your API endpoint for database upload
const String _dbUploadApiUrl = "http://10.1.200.26/ServiceJson/Service4.svc/UploadDatabase"; // Placeholder API endpoint

class DatabaseMaintenanceService {
  final AppDatabase _appDatabase;

  DatabaseMaintenanceService({required AppDatabase appDatabase})
      : _appDatabase = appDatabase;

  /// Performs a backup of the local SQLite database, zips it, and uploads it to a server.
  Future<SyncStatus> backupAndUploadDb({String? userId, String? deviceId}) async {
    try {
      // CRUCIAL FIX: Do NOT close/reopen database here.
      // The database connection should be managed by the AppDatabase.instance getter
      // which ensures a single instance. If you need to ensure file is not locked,
      // you might need to ensure the database connection is truly closed
      // before attempting file operations, which is complex with AppDatabase.instance.
      // For simplicity, we assume AppDatabase.instance manages its own connection.

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFilePath = p.join(dbFolder.path, 'biochecksheet.sqlite'); // The actual database file name

      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        return const SyncError(message: 'Database file not found locally.'); // <<< CRUCIAL FIX: Use named parameter
      }

      // 1. Create a zip archive
      // CRUCIAL FIX: Ensure readAsBytesSync() returns non-null List<int>
      final List<int> fileBytes = dbFile.readAsBytesSync();
      if (fileBytes.isEmpty) {
        return const SyncError(message: 'Database file is empty or could not be read.'); // <<< CRUCIAL FIX: Use named parameter
      }
      
      final archive = Archive();
      archive.addFile(ArchiveFile('biochecksheet.sqlite', fileBytes.length, fileBytes)); // <<< Pass non-nullable List<int>
      final zipBytes = ZipEncoder().encode(archive);

      final backupDir = Directory(p.join(dbFolder.path, 'db_backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final backupFilePath = p.join(backupDir.path, 'biochecksheet_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
      final backupFile = File(backupFilePath);
      await backupFile.writeAsBytes(zipBytes!); // zipBytes can be null if encode fails

      print('Database backed up to: $backupFilePath');

      // 2. Upload the zipped file to server
      final uri = Uri.parse(_dbUploadApiUrl);
      final request = http.MultipartRequest('POST', uri)
        ..headers['Content-Type'] = 'multipart/form-data'
        ..fields['userId'] = userId ?? 'unknown'
        ..fields['deviceId'] = deviceId ?? 'unknown'
        ..files.add(http.MultipartFile.fromBytes(
          'databaseFile',
          zipBytes, // <<< Pass non-nullable zipBytes
          filename: 'biochecksheet.zip',
          contentType: MediaType('application', 'zip'), // <<< Use MediaType
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Database upload successful: $responseBody');
        return const SyncSuccess(message: 'สำรองและอัปโหลดฐานข้อมูลสำเร็จ!');
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Database upload failed: ${response.statusCode} - $errorBody');
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on Exception catch (e) {
      print('Error during database backup and upload: $e');
      return SyncError(exception: e, message: 'ข้อผิดพลาดในการสำรองและอัปโหลดฐานข้อมูล: $e'); // <<< CRUCIAL FIX: Use named parameter
    } finally {
      // Reopen the database connection after operation (if it was closed).
      // This is not needed if AppDatabase.instance manages connection.
      // _appDatabase.connect(); // REMOVED: This method does not exist on AppDatabase
    }
  }

  /// Executes a raw SQL query received from the server.
  /// This function is HIGHLY DANGEROUS and should only be used with extreme caution
  /// and strict security measures.
  Future<SyncStatus> executeRawSqlQuery(String sqlQuery) async {
    try {
      await _appDatabase.customStatement(sqlQuery);
      print('Raw SQL query executed successfully: $sqlQuery');
      return const SyncSuccess(message: 'รัน Raw SQL Query สำเร็จ!');
    } on Exception catch (e) {
      print('Error executing raw SQL query: $e');
      return SyncError(exception: e, message: 'ข้อผิดพลาดในการรัน Raw SQL Query: $e');
    }
  }
}