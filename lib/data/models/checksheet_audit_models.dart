// lib/data/models/checksheet_audit_models.dart

/// Case-insensitive JSON lookup helpers for SQL DataTable serialization.
dynamic _auditReadKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return null;
}

int _auditToInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? fallback;
}

String _auditToStr(dynamic value) => value?.toString() ?? '';

String? _auditToNullableStr(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

/// Option item with live document count for cross-filtering dropdowns.
class AuditFilterOption {
  final String value;
  final int count;

  const AuditFilterOption({required this.value, required this.count});
}

/// Row from GET /CHECKSHEET_AUDIT/api/documents -> rows[]
class AuditDocumentRow {
  final String documentId;
  final int jobId;
  final String? createDate;
  final String? lastSync;
  final String formName;
  final String machineName;
  final String location;
  final String phases;
  final String lot;
  final String createUser;
  final int itemCount;
  final int normalCount;
  final int abnormalCount;
  final int outOfSpecCount;
  final int unreadableCount;
  final int blankCount;
  final int verifiedCount;
  final int caseCount;
  final int openCaseCount;
  final int unfinishedCount;
  final String? supervisorUser;
  final String? supervisorCheck;

  const AuditDocumentRow({
    required this.documentId,
    required this.jobId,
    this.createDate,
    this.lastSync,
    required this.formName,
    required this.machineName,
    required this.location,
    required this.phases,
    required this.lot,
    required this.createUser,
    required this.itemCount,
    required this.normalCount,
    required this.abnormalCount,
    required this.outOfSpecCount,
    required this.unreadableCount,
    required this.blankCount,
    required this.verifiedCount,
    required this.caseCount,
    required this.openCaseCount,
    required this.unfinishedCount,
    this.supervisorUser,
    this.supervisorCheck,
  });

  int get issueCount => abnormalCount + outOfSpecCount;

  bool get isFinished => unfinishedCount <= 0;

  /// Splits comma-separated phases just like JS: key(d.phases).split(', ')
  List<String> get phaseList {
    final trimmed = phases.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed
        .split(', ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory AuditDocumentRow.fromJson(Map<String, dynamic> json) {
    return AuditDocumentRow(
      documentId: _auditToStr(_auditReadKey(json, 'documentId')),
      jobId: _auditToInt(_auditReadKey(json, 'jobId')),
      createDate: _auditToNullableStr(_auditReadKey(json, 'createDate')),
      lastSync: _auditToNullableStr(_auditReadKey(json, 'lastSync')),
      formName: _auditToStr(_auditReadKey(json, 'formName')),
      machineName: _auditToStr(_auditReadKey(json, 'machineName')),
      location: _auditToStr(_auditReadKey(json, 'location')),
      phases: _auditToStr(_auditReadKey(json, 'phases')),
      lot: _auditToStr(_auditReadKey(json, 'lot')),
      createUser: _auditToStr(_auditReadKey(json, 'createUser')),
      itemCount: _auditToInt(_auditReadKey(json, 'itemCount')),
      normalCount: _auditToInt(_auditReadKey(json, 'normalCount')),
      abnormalCount: _auditToInt(_auditReadKey(json, 'abnormalCount')),
      outOfSpecCount: _auditToInt(_auditReadKey(json, 'outOfSpecCount')),
      unreadableCount: _auditToInt(_auditReadKey(json, 'unreadableCount')),
      blankCount: _auditToInt(_auditReadKey(json, 'blankCount')),
      verifiedCount: _auditToInt(_auditReadKey(json, 'verifiedCount')),
      caseCount: _auditToInt(_auditReadKey(json, 'caseCount')),
      openCaseCount: _auditToInt(_auditReadKey(json, 'openCaseCount')),
      unfinishedCount: _auditToInt(_auditReadKey(json, 'unfinishedCount')),
      supervisorUser:
          _auditToNullableStr(_auditReadKey(json, 'supervisorUser')),
      supervisorCheck:
          _auditToNullableStr(_auditReadKey(json, 'supervisorCheck')),
    );
  }
}

/// Row from GET /CHECKSHEET_AUDIT/api/detail -> items[]
class AuditCheckItem {
  final String recordTagId;
  final String phaseId;
  final String phaseName;
  final String groupName;
  final String tagName;
  final String tagType;
  final String? description;
  final String? specification;
  final String? specMin;
  final String? specMax;
  final String? unit;
  final String? value;
  final String result;
  final String? remark;

  const AuditCheckItem({
    required this.recordTagId,
    required this.phaseId,
    required this.phaseName,
    required this.groupName,
    required this.tagName,
    required this.tagType,
    this.description,
    this.specification,
    this.specMin,
    this.specMax,
    this.unit,
    this.value,
    required this.result,
    this.remark,
  });

  String get formattedSpec {
    final mn = specMin?.trim() ?? '';
    final mx = specMax?.trim() ?? '';
    final u = (unit != null && unit!.trim().isNotEmpty) ? ' ${unit!.trim()}' : '';
    if (mn.isNotEmpty && mx.isNotEmpty) return '$mn – $mx$u';
    if (mn.isNotEmpty) return '≥ $mn$u';
    if (mx.isNotEmpty) return '≤ $mx$u';
    return '';
  }

  factory AuditCheckItem.fromJson(Map<String, dynamic> json) {
    return AuditCheckItem(
      recordTagId: _auditToStr(_auditReadKey(json, 'recordTagId')),
      phaseId: _auditToStr(_auditReadKey(json, 'phaseId')),
      phaseName: _auditToStr(_auditReadKey(json, 'phaseName')),
      groupName: _auditToStr(_auditReadKey(json, 'groupName')),
      tagName: _auditToStr(_auditReadKey(json, 'tagName')),
      tagType: _auditToStr(_auditReadKey(json, 'tagType')),
      description: _auditToNullableStr(_auditReadKey(json, 'description')),
      specification: _auditToNullableStr(_auditReadKey(json, 'specification')),
      specMin: _auditToNullableStr(_auditReadKey(json, 'specMin')),
      specMax: _auditToNullableStr(_auditReadKey(json, 'specMax')),
      unit: _auditToNullableStr(_auditReadKey(json, 'unit')),
      value: _auditToNullableStr(_auditReadKey(json, 'value')),
      result: _auditToStr(_auditReadKey(json, 'result')),
      remark: _auditToNullableStr(_auditReadKey(json, 'remark')),
    );
  }
}

/// Row from GET /CHECKSHEET_AUDIT/api/detail -> verifies[]
class AuditVerifyEntry {
  final String recordTagId;
  final String verifyTypeName;
  final String verifyBy;
  final String? verifyDate;
  final String? remark;

  const AuditVerifyEntry({
    required this.recordTagId,
    required this.verifyTypeName,
    required this.verifyBy,
    this.verifyDate,
    this.remark,
  });

  factory AuditVerifyEntry.fromJson(Map<String, dynamic> json) {
    return AuditVerifyEntry(
      recordTagId: _auditToStr(_auditReadKey(json, 'recordTagId')),
      verifyTypeName: _auditToStr(_auditReadKey(json, 'verifyTypeName')),
      verifyBy: _auditToStr(_auditReadKey(json, 'verifyBy')),
      verifyDate: _auditToNullableStr(_auditReadKey(json, 'verifyDate')),
      remark: _auditToNullableStr(_auditReadKey(json, 'remark')),
    );
  }
}

/// Row from GET /CHECKSHEET_AUDIT/api/detail -> cases[]
class AuditCaseEntry {
  final String recordTagId;
  final String problemId;
  final int status;
  final String createUser;
  final String? createDate;
  final String? closeUser;
  final String? closeDate;
  final String? solvingDescription;

  const AuditCaseEntry({
    required this.recordTagId,
    required this.problemId,
    required this.status,
    required this.createUser,
    this.createDate,
    this.closeUser,
    this.closeDate,
    this.solvingDescription,
  });

  bool get isOpen => status == 0;

  factory AuditCaseEntry.fromJson(Map<String, dynamic> json) {
    return AuditCaseEntry(
      recordTagId: _auditToStr(_auditReadKey(json, 'recordTagId')),
      problemId: _auditToStr(_auditReadKey(json, 'problemId')),
      status: _auditToInt(_auditReadKey(json, 'status')),
      createUser: _auditToStr(_auditReadKey(json, 'createUser')),
      createDate: _auditToNullableStr(_auditReadKey(json, 'createDate')),
      closeUser: _auditToNullableStr(_auditReadKey(json, 'closeUser')),
      closeDate: _auditToNullableStr(_auditReadKey(json, 'closeDate')),
      solvingDescription:
          _auditToNullableStr(_auditReadKey(json, 'solvingDescription')),
    );
  }
}

/// Row from GET /CHECKSHEET_AUDIT/api/detail -> supervisorChecks[]
class AuditSupervisorCheck {
  final String phaseName;
  final String userId;
  final String? checkDateTime;
  final String? comment;

  const AuditSupervisorCheck({
    required this.phaseName,
    required this.userId,
    this.checkDateTime,
    this.comment,
  });

  factory AuditSupervisorCheck.fromJson(Map<String, dynamic> json) {
    return AuditSupervisorCheck(
      phaseName: _auditToStr(_auditReadKey(json, 'phaseName')),
      userId: _auditToStr(_auditReadKey(json, 'userId')),
      checkDateTime: _auditToNullableStr(_auditReadKey(json, 'checkDateTime')),
      comment: _auditToNullableStr(_auditReadKey(json, 'comment')),
    );
  }
}

/// Container for full detail payload of a single document.
class AuditDocumentDetail {
  final List<AuditCheckItem> items;
  final List<AuditVerifyEntry> verifies;
  final List<AuditCaseEntry> cases;
  final List<AuditSupervisorCheck> supervisorChecks;

  const AuditDocumentDetail({
    required this.items,
    required this.verifies,
    required this.cases,
    required this.supervisorChecks,
  });

  Map<String, List<AuditVerifyEntry>> get verifiesByRecordTagId {
    final map = <String, List<AuditVerifyEntry>>{};
    for (final v in verifies) {
      map.putIfAbsent(v.recordTagId, () => []).add(v);
    }
    return map;
  }

  Map<String, List<AuditCaseEntry>> get casesByRecordTagId {
    final map = <String, List<AuditCaseEntry>>{};
    for (final c in cases) {
      map.putIfAbsent(c.recordTagId, () => []).add(c);
    }
    return map;
  }
}
