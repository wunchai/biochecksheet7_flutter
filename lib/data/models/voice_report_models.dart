// lib/data/models/voice_report_models.dart

/// Formats DateTime as ISO 8601 WITH local timezone offset (e.g. `2026-11-27T14:05:10+07:00`).
/// Required by CheckSheet Voice API Section 4.5 (plain `toIso8601String()` has no offset and causes 50113).
String formatVoiceIsoWithOffset(DateTime t) {
  final local = t.toLocal();
  final o = local.timeZoneOffset;
  final sign = o.isNegative ? '-' : '+';
  final hh = o.inHours.abs().toString().padLeft(2, '0');
  final mm = (o.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final base = local.toIso8601String().split('.').first;
  return '$base$sign$hh:$mm';
}

/// HTTP 400 error: invalid payload/rule violation. Must NOT be auto-retried.
class VoiceRejectedException implements Exception {
  final int? code;
  final String message;

  const VoiceRejectedException(this.message, {this.code});

  @override
  String toString() => message;
}

/// HTTP 404 error: report or audio file not found (50102 / 50106).
class VoiceNotFoundException implements Exception {
  final int? code;
  final String message;

  const VoiceNotFoundException(this.message, {this.code});

  @override
  String toString() => message;
}

/// HTTP 500 / network error / timeout: keep file in local queue and retry later with backoff.
class VoiceRetryLaterException implements Exception {
  final String message;

  const VoiceRetryLaterException(this.message);

  @override
  String toString() => message;
}

dynamic _vReadKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return null;
}

int _vToInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? fallback;
}

int? _vToNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double _vToDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? fallback;
}

double? _vToNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

bool _vToBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

String _vToStr(dynamic v) => v?.toString() ?? '';

String? _vToNullableStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/// Lookups -> Table (statuses)
class VoiceStatusLookup {
  final int id;
  final String name;

  const VoiceStatusLookup({required this.id, required this.name});

  factory VoiceStatusLookup.fromJson(Map<String, dynamic> json) {
    return VoiceStatusLookup(
      id: _vToInt(_vReadKey(json, 'id')),
      name: _vToStr(_vReadKey(json, 'name')),
    );
  }
}

/// Lookups -> Table1 (engines)
class VoiceEngineLookup {
  final int id;
  final String engineType;
  final String model;
  final bool enabled;
  final bool isPrimary;

  const VoiceEngineLookup({
    required this.id,
    required this.engineType,
    required this.model,
    required this.enabled,
    required this.isPrimary,
  });

  factory VoiceEngineLookup.fromJson(Map<String, dynamic> json) {
    return VoiceEngineLookup(
      id: _vToInt(_vReadKey(json, 'id')),
      engineType: _vToStr(_vReadKey(json, 'engineType')),
      model: _vToStr(_vReadKey(json, 'model')),
      enabled: _vToBool(_vReadKey(json, 'enabled')),
      isPrimary: _vToBool(_vReadKey(json, 'isPrimary')),
    );
  }
}

class VoiceLookups {
  final List<VoiceStatusLookup> statuses;
  final List<VoiceEngineLookup> engines;

  const VoiceLookups({
    required this.statuses,
    this.engines = const [],
  });

  String statusNameFor(int status, {String? fallback}) {
    if (fallback != null && fallback.isNotEmpty) return fallback;
    for (final s in statuses) {
      if (s.id == status) return s.name;
    }
    switch (status) {
      case 0:
        return 'รอถอดเสียง';
      case 1:
        return 'กำลังถอดเสียง';
      case 2:
        return 'ถอดเสียงแล้ว';
      case 3:
        return 'สรุปแล้ว';
      case 4:
        return 'ตรวจทานแล้ว';
      case 8:
        return 'ไม่ได้ถอดเสียง';
      case 9:
        return 'ล้มเหลว';
      default:
        return 'สถานะ $status';
    }
  }
}

