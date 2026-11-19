// lib/data/network/document_online_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For DbDocumentOnline
import 'package:biochecksheet7_flutter/data/network/api_request_models.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
import 'package:biochecksheet7_flutter/data/models/am_summary_models.dart';
import 'package:biochecksheet7_flutter/data/models/checksheet_audit_models.dart';

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
            lot: json['Lot']?.toString() ??
                json['lot']?.toString(), // <<< NEW: Parse LOT
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
                : int.tryParse(json['uiType']?.toString() ?? '0') ?? 0,
            verify: json['Verify'] is int
                ? json['Verify']
                : int.tryParse(json['Verify']?.toString() ?? '0') ?? 0,
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

  // --- NEW: Fetch Machine Summary Online ---
  Future<dynamic> fetchMachineSummaryOnline({
    required String userId,
    required String jobId,
    required String documentId,
    int pageIndex = 1,
    int pageSize = 1000,
  }) async {
    final url =
        Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_MACHINE_SUMMARY_GET');

    final innerBody = {
      "UserId": userId,
      "JobId": jobId,
      "DocumentId": documentId,
      "PageIndex": pageIndex.toString(),
      "PageSize": pageSize.toString(),
    };

    final body = {
      "ServiceName": "CHECKSHEET_MACHINE_SUMMARY_GET",
      "Paremeter": jsonEncode(innerBody)
    };

    try {
      print(
          'DocumentOnlineApiService: Fetching Machine Summary from $url (Page: $pageIndex, Size: $pageSize)');
      print('DEBUG MACHINE SUMMARY BODY: $body');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print(
          'DocumentOnlineApiService: Machine Summary Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        print('DEBUG MACHINE SUMMARY RESPONSE BODY: $decodedBody');
        return jsonDecode(decodedBody);
      } else {
        print('DEBUG MACHINE SUMMARY FAILED: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during fetchMachineSummaryOnline: $e');
      return null;
    }
  }

  // --- NEW: Open Case API Methods ---
  Future<OpenCaseGetResponse?> getOpenCase(int apiId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_OPEN_CASE_GET');
    //final body = {"apiId": apiId};
    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_OPEN_CASE_GET",
      "Paremeter":
          jsonEncode({"apiId": apiId}) // Assuming this parameter is used
    });

    print('DEBUG getOpenCase REQUEST: url=$url, body=$body');

    try {
      final response = await http.post(
        url,
        headers: {'accept': 'text/plain', 'Content-Type': 'application/json'},
        body: body,
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

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_OPEN_CASE_SET",
      "Paremeter":
          jsonEncode(request.toJson()) // Assuming this parameter is used
    });

    try {
      final response = await http.post(
        url,
        headers: {'accept': 'text/plain', 'Content-Type': 'application/json'},
        body: body,
      );

      print('DEBUG SET OPEN CASE BODY: $body');
      print('DEBUG SET OPEN CASE RESPONSE: statusCode=${response.statusCode}');
      print('DEBUG SET OPEN CASE RESPONSE: body=${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception in setOpenCase: $e');
      return false;
    }
  }

  // --- NEW: Supervisor Check API Methods ---
  Future<SupervisorCheckGetResponse?> getSupervisorCheck(
      String documentId, String machineId) async {
    final url =
        Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_SUPERVISOR_CHECK_GET');
    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_SUPERVISOR_CHECK_GET",
      "Paremeter": jsonEncode({
        "DocumentId": documentId,
        "MachineId": machineId,
      })
    });

    print('DEBUG getSupervisorCheck REQUEST: url=$url, body=$body');

    try {
      final response = await http.post(
        url,
        headers: {'accept': 'text/plain', 'Content-Type': 'application/json'},
        body: body,
      );

      print(
          'DEBUG getSupervisorCheck RESPONSE: statusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        print('DEBUG GET SUPERVISOR CHECK JSON: $responseData');

        return SupervisorCheckGetResponse.fromJson(responseData);
      } else {
        print('DEBUG getSupervisorCheck FAILED BODY: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Exception in getSupervisorCheck: $e');
      return null;
    }
  }

  Future<bool> setSupervisorCheck(SupervisorCheckSetRequest request) async {
    final url =
        Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_SUPERVISOR_CHECK_SET');

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_SUPERVISOR_CHECK_SET",
      "Paremeter": jsonEncode(request.toJson())
    });

    try {
      final response = await http.post(
        url,
        headers: {'accept': 'text/plain', 'Content-Type': 'application/json'},
        body: body,
      );

      print('DEBUG SET SUPERVISOR CHECK BODY: $body');
      print(
          'DEBUG SET SUPERVISOR CHECK RESPONSE: statusCode=${response.statusCode}');
      print('DEBUG SET SUPERVISOR CHECK RESPONSE: body=${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception in setSupervisorCheck: $e');
      return false;
    }
  }

  // --- NEW: Calendar Overview API ---
  Future<CalendarSummaryResponse?> getCalendarSummary(
    String userId,
    int year,
    int month, {
    int pageIndex = 1,
    int pageSize = 100,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_CALENDAR_SUMMARY');

    final innerParameter = {
      "userId": userId,
      "year": year.toString(),
      "month": month.toString(),
      "PageIndex": pageIndex.toString(),
      "PageSize": pageSize.toString(),
    };

    final body = {
      "ServiceName": "CHECKSHEET_CALENDAR_SUMMARY",
      "Paremeter": jsonEncode(innerParameter),
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
        print('=== CALENDAR API RAW RESPONSE ===');
        print(decodedBody);
        print('=================================');
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        return CalendarSummaryResponse.fromJson(responseData);
      } else {
        print('Error getCalendarSummary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getCalendarSummary: $e');
      return null;
    }
  }

  // --- NEW: Notification History API ---
  Future<NotificationHistoryResponse?> getNotificationHistory(
    String userId, {
    int pageIndex = 1,
    int pageSize = 20,
    int lastId = 0,
  }) async {
    final url =
        Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_NOTIFICATION_HISTORY_GET');

    final innerParameter = {
      "userId": userId,
      "pageIndex": pageIndex,
      "pageSize": pageSize,
      "lastId": lastId,
    };

    final body = {
      "ServiceName": "CHECKSHEET_NOTIFICATION_HISTORY_GET",
      "Paremeter": jsonEncode(innerParameter),
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
        return NotificationHistoryResponse.fromJson(responseData);
      } else {
        print('Error getNotificationHistory: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getNotificationHistory: $e');
      return null;
    }
  }

  // --- NEW: AM Management Summary Dashboard API (CHECKSHEET_SUMMARY_GET) ---
  Future<List<Map<String, dynamic>>> _fetchAmSummaryRaw({
    required String level,
    String? jobId,
    String? documentId,
    String? fromDate,
    String? toDate,
    bool? openCaseOnly,
    bool refresh = false,
    int pageIndex = 1,
    int pageSize = 100000,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_SUMMARY_GET');

    final innerParameter = <String, dynamic>{
      "level": level,
      "refresh": refresh ? "1" : "0",
      "PageIndex": pageIndex.toString(),
      "PageSize": pageSize.toString(),
      if (jobId != null && jobId.isNotEmpty) "jobId": jobId,
      if (documentId != null && documentId.isNotEmpty) "documentId": documentId,
      if (fromDate != null && fromDate.isNotEmpty) "fromDate": fromDate,
      if (toDate != null && toDate.isNotEmpty) "toDate": toDate,
      if (openCaseOnly != null) "openCaseOnly": openCaseOnly ? "1" : "0",
    };

    final body = {
      "ServiceName": "CHECKSHEET_SUMMARY_GET",
      "Paremeter": jsonEncode(innerParameter),
    };

    final response = await http
        .post(
          url,
          headers: {
            'accept': 'text/plain',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
          'HTTP ${response.statusCode}: ไม่สามารถดึงข้อมูลสรุป AM ($level)');
    }

    final String decodedBody = utf8.decode(response.bodyBytes);
    final dynamic parsed = jsonDecode(decodedBody);

    if (parsed is Map<String, dynamic>) {
      final status = parsed['status']?.toString().toLowerCase();
      if (status == 'error') {
        throw Exception(
            parsed['message']?.toString() ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์');
      }
      final dynamic rawData = parsed['Data'] ?? parsed['data'];
      if (rawData == null) return [];
      final dynamic listData =
          rawData is String ? jsonDecode(rawData) : rawData;
      if (listData is List) {
        return listData
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } else if (parsed is List) {
      return parsed
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  Future<List<AmSummaryMonthlyRow>> getAmSummaryMonthly({
    String? jobId,
    String? fromDate,
    String? toDate,
    bool refresh = true,
  }) async {
    final rows = await _fetchAmSummaryRaw(
      level: 'JOB_MONTHLY',
      jobId: jobId,
      fromDate: fromDate,
      toDate: toDate,
      refresh: refresh,
    );
    return rows.map(AmSummaryMonthlyRow.fromJson).toList();
  }

  Future<List<AmSummaryDocumentRow>> getAmSummaryDocuments({
    String? jobId,
    String? documentId,
    String? fromDate,
    String? toDate,
  }) async {
    final rows = await _fetchAmSummaryRaw(
      level: 'DOCUMENT',
      jobId: jobId,
      documentId: documentId,
      fromDate: fromDate,
      toDate: toDate,
      refresh: false,
    );
    return rows.map(AmSummaryDocumentRow.fromJson).toList();
  }

  Future<List<AmSummaryAbnormalRow>> getAmSummaryAbnormals({
    String? jobId,
    String? documentId,
    String? fromDate,
    String? toDate,
    bool? openCaseOnly,
  }) async {
    final rows = await _fetchAmSummaryRaw(
      level: 'ABNORMAL',
      jobId: jobId,
      documentId: documentId,
      fromDate: fromDate,
      toDate: toDate,
      openCaseOnly: openCaseOnly,
      refresh: false,
    );
    return rows.map(AmSummaryAbnormalRow.fromJson).toList();
  }

  // --- NEW: CheckSheet Audit API (CHECKSHEET_AUDIT) ---
  Future<List<AuditDocumentRow>> getAuditDocuments({
    required String fromDate,
    required String toDate,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_AUDIT/api/documents')
        .replace(queryParameters: {
      'fromDate': fromDate,
      'toDate': toDate,
    });

    final response = await http
        .get(uri, headers: {'accept': 'application/json'})
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: โหลดรายการเอกสารไม่สำเร็จ');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
    if (decoded['status']?.toString().toLowerCase() != 'success') {
      throw Exception(
          decoded['message']?.toString() ?? 'โหลดข้อมูลไม่สำเร็จ');
    }

    final rawRows = decoded['rows'];
    if (rawRows is List) {
      return rawRows
          .whereType<Map>()
          .map((e) => AuditDocumentRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<AuditDocumentDetail> getAuditDocumentDetail(String documentId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_AUDIT/api/detail')
        .replace(queryParameters: {'documentId': documentId});

    final response = await http
        .get(uri, headers: {'accept': 'application/json'})
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
          'HTTP ${response.statusCode}: โหลดรายละเอียดเอกสารไม่สำเร็จ');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
    if (decoded['status']?.toString().toLowerCase() != 'success') {
      throw Exception(
          decoded['message']?.toString() ?? 'โหลดรายละเอียดไม่สำเร็จ');
    }

    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return AuditDocumentDetail(
      items: parseList(decoded['items'], AuditCheckItem.fromJson),
      verifies: parseList(decoded['verifies'], AuditVerifyEntry.fromJson),
      cases: parseList(decoded['cases'], AuditCaseEntry.fromJson),
      supervisorChecks:
          parseList(decoded['supervisorChecks'], AuditSupervisorCheck.fromJson),
    );
  }
}
