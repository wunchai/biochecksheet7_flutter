// lib/data/network/voice_report_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/models/voice_report_models.dart';

/// Client for CheckSheet Voice API:
/// - POST {BASE_URL}/CHECKSHEET_VOICE_UPLOAD (multipart/form-data)
/// - POST {BASE_URL}/CHECKSHEET_VOICE ({ServiceName, Paremeter})
/// - GET  {BASE_URL}/CHECKSHEET_VOICE_AUDIO?id={id}
class VoiceReportApiService {
  VoiceReportDetail _parseDetailPayload(Map<String, dynamic> body) {
    final rows = _extractTable(body, 'Table');
    if (rows.isEmpty) {
      throw const VoiceNotFoundException('ไม่พบรายการเสียง', code: 50102);
    }
    final engines =
        _extractTable(body, 'Table1').map(VoiceEngineResult.fromJson).toList();
    final summaries =
        _extractTable(body, 'Table2').map(VoiceSummarySlot.fromJson).toList();
    final history = _extractTable(body, 'Table3')
        .map(VoiceSummaryHistoryItem.fromJson)
        .toList();
    return VoiceReportDetail(
      report: VoiceReportItem.fromJson(rows.first),
      engineResults: engines,
      summaries: summaries,
      summaryHistory: history,
    );
  }

  /// 4. POST /CHECKSHEET_VOICE_UPLOAD (returns same 4-table format as Detail)
  Future<VoiceReportDetail> uploadVoice({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String mimeType,
    required String clientRecordId,
    required String userId,
    required int jobId,
    required String recordedAtIso,
    required double durationSec,
    required String platform,
    String? appVersion,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_VOICE_UPLOAD');
    final req = http.MultipartRequest('POST', uri)
      ..fields['clientRecordId'] = clientRecordId
      ..fields['userId'] = userId
      ..fields['jobId'] = '$jobId'
      ..fields['recordedAt'] = recordedAtIso
      ..fields['durationSec'] = durationSec.toStringAsFixed(1)
      ..fields['platform'] = platform;

    if (appVersion != null && appVersion.trim().isNotEmpty) {
      final trimmedVer = appVersion.trim();
      req.fields['appVersion'] =
          trimmedVer.length <= 30 ? trimmedVer : trimmedVer.substring(0, 30);
    }

    final mediaType = MediaType.parse(mimeType);
    if (fileBytes != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    } else {
      throw const VoiceRejectedException('ไม่พบไฟล์เสียงสำหรับอัปโหลด');
    }

    http.Response res;
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const VoiceRetryLaterException(
          'การส่งไฟล์เสียงหมดเวลา (Timeout) ระบบจะเก็บไว้ส่งใหม่ภายหลัง');
    } catch (e) {
      throw VoiceRetryLaterException(
          'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ($e) ระบบจะเก็บไว้ส่งใหม่ภายหลัง');
    }

    final decodedText = utf8.decode(res.bodyBytes);
    dynamic body;
    try {
      body = decodedText.isEmpty ? {} : jsonDecode(decodedText);
    } catch (_) {
      body = null;
    }

    if (res.statusCode == 200 && body is Map<String, dynamic>) {
      if (body['status']?.toString().toLowerCase() == 'error') {
        final code = _parseCode(body['code']);
        final msg = body['message']?.toString() ?? 'ข้อมูลไม่ถูกต้อง';
        throw VoiceRejectedException(msg, code: code);
      }
      return _parseDetailPayload(body);
    }

    if (res.statusCode == 400) {
      final msg = (body is Map<String, dynamic>)
          ? (body['message']?.toString() ??
              body['title']?.toString() ??
              'ข้อมูลไม่ถูกต้อง (HTTP 400)')
          : 'ข้อมูลไม่ถูกต้อง (HTTP 400)';
      final code =
          (body is Map<String, dynamic>) ? _parseCode(body['code']) : null;
      throw VoiceRejectedException(msg, code: code);
    }

    if (res.statusCode == 404) {
      final msg = (body is Map<String, dynamic>)
          ? (body['message']?.toString() ?? 'ไม่พบรายการ (HTTP 404)')
          : 'ไม่พบรายการ (HTTP 404)';
      final code =
          (body is Map<String, dynamic>) ? _parseCode(body['code']) : null;
      throw VoiceNotFoundException(msg, code: code);
    }

    throw VoiceRetryLaterException(
        'เซิร์ฟเวอร์ตอบกลับ HTTP ${res.statusCode} ระบบจะเก็บไว้ส่งใหม่ภายหลัง');
  }