/// Report item returned by Upload (`Table[0]`), Detail (`Table[0]`), and List (`Table[*]`).
class VoiceReportItem {
  final String id;
  final String clientRecordId;
  final String userId;
  final int jobId;
  final String? formName;
  final String? machineName;
  final String? recordedAt;
  final String? uploadedAt;
  final double durationSec;
  final String? audioMime;
  final int? audioBytes;
  final String? platform;
  final String? appVersion;
  final int status;
  final String statusName;
  final String? errorMessage;
  final String? text;
  final String? textEngineType;
  final String? textModel;
  final String? audioUrl;

  // --- Summary Shortcut Fields (Channels ③ Cowork & ④ Human) ---
  final int coworkStatus;
  final String? coworkText;
  final String? coworkAt;
  final int humanStatus;
  final String? humanText;
  final String? humanBy;
  final String? humanAt;

  const VoiceReportItem({
    required this.id,
    required this.clientRecordId,
    required this.userId,
    required this.jobId,
    this.formName,
    this.machineName,
    this.recordedAt,
    this.uploadedAt,
    required this.durationSec,
    this.audioMime,
    this.audioBytes,
    this.platform,
    this.appVersion,
    required this.status,
    required this.statusName,
    this.errorMessage,
    this.text,
    this.textEngineType,
    this.textModel,
    this.audioUrl,
    this.coworkStatus = 0,
    this.coworkText,
    this.coworkAt,
    this.humanStatus = 0,
    this.humanText,
    this.humanBy,
    this.humanAt,
  });

  /// Poll only while status is 0 (รอถอดเสียง) or 1 (กำลังถอดเสียง). Stop on any other status.
  bool get shouldKeepPolling => status == 0 || status == 1;
  bool get isCompletedWithText => status == 2 || status == 3 || status == 4;
  bool get isSkipped => status == 8;
  bool get isFailed => status == 9;

  bool get hasCoworkSummary =>
      coworkStatus != 0 && coworkText != null && coworkText!.trim().isNotEmpty;
  bool get hasHumanSummary =>
      humanStatus != 0 && humanText != null && humanText!.trim().isNotEmpty;

  String resolveAudioUrl(String baseUrl) {
    final cleanBase = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (audioUrl != null && audioUrl!.trim().isNotEmpty) {
      final path = audioUrl!.trim().replaceFirst(RegExp(r'^/+'), '');
      return '$cleanBase/$path';
    }
    return '$cleanBase/CHECKSHEET_VOICE_AUDIO?id=$id';
  }

  factory VoiceReportItem.fromJson(Map<String, dynamic> json) {
    return VoiceReportItem(
      id: _vToStr(_vReadKey(json, 'id')),
      clientRecordId: _vToStr(_vReadKey(json, 'clientRecordId')),
      userId: _vToStr(_vReadKey(json, 'userId')),
      jobId: _vToInt(_vReadKey(json, 'jobId')),
      formName: _vToNullableStr(_vReadKey(json, 'formName')),
      machineName: _vToNullableStr(_vReadKey(json, 'machineName')),
      recordedAt: _vToNullableStr(_vReadKey(json, 'recordedAt')),
      uploadedAt: _vToNullableStr(_vReadKey(json, 'uploadedAt')),
      durationSec: _vToDouble(_vReadKey(json, 'durationSec')),
      audioMime: _vToNullableStr(_vReadKey(json, 'audioMime')),
      audioBytes: _vToNullableInt(_vReadKey(json, 'audioBytes')),
      platform: _vToNullableStr(_vReadKey(json, 'platform')),
      appVersion: _vToNullableStr(_vReadKey(json, 'appVersion')),
      status: _vToInt(_vReadKey(json, 'status')),
      statusName: _vToStr(_vReadKey(json, 'statusName')),
      errorMessage: _vToNullableStr(_vReadKey(json, 'errorMessage')),
      text: _vToNullableStr(_vReadKey(json, 'text')),
      textEngineType: _vToNullableStr(_vReadKey(json, 'textEngineType')),
      textModel: _vToNullableStr(_vReadKey(json, 'textModel')),
      audioUrl: _vToNullableStr(_vReadKey(json, 'audioUrl')),
      coworkStatus: _vToInt(_vReadKey(json, 'coworkStatus')),
      coworkText: _vToNullableStr(_vReadKey(json, 'coworkText')),
      coworkAt: _vToNullableStr(_vReadKey(json, 'coworkAt')),
      humanStatus: _vToInt(_vReadKey(json, 'humanStatus')),
      humanText: _vToNullableStr(_vReadKey(json, 'humanText')),
      humanBy: _vToNullableStr(_vReadKey(json, 'humanBy')),
      humanAt: _vToNullableStr(_vReadKey(json, 'humanAt')),
    );
  }
}

