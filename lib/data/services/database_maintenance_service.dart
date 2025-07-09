// lib/data/services/database_maintenance_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart'; // For zipping files
import 'package:http/http.dart' as http; // For uploading files
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For database access
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // For SyncStatus, SyncError, SyncSuccess
//import 'package:http_parser/http_parser.dart'; // <<< CRUCIAL FIX: Import MediaType

// TODO: Define your API endpoint for database upload
const String _dbUploadApiUrl = "http://10.1.200.26/ServiceJson/Service4.svc/UploadDatabase"; // Placeholder API endpoint

class DatabaseMaintenanceService {
  final AppDatabase _appDatabase;

  DatabaseMaintenanceService({required AppDatabase appDatabase})
      : _appDatabase = appDatabase;

   /// Performs a backup of the local SQLite database, zips it, and uploads it to a server.
  /// CRUCIAL FIX: Deletes the generated zip file regardless of upload success or failure.
  Future<SyncStatus> backupAndUploadDb({String? userId, String? deviceId}) async {
    File? backupFile;
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFilePath = p.join(dbFolder.path, 'db.sqlite');

      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        return const SyncError(message: 'Database file not found locally.');
      }

      final List<int> fileBytes = dbFile.readAsBytesSync();
      if (fileBytes.isEmpty) {
        return const SyncError(message: 'Database file is empty or could not be read.');
      }
      
      final archive = Archive();
      archive.addFile(ArchiveFile('db.sqlite', dbFile.lengthSync(), fileBytes));
      final zipBytes = ZipEncoder().encode(archive);

      final backupDir = Directory(p.join(dbFolder.path, 'db_backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final String finalDeviceId = deviceId ?? 'unknown_device';
      final String uniqueFileName = 'biochecksheet_backup_${finalDeviceId}_${DateTime.now().millisecondsSinceEpoch}.zip';
      final String backupFilePath = p.join(backupDir.path, uniqueFileName);
      backupFile = File(backupFilePath);
      await backupFile.writeAsBytes(zipBytes!);

      print('Database backed up to: $backupFilePath');

      // CRUCIAL CHANGE: Use http.Request for raw binary upload
      final uri = Uri.parse(_dbUploadApiUrl);
      final request = http.Request('POST', uri) // <<< Use http.Request
        ..headers['Content-Type'] = 'application/zip' // <<< Set Content-Type for the entire body
        ..headers['userId'] = userId ?? 'unknown' // <<< Add userId to header
        ..headers['deviceId'] = deviceId ?? 'unknown' // <<< Add deviceId to header
        ..bodyBytes = zipBytes; // <<< Set the zip file bytes as the body

      final response = await http.Client().send(request); // <<< Send the Request

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
      return SyncError(exception: e, message: 'ข้อผิดพลาดในการสำรองและอัปโหลดฐานข้อมูล: $e');
    } finally {
      if (backupFile != null && await backupFile.exists()) {
        try {
          await backupFile.delete();
          print('Database backup zip file deleted: ${backupFile.path}');
        } catch (deleteError) {
          print('Error deleting backup zip file: $deleteError');
        }
      }
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