// lib/data/network/sync_metadata_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/sync_table.dart'; // สำหรับ DbSync

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class SyncMetadataApiService {
  Future<List<DbSync>> checkSyncStatus() async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterSync_Check"); // สันนิษฐานว่า API นี้ใช้สำหรับ Sync Metadata
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterSync_Check",
      "Paremeter": {} // Assuming no parameters
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> syncList = responseJson['Table'];
          final List<DbSync> syncedMetadata = syncList.map((syncData) {
            return DbSync(
              uid: 0,
              syncId: syncData['SyncId'] ?? '',
              syncName: syncData['SyncName'] ?? '',
              lastSync: syncData['LastSync'] ?? '', // API อาจส่ง String วันที่มาให้
              syncStatus: int.tryParse(syncData['SyncStatus'].toString()) ?? 0,
              nextSync: syncData['NextSync'] ?? '',
            );
          }).toList();
          return syncedMetadata;
        } else {
          throw Exception("Sync Metadata API response format invalid.");
        }
      } else {
        throw Exception("Sync Metadata failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error during sync metadata: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred during sync metadata: $e");
    }
  }
}