/// Detail -> Table1 (Engine result for Channels ① OpenAI & ② faster-whisper)
class VoiceEngineResult {
  final int engineId;
  final String engineType;
  final String model;
  final bool isPrimary;
  final bool engineEnabled;
  final int status; // 0 รอคิว, 1 กำลังถอด, 2 สำเร็จ, 8 ข้าม, 9 ล้มเหลว
  final String statusName;
  final int attempts;
  final String? text;
  final String? language;
  final double? audioSeconds;
  final double? costUsd;
  final int? latencyMs;
  final String? error;
  final String? createdAt;
  final String? completedAt;

  const VoiceEngineResult({
    required this.engineId,
    required this.engineType,
    required this.model,
    required this.isPrimary,
    required this.engineEnabled,
    required this.status,
    required this.statusName,
    this.attempts = 0,
    this.text,
    this.language,
    this.audioSeconds,
    this.costUsd,
    this.latencyMs,
    this.error,
    this.createdAt,
    this.completedAt,
  });

  bool get hasText => text != null && text!.trim().isNotEmpty;

  factory VoiceEngineResult.fromJson(Map<String, dynamic> json) {
    return VoiceEngineResult(
      engineId: _vToInt(_vReadKey(json, 'engineId')),
      engineType: _vToStr(_vReadKey(json, 'engineType')),
      model: _vToStr(_vReadKey(json, 'model')),
      isPrimary: _vToBool(_vReadKey(json, 'isPrimary')),
      engineEnabled: _vToBool(_vReadKey(json, 'engineEnabled'), fallback: true),
      status: _vToInt(_vReadKey(json, 'status')),
      statusName: _vToStr(_vReadKey(json, 'statusName')),
      attempts: _vToInt(_vReadKey(json, 'attempts')),
      text: _vToNullableStr(_vReadKey(json, 'text')),
      language: _vToNullableStr(_vReadKey(json, 'language')),
      audioSeconds: _vToNullableDouble(_vReadKey(json, 'audioSeconds')),
      costUsd: _vToNullableDouble(_vReadKey(json, 'costUsd')),
      latencyMs: _vToNullableInt(_vReadKey(json, 'latencyMs')),
      error: _vToNullableStr(_vReadKey(json, 'error')),
      createdAt: _vToNullableStr(_vReadKey(json, 'createdAt')),
      completedAt: _vToNullableStr(_vReadKey(json, 'completedAt')),
    );
  }
}

/// Detail -> Table2 (Summary slots for Channels ③ cowork & ④ human)
class VoiceSummarySlot {
  final String source; // 'cowork' or 'human'
  final String sourceName;
  final int status; // 0 = ยังไม่มีสรุป, 1 = มีสรุปแล้ว
  final String statusName;
  final String? text;
  final String? note;
  final String? model;
  final String? createdBy;
  final String? createdAt;
  final int versions;

  const VoiceSummarySlot({
    required this.source,
    required this.sourceName,
    required this.status,
    required this.statusName,
    this.text,
    this.note,
    this.model,
    this.createdBy,
    this.createdAt,
    this.versions = 0,
  });

  bool get hasSummary =>
      status != 0 && text != null && text!.trim().isNotEmpty;

  factory VoiceSummarySlot.fromJson(Map<String, dynamic> json) {
    return VoiceSummarySlot(
      source: _vToStr(_vReadKey(json, 'source')),
      sourceName: _vToStr(_vReadKey(json, 'sourceName')),
      status: _vToInt(_vReadKey(json, 'status')),
      statusName: _vToStr(_vReadKey(json, 'statusName')),
      text: _vToNullableStr(_vReadKey(json, 'text')),
      note: _vToNullableStr(_vReadKey(json, 'note')),
      model: _vToNullableStr(_vReadKey(json, 'model')),
      createdBy: _vToNullableStr(_vReadKey(json, 'createdBy')),
      createdAt: _vToNullableStr(_vReadKey(json, 'createdAt')),
      versions: _vToInt(_vReadKey(json, 'versions')),
    );
  }
}

