// lib/data/network/document_online_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For DbDocumentOnline
// import 'package:biochecksheet7_flutter/data/database/tables/document_record_online_table.dart';

class PagedDocumentRecordOnlineResponse {
  final int totalPages;
  final List<DbDocumentRecordOnline> records;

  PagedDocumentRecordOnlineResponse({
    required this.totalPages,
    required this.records,
  });
}

class DocumentOnlineApiService {
  Future<List<DbDocumentOnline>> fetchDocumentOnline({
    required String userId,
    required String jobId,
    required String start,
    required String stop,
    String pageIndex = "1",
    String pageSize = "20",
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_DOCUMENONLINE_SYNC');

    final body = {
      "userId": userId,
      "jobId": jobId,
      "start": start,
      "stop": stop,
      "pageIndex": pageIndex,
      "pageSize": pageSize,
    };

    try {
      print('DocumentOnlineApiService: Fetching from $url');
      print('Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('DocumentOnlineApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        
        // Extracted nested JSON array string
        final String jobsString = responseData['Jobs'] ?? '[]';
        final List<dynamic> jsonList = jsonDecode(jobsString);
        
        print('DocumentOnlineApiService: Fetched ${jsonList.length} records.');

        // Map the JSON response to proper DbDocumentOnline (using DocumentOnlinesCompanion for mapping intermediate or manual mapping)
        return jsonList.map((json) {
          return DbDocumentOnline(
            uid: 0, // auto generated
            documentId: json['DocumentId']?.toString(),
            jobId: json['JobId']?.toString(),
            documentName: json['DocumentName']?.toString(),
            userId: json['CreateBy']?.toString(),
            createDate: json['CreateDate']?.toString(),
            status: json['Status'] is int
                ? json['Status']
                : int.tryParse(json['Status']?.toString() ?? '0') ?? 0,
            lastSync: json['SyncDate']?.toString() ?? DateTime.now().toIso8601String(),
            updatedAt: null,
          );
        }).toList();
      } else {
        print('Failed to fetch DocumentOnline sync. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
        // Or throw Exception('Failed to load online documents');
      }
    } catch (e) {
      print('Exception during fetch DocumentOnline sync: $e');
      throw Exception('Exception during fetch DocumentOnline sync: $e');
    }
  }

  // --- NEW: Fetch Tags for Online View ---
  Future<PagedDocumentRecordOnlineResponse> fetchDocumentRecordPagedOnline({
    required String userId,
    required String jobId,
    required String documentId,
    int pageIndex = 1,
    int pageSize = 1000,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_RECORDTAG_PAGED_SYNC');

    final body = {
      "userId": userId,
      "jobId": jobId,
      "documentId": documentId,
      "pageIndex": pageIndex.toString(),
      "pageSize": pageSize.toString(),
    };

    try {
      print('DocumentOnlineApiService: Fetching Records from $url (Page: $pageIndex, Size: $pageSize)');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('DocumentOnlineApiService: Record Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        
        final int totalPages = responseData['TotalPages'] ?? 1;
        final String tagsString = responseData['Tags'] ?? '[]';
        final List<dynamic> jsonList = jsonDecode(tagsString);

        print('DocumentOnlineApiService: Fetched ${jsonList.length} tags on page $pageIndex.');

        // Map the JSON response to proper DbDocumentRecordOnline
        final List<DbDocumentRecordOnline> records = jsonList.map((json) {
          return DbDocumentRecordOnline(
            uid: 0, // auto generated
            documentId: json['documentId']?.toString(), // API is "documentId", lower camelCase based on sample
            documentCreateDate: json['documentCreateDate']?.toString(), // lower camelCase
            documentCreateUser: json['documentCreateUser']?.toString(), // lower camelCase
            machineId: json['MachineId']?.toString(), // Pascal case based on sample
            jobId: json['JobId']?.toString(),
            tagId: json['TagId']?.toString(),
            tagName: json['TagName']?.toString(),
            tagGroupId: json['TagGroupId']?.toString(),
            tagGroupName: json['TagGroupName']?.toString(),
            tagType: json['TagType']?.toString(),
            tagSelectionValue: json['TagSelectionValue']?.toString(),
            description: json['Description']?.toString(),
            specification: json['Specification']?.toString(),
            specMin: json['SpecMin']?.toString(),
            specMax: json['SpecMax']?.toString(),
            unit: json['Unit']?.toString(),
            valueType: json['ValueType']?.toString(),
            value: json['Value']?.toString(),
            status: json['Status'] is int
                ? json['Status']
                : int.tryParse(json['Status']?.toString() ?? '0') ?? 0,
            unReadable: json['UnReadable']?.toString() ?? 'false',
            remark: json['Remark']?.toString(),
            syncDate: json['SyncDate']?.toString(),
            uiType: json['uiType'] is int 
                ? json['uiType'] 
                : int.tryParse(json['uiType']?.toString() ?? '0') ?? 0, // NEW field requested
            updatedAt: null,
          );
        }).toList();

        return PagedDocumentRecordOnlineResponse(
          totalPages: totalPages,
          records: records,
        );
      } else {
        throw Exception('Failed to fetch DocumentRecordOnline sync. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during fetch DocumentRecordOnline sync: $e');
      throw Exception('Exception during fetch DocumentRecordOnline sync: $e');
    }
  }
}