  /// Helper for POST /CHECKSHEET_VOICE ({ServiceName, Paremeter})
  Future<Map<String, dynamic>> _call(
    String serviceName, [
    Map<String, dynamic>? param,
  ]) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/CHECKSHEET_VOICE');
    final payload = {
      'ServiceName': serviceName,
      'Paremeter': param == null ? '' : jsonEncode(param),
    };

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const VoiceRetryLaterException('การเชื่อมต่อหมดเวลา (Timeout)');
    } catch (e) {
      throw VoiceRetryLaterException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e');
    }

    final decodedText = utf8.decode(response.bodyBytes);
    dynamic decoded;
    try {
      decoded = decodedText.isEmpty ? {} : jsonDecode(decodedText);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode == 400) {
      final msg = (decoded is Map<String, dynamic>)
          ? (decoded['message']?.toString() ??
              decoded['title']?.toString() ??
              'ข้อมูลไม่ถูกต้อง (HTTP 400)')
          : 'ข้อมูลไม่ถูกต้อง (HTTP 400)';
      final code = (decoded is Map<String, dynamic>)
          ? _parseCode(decoded['code'])
          : null;
      throw VoiceRejectedException(msg, code: code);
    }

    if (response.statusCode == 404) {
      final msg = (decoded is Map<String, dynamic>)
          ? (decoded['message']?.toString() ?? 'ไม่พบรายการ (HTTP 404)')
          : 'ไม่พบรายการ (HTTP 404)';
      final code = (decoded is Map<String, dynamic>)
          ? _parseCode(decoded['code'])
          : null;
      throw VoiceNotFoundException(msg, code: code);
    }

    if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
      throw VoiceRetryLaterException('HTTP ${response.statusCode}');
    }

    if (decoded['status']?.toString().toLowerCase() == 'error') {
      final msg = decoded['message']?.toString() ?? 'เกิดข้อผิดพลาด';
      final code = _parseCode(decoded['code']);
      throw VoiceRejectedException(msg, code: code);
    }

    return decoded;
  }

  int? _parseCode(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
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

  /// 5. Detail (by `id` or `clientRecordId`) — returns Table, Table1 (engines), Table2 (summaries), Table3 (history)
  Future<VoiceReportDetail> getDetail({
    String? id,
    String? clientRecordId,
  }) async {
    final param = <String, dynamic>{
      if (id != null && id.isNotEmpty) 'id': id,
      if ((id == null || id.isEmpty) &&
          clientRecordId != null &&
          clientRecordId.isNotEmpty)
        'clientRecordId': clientRecordId,
    };
    final body = await _call('Detail', param);
    return _parseDetailPayload(body);
  }

  /// 6. List
  Future<List<VoiceReportItem>> getList({
    String? fromDate,
    String? toDate,
    int? status,
    int? jobId,
    String? userId,
    int top = 100,
  }) async {
    final param = <String, dynamic>{
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      if (status != null) 'status': status,
      if (jobId != null) 'jobId': jobId,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      'top': top,
    };
    final body = await _call('List', param);
    return _extractTable(body, 'Table')
        .map(VoiceReportItem.fromJson)
        .toList();
  }

  /// 7. Lookups
  Future<VoiceLookups> getLookups() async {
    final body = await _call('Lookups');
    final statuses = _extractTable(body, 'Table')
        .map(VoiceStatusLookup.fromJson)
        .toList();
    final engines = _extractTable(body, 'Table1')
        .map(VoiceEngineLookup.fromJson)
        .toList();
    return VoiceLookups(statuses: statuses, engines: engines);
  }

  /// 9. Retry (Admin-only; not exposed in standard user UI)
  Future<VoiceReportDetail> retryAdminOnly({
    required String id,
    int? engineId,
    required String user,
  }) async {
    final body = await _call('Retry', {
      'id': id,
      if (engineId != null) 'engineId': engineId,
      'user': user,
    });
    return _parseDetailPayload(body);
  }

  /// 9.1 SaveSummary (Human summary — Channel ④)
  Future<VoiceReportDetail> saveSummary({
    required String id,
    required String text,
    String? note,
    required String user,
  }) async {
    final trimmedNote = note?.trim();
    final body = await _call('SaveSummary', {
      'id': id,
      'text': text.trim(),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      'user': user,
    });
    return _parseDetailPayload(body);
  }
}