/// Detail -> Table3 (Summary version history, newest to oldest)
class VoiceSummaryHistoryItem {
  final int summaryId;
  final String source;
  final String text;
  final String? note;
  final String? model;
  final String? createdBy;
  final String? createdAt;

  const VoiceSummaryHistoryItem({
    required this.summaryId,
    required this.source,
    required this.text,
    this.note,
    this.model,
    this.createdBy,
    this.createdAt,
  });

  factory VoiceSummaryHistoryItem.fromJson(Map<String, dynamic> json) {
    return VoiceSummaryHistoryItem(
      summaryId: _vToInt(_vReadKey(json, 'summaryId')),
      source: _vToStr(_vReadKey(json, 'source')),
      text: _vToStr(_vReadKey(json, 'text')),
      note: _vToNullableStr(_vReadKey(json, 'note')),
      model: _vToNullableStr(_vReadKey(json, 'model')),
      createdBy: _vToNullableStr(_vReadKey(json, 'createdBy')),
      createdAt: _vToNullableStr(_vReadKey(json, 'createdAt')),
    );
  }
}

/// Full 4-table payload returned by Detail, Upload, Retry, and SaveSummary.
/// Provides helpers for the 4 mandatory channels (① OpenAI, ② faster-whisper, ③ Cowork, ④ Human).
class VoiceReportDetail {
  final VoiceReportItem report; // Table[0]
  final List<VoiceEngineResult> engineResults; // Table1
  final List<VoiceSummarySlot> summaries; // Table2
  final List<VoiceSummaryHistoryItem> summaryHistory; // Table3

  const VoiceReportDetail({
    required this.report,
    this.engineResults = const [],
    this.summaries = const [],
    this.summaryHistory = const [],
  });

  /// Channel ①: OpenAI (primary engine, or first row with engineType == 'openai')
  VoiceEngineResult get openAiChannel {
    for (final e in engineResults) {
      if (e.engineType.toLowerCase() == 'openai' && e.isPrimary) return e;
    }
    for (final e in engineResults) {
      if (e.engineType.toLowerCase() == 'openai') return e;
    }
    return VoiceEngineResult(
      engineId: 1,
      engineType: 'openai',
      model: report.textModel ?? 'gpt-4o-mini-transcribe',
      isPrimary: true,
      engineEnabled: true,
      status: report.status,
      statusName: report.statusName.isNotEmpty ? report.statusName : 'รอคิว',
      text: report.textEngineType?.toLowerCase() == 'openai'
          ? report.text
          : null,
      error: report.errorMessage,
    );
  }

  /// Channel ②: faster-whisper (row with engineType == 'faster-whisper')
  VoiceEngineResult get fasterWhisperChannel {
    for (final e in engineResults) {
      if (e.engineType.toLowerCase() == 'faster-whisper') return e;
    }
    return const VoiceEngineResult(
      engineId: 3,
      engineType: 'faster-whisper',
      model: 'medium',
      isPrimary: false,
      engineEnabled: true,
      status: 0,
      statusName: 'รอคิว',
    );
  }

  /// Channel ③: สรุปโดย Cowork (always returned in Table2 with source == 'cowork')
  VoiceSummarySlot get coworkChannel {
    for (final s in summaries) {
      if (s.source.toLowerCase() == 'cowork') return s;
    }
    return VoiceSummarySlot(
      source: 'cowork',
      sourceName: 'สรุปโดย Cowork',
      status: report.coworkStatus,
      statusName: report.coworkStatus == 0 ? 'ยังไม่มีสรุป' : 'มีสรุปแล้ว',
      text: report.coworkText,
      createdAt: report.coworkAt,
    );
  }

  /// Channel ④: สรุปโดยคน (always returned in Table2 with source == 'human')
  VoiceSummarySlot get humanChannel {
    for (final s in summaries) {
      if (s.source.toLowerCase() == 'human') return s;
    }
    return VoiceSummarySlot(
      source: 'human',
      sourceName: 'สรุปโดยคน',
      status: report.humanStatus,
      statusName: report.humanStatus == 0 ? 'ยังไม่มีสรุป' : 'มีสรุปแล้ว',
      text: report.humanText,
      createdBy: report.humanBy,
      createdAt: report.humanAt,
    );
  }
}

