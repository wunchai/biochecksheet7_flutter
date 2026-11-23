// lib/data/network/mt_request_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/models/mt_request_models.dart';

/// Client for POST {BASE_URL}/CHECKSHEET_MT_REQUEST
/// Implements all 11 commands defined in CheckSheet_MTRequest_API.md.
class MtRequestApiService {
  Future<Map<String, dynamic>> _call(
    String serviceName, [
    Map<String, dynamic>? param,
  ]) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_MT_REQUEST');
    final payload = {
      'ServiceName': serviceName,
      'Paremeter': param == null ? '' : jsonEncode(param),
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    final decodedText = utf8.decode(response.bodyBytes);
    dynamic decoded;
    try {
      decoded = decodedText.isEmpty ? {} : jsonDecode(decodedText);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode != 200) {
      String msg = 'HTTP ${response.statusCode}';
      int? errCode;
      if (decoded is Map<String, dynamic>) {
        errCode = decoded['code'] is int
            ? decoded['code'] as int
            : int.tryParse(decoded['code']?.toString() ?? '');
        msg = decoded['message']?.toString() ??
            decoded['title']?.toString() ??
            msg;
      }
      throw MtRequestApiException(
        httpStatus: response.statusCode,
        code: errCode,
        message: msg,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const MtRequestApiException(
        httpStatus: 200,
        message: 'รูปแบบข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่ถูกต้อง',
      );
    }

    if (decoded['status']?.toString().toLowerCase() == 'error') {
      throw MtRequestApiException(
        httpStatus: 400,
        code: decoded['code'] is int
            ? decoded['code'] as int
            : int.tryParse(decoded['code']?.toString() ?? ''),
        message: decoded['message']?.toString() ?? 'เกิดข้อผิดพลาด',
      );
    }

    return decoded;
  }

  List<Map<String, dynamic>> _extractTable(
      Map<String, dynamic> body, String key) {
    final dynamic raw = body[key];
    if (raw == null) return const [];
    final dynamic list = raw is String ? jsonDecode(raw) : raw;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  MtRequestDetail _parseDetail(Map<String, dynamic> body) {
    final headers = _extractTable(body, 'Table');
    if (headers.isEmpty) {
      throw const MtRequestApiException(
        httpStatus: 404,
        code: 50030,
        message: 'ไม่พบข้อมูลใบแจ้งซ่อม',
      );
    }
    final cases =
        _extractTable(body, 'Table1').map(MtRequestCaseItem.fromJson).toList();
    return MtRequestDetail(
      header: MtRequestHeader.fromJson(headers.first),
      cases: cases,
    );
  }

  // 3.1 Lookups
  Future<MtRequestLookups> getLookups() async {
    final body = await _call('Lookups');
    final statuses = _extractTable(body, 'Table')
        .map(MtRequestStatusLookup.fromJson)
        .toList();
    final results = _extractTable(body, 'Table1')
        .map(MtRequestResultLookup.fromJson)
        .toList();
    return MtRequestLookups(statuses: statuses, results: results);
  }

  // 3.2 CaseList
  Future<List<MtCaseListItem>> getCaseList({
    int? jobId,
    bool onlyOpen = true,
  }) async {
    final param = <String, dynamic>{
      'onlyOpen': onlyOpen ? 1 : 0,
      if (jobId != null) 'jobId': jobId,
    };
    final body = await _call('CaseList', param);
    return _extractTable(body, 'Table').map(MtCaseListItem.fromJson).toList();
  }

  // 3.3 List
  Future<List<MtRequestListItem>> getRequestList({
    String? fromDate,
    String? toDate,
    int? status,
    int? jobId,
  }) async {
    final param = <String, dynamic>{
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      if (status != null) 'status': status,
      if (jobId != null) 'jobId': jobId,
    };
    final body = await _call('List', param.isEmpty ? null : param);
    return _extractTable(body, 'Table')
        .map(MtRequestListItem.fromJson)
        .toList();
  }

  // 3.4 Detail
  Future<MtRequestDetail> getDetail(int id) async {
    final body = await _call('Detail', {'id': id});
    return _parseDetail(body);
  }

  // 3.5 Create
  Future<MtRequestDetail> create({
    required List<int> problemIds,
    String? description,
    required String user,
  }) async {
    final desc = description?.trim();
    final body = await _call('Create', {
      'problemIds': problemIds,
      if (desc != null && desc.isNotEmpty) 'description': desc,
      'user': user,
    });
    return _parseDetail(body);
  }

  // 3.6 AddCases
  Future<MtRequestDetail> addCases({
    required int id,
    required List<int> problemIds,
    required String user,
  }) async {
    final body = await _call('AddCases', {
      'id': id,
      'problemIds': problemIds,
      'user': user,
    });
    return _parseDetail(body);
  }

  // 3.7 RemoveCase
  Future<MtRequestDetail> removeCase({
    required int id,
    required int problemId,
    required String user,
  }) async {
    final body = await _call('RemoveCase', {
      'id': id,
      'problemId': problemId,
      'user': user,
    });
    return _parseDetail(body);
  }

  // 3.8 Update
  Future<MtRequestDetail> updateDescription({
    required int id,
    String? description,
    required String user,
  }) async {
    final body = await _call('Update', {
      'id': id,
      'description': description?.trim() ?? '',
      'user': user,
    });
    return _parseDetail(body);
  }

  // 3.9 SetRequestNo
  Future<MtRequestDetail> setRequestNo({
    required int id,
    required String requestNo,
    required String user,
  }) async {
    final body = await _call('SetRequestNo', {
      'id': id,
      'requestNo': requestNo.trim(),
      'user': user,
    });
    return _parseDetail(body);
  }

  // 3.10 Close
  Future<MtRequestDetail> close({
    required int id,
    required List<MtCloseCaseInput> results,
    String? closeNote,
    required String user,
  }) async {
    final note = closeNote?.trim();
    final body = await _call('Close', {
      'id': id,
      'results': results.map((r) => r.toJson()).toList(),
      if (note != null && note.isNotEmpty) 'closeNote': note,
      'user': user,
    });
    return _parseDetail(body);
  }

  // 3.11 Cancel
  Future<MtRequestDetail> cancel({
    required int id,
    String? note,
    required String user,
  }) async {
    final trimmed = note?.trim();
    final body = await _call('Cancel', {
      'id': id,
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      'user': user,
    });
    return _parseDetail(body);
  }
}
