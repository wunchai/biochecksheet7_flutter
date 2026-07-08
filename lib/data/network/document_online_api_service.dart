// lib/data/network/document_online_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For DbDocumentOnline
import 'package:biochecksheet7_flutter/data/network/api_request_models.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';

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
    String? documentId, // <<< NEW
    String pageIndex = "1",
    String pageSize = "20",
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_DOCUMENONLINE_SYNC');

    final body = {
      "userId": userId,
      "jobId": jobId,
      "start": start,
      "stop": stop,
      "documentId": documentId ?? "", // ส่ง String ว่างไปถ้าเป็น null
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

      print(
          'DocumentOnlineApiService: Response status: ${response.statusCode}');

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
            lastSync: json['SyncDate']?.toString() ??
                DateTime.now().toIso8601String(),
            updatedAt: null,
          );
        }).toList();
      } else {
        print(
            'Failed to fetch DocumentOnline sync. Status code: ${response.statusCode}');
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
    final url =
        Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_RECORDTAG_PAGED_SYNC');

    final body = {
      "userId": userId,
      "jobId": jobId,
      "documentId": documentId,
      "pageIndex": pageIndex.toString(),
      "pageSize": pageSize.toString(),
    };

    try {
      print(
          'DocumentOnlineApiService: Fetching Records from $url (Page: $pageIndex, Size: $pageSize)');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print(
          'DocumentOnlineApiService: Record Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);

        final int totalPages = responseData['TotalPages'] ?? 1;
        final String tagsString = responseData['Tags'] ?? '[]';
        final List<dynamic> jsonList = jsonDecode(tagsString);

        print(
            'DocumentOnlineApiService: Fetched ${jsonList.length} tags on page $pageIndex.');
        print(jsonList);
        final List<DbDocumentRecordOnline> records = jsonList.map((json) {
          final parsedApiId = int.tryParse(json['id']?.toString() ??
              json['Id']?.toString() ??
              json['ID']?.toString() ??
              '');
          print('DEBUG API_ID: $parsedApiId for tag: ${json['TagName']}');

          return DbDocumentRecordOnline(
            uid: 0, // auto generated
            apiId: parsedApiId, // NEW: Fetch API ID
            documentId: json['documentId']
                ?.toString(), // API is "documentId", lower camelCase based on sample
            documentCreateDate:
                json['documentCreateDate']?.toString(), // lower camelCase
            documentCreateUser:
                json['documentCreateUser']?.toString(), // lower camelCase
            machineId:
                json['MachineId']?.toString(), // Pascal case based on sample
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
                : int.tryParse(json['uiType']?.toString() ?? '0') ??
                    0, // NEW field requested
            updatedAt: null,
          );
        }).toList();

        return PagedDocumentRecordOnlineResponse(
          totalPages: totalPages,
          records: records,
        );
      } else {
        throw Exception(
            'Failed to fetch DocumentRecordOnline sync. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during fetch DocumentRecordOnline sync: $e');
      throw Exception('Exception during fetch DocumentRecordOnline sync: $e');
    }
  }

  // --- NEW: Open Case API Methods ---
  Future<OpenCaseGetResponse?> getOpenCase(int apiId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_OPEN_CASE_GET');
    final body = {"apiId": apiId};

    print('DEBUG getOpenCase REQUEST: url=$url, body=$body');

    try {
      final response = await http.post(
        url,
        headers: {'accept': 'text/plain', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('DEBUG getOpenCase RESPONSE: statusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        print('DEBUG GET OPEN CASE JSON: $responseData');
        
        // Map to model
        return OpenCaseGetResponse.fromJson(responseData);
      } else {
        print('DEBUG getOpenCase FAILED BODY: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Exception in getOpenCase: $e');
      return null;
    }
  }

  Future<bool> setOpenCase(OpenCaseSetRequest request) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_OPEN_CASE_SET');

    try {
      final response = await http.post(
        url,
        headers: {'accept': 'text/plain', 'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception in setOpenCase: $e');
      return false;
    }
  }
}