/// Offline queue entry persisted locally until HTTP 200 is received (Section 4.3).
/// [clientRecordId] is created ONCE per recording and reused across all retries.
class VoiceQueuedRecord {
  final String clientRecordId;
  final String userId;
  final int jobId;
  final String? jobLabel;
  final String recordedAtIso;
  final double durationSec;
  final String platform;
  final String? appVersion;
  final String? filePath;
  final String mimeType;
  final String fileName;
  final int attempts;
  final String? lastError;
  final bool isRejected400;
  final int? nextRetryAtMs;

  const VoiceQueuedRecord({
    required this.clientRecordId,
    required this.userId,
    required this.jobId,
    this.jobLabel,
    required this.recordedAtIso,
    required this.durationSec,
    required this.platform,
    this.appVersion,
    this.filePath,
    required this.mimeType,
    required this.fileName,
    this.attempts = 0,
    this.lastError,
    this.isRejected400 = false,
    this.nextRetryAtMs,
  });

  /// Exponential backoff delays: 10s, 30s, 60s, 300s (5m).
  static Duration backoffForAttempt(int attempt) {
    if (attempt <= 1) return const Duration(seconds: 10);
    if (attempt == 2) return const Duration(seconds: 30);
    if (attempt == 3) return const Duration(minutes: 1);
    return const Duration(minutes: 5);
  }

  VoiceQueuedRecord copyWith({
    int? jobId,
    String? jobLabel,
    int? attempts,
    String? lastError,
    bool? isRejected400,
    int? nextRetryAtMs,
    bool clearNextRetry = false,
  }) {
    return VoiceQueuedRecord(
      clientRecordId: clientRecordId,
      userId: userId,
      jobId: jobId ?? this.jobId,
      jobLabel: jobLabel ?? this.jobLabel,
      recordedAtIso: recordedAtIso,
      durationSec: durationSec,
      platform: platform,
      appVersion: appVersion,
      filePath: filePath,
      mimeType: mimeType,
      fileName: fileName,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      isRejected400: isRejected400 ?? this.isRejected400,
      nextRetryAtMs:
          clearNextRetry ? null : (nextRetryAtMs ?? this.nextRetryAtMs),
    );
  }

  Map<String, dynamic> toJson() => {
        'clientRecordId': clientRecordId,
        'userId': userId,
        'jobId': jobId,
        'jobLabel': jobLabel,
        'recordedAtIso': recordedAtIso,
        'durationSec': durationSec,
        'platform': platform,
        'appVersion': appVersion,
        'filePath': filePath,
        'mimeType': mimeType,
        'fileName': fileName,
        'attempts': attempts,
        'lastError': lastError,
        'isRejected400': isRejected400,
        'nextRetryAtMs': nextRetryAtMs,
      };

  factory VoiceQueuedRecord.fromJson(Map<String, dynamic> json) {
    return VoiceQueuedRecord(
      clientRecordId: _vToStr(json['clientRecordId']),
      userId: _vToStr(json['userId']),
      jobId: _vToInt(json['jobId']),
      jobLabel: _vToNullableStr(json['jobLabel']),
      recordedAtIso: _vToStr(json['recordedAtIso']),
      durationSec: _vToDouble(json['durationSec']),
      platform: _vToStr(json['platform']),
      appVersion: _vToNullableStr(json['appVersion']),
      filePath: _vToNullableStr(json['filePath']),
      mimeType: _vToStr(json['mimeType']).isEmpty
          ? 'audio/mp4'
          : _vToStr(json['mimeType']),
      fileName: _vToStr(json['fileName']).isEmpty
          ? 'voice.m4a'
          : _vToStr(json['fileName']),
      attempts: _vToInt(json['attempts']),
      lastError: _vToNullableStr(json['lastError']),
      isRejected400: _vToBool(json['isRejected400']),
      nextRetryAtMs: _vToNullableInt(json['nextRetryAtMs']),
    );
  }
}
