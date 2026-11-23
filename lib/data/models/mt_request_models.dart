// lib/data/models/mt_request_models.dart

/// Exception returned by CHECKSHEET_MT_REQUEST API (400 / 404 / 500).
class MtRequestApiException implements Exception {
  final int httpStatus;
  final int? code;
  final String message;

  const MtRequestApiException({
    required this.httpStatus,
    this.code,
    required this.message,
  });

  bool get shouldReload => httpStatus == 400 || httpStatus == 404;

  @override
  String toString() => message;
}

dynamic _mtReadKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return null;
}

int _mtToInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? fallback;
}

int? _mtToNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

bool _mtToBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

bool? _mtToNullableBool(dynamic v) {
  if (v == null) return null;
  return _mtToBool(v);
}

String _mtToStr(dynamic v) => v?.toString() ?? '';

String? _mtToNullableStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/// From Lookups -> Table
class MtRequestStatusLookup {
  final int id;
  final String name;

  const MtRequestStatusLookup({required this.id, required this.name});

  factory MtRequestStatusLookup.fromJson(Map<String, dynamic> json) {
    return MtRequestStatusLookup(
      id: _mtToInt(_mtReadKey(json, 'id')),
      name: _mtToStr(_mtReadKey(json, 'name')),
    );
  }
}

/// From Lookups -> Table1
class MtRequestResultLookup {
  final int id;
  final String name;
  final bool defaultCloseCase;

  const MtRequestResultLookup({
    required this.id,
    required this.name,
    required this.defaultCloseCase,
  });

  factory MtRequestResultLookup.fromJson(Map<String, dynamic> json) {
    return MtRequestResultLookup(
      id: _mtToInt(_mtReadKey(json, 'id')),
      name: _mtToStr(_mtReadKey(json, 'name')),
      defaultCloseCase: _mtToBool(_mtReadKey(json, 'defaultCloseCase')),
    );
  }
}

class MtRequestLookups {
  final List<MtRequestStatusLookup> statuses;
  final List<MtRequestResultLookup> results;

  const MtRequestLookups({
    required this.statuses,
    required this.results,
  });

  String statusNameFor(int status, {String? fallback}) {
    for (final s in statuses) {
      if (s.id == status) return s.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    switch (status) {
      case 0:
        return 'ร่าง';
      case 1:
        return 'ส่ง MT แล้ว';
      case 2:
        return 'ปิดงาน';
      case 3:
        return 'ยกเลิก';
      default:
        return 'สถานะ $status';
    }
  }
}

/// Row from CaseList -> Table
class MtCaseListItem {
  final int problemId;
  final int jobId;
  final String formName;
  final String machineName;
  final String documentId;
  final String documentName;
  final int? phaseId;
  final String phaseName;
  final String tagName;
  final String value;
  final String? description;
  final int status; // 0 = open, 1 = closed
  final String? createDate;
  final String? createUser;
  final String? closeDate;
  final String? closeUser;
  final String? solvingDescription;
  final int? activeMTRequestId;
  final String? activeRequestNo;
  final int requestCount;

  const MtCaseListItem({
    required this.problemId,
    required this.jobId,
    required this.formName,
    required this.machineName,
    required this.documentId,
    required this.documentName,
    this.phaseId,
    required this.phaseName,
    required this.tagName,
    required this.value,
    this.description,
    required this.status,
    this.createDate,
    this.createUser,
    this.closeDate,
    this.closeUser,
    this.solvingDescription,
    this.activeMTRequestId,
    this.activeRequestNo,
    required this.requestCount,
  });

  bool get isOpen => status == 0;
  bool get isInActiveRequest => activeMTRequestId != null;
  bool get canSelectForNewRequest => isOpen && !isInActiveRequest;

  factory MtCaseListItem.fromJson(Map<String, dynamic> json) {
    return MtCaseListItem(
      problemId: _mtToInt(_mtReadKey(json, 'problemId')),
      jobId: _mtToInt(_mtReadKey(json, 'jobId')),
      formName: _mtToStr(_mtReadKey(json, 'formName')),
      machineName: _mtToStr(_mtReadKey(json, 'machineName')),
      documentId: _mtToStr(_mtReadKey(json, 'documentId')),
      documentName: _mtToStr(_mtReadKey(json, 'documentName')),
      phaseId: _mtToNullableInt(_mtReadKey(json, 'phaseId')),
      phaseName: _mtToStr(_mtReadKey(json, 'phaseName')),
      tagName: _mtToStr(_mtReadKey(json, 'tagName')),
      value: _mtToStr(_mtReadKey(json, 'value')),
      description: _mtToNullableStr(_mtReadKey(json, 'description')),
      status: _mtToInt(_mtReadKey(json, 'status')),
      createDate: _mtToNullableStr(_mtReadKey(json, 'createDate')),
      createUser: _mtToNullableStr(_mtReadKey(json, 'createUser')),
      closeDate: _mtToNullableStr(_mtReadKey(json, 'closeDate')),
      closeUser: _mtToNullableStr(_mtReadKey(json, 'closeUser')),
      solvingDescription:
          _mtToNullableStr(_mtReadKey(json, 'solvingDescription')),
      activeMTRequestId:
          _mtToNullableInt(_mtReadKey(json, 'activeMTRequestId')),
      activeRequestNo: _mtToNullableStr(_mtReadKey(json, 'activeRequestNo')),
      requestCount: _mtToInt(_mtReadKey(json, 'requestCount')),
    );
  }
}

/// Row from List -> Table
class MtRequestListItem {
  final int id;
  final int jobId;
  final String formName;
  final String machineName;
  final String? description;
  final String? requestNo;
  final int status;
  final String statusName;
  final String? createUser;
  final String? createDate;
  final String? sentUser;
  final String? sentDate;
  final String? closeUser;
  final String? closeDate;
  final String? closeNote;
  final int caseCount;
  final int closedCaseCount;

  const MtRequestListItem({
    required this.id,
    required this.jobId,
    required this.formName,
    required this.machineName,
    this.description,
    this.requestNo,
    required this.status,
    required this.statusName,
    this.createUser,
    this.createDate,
    this.sentUser,
    this.sentDate,
    this.closeUser,
    this.closeDate,
    this.closeNote,
    required this.caseCount,
    required this.closedCaseCount,
  });

  factory MtRequestListItem.fromJson(Map<String, dynamic> json) {
    return MtRequestListItem(
      id: _mtToInt(_mtReadKey(json, 'id')),
      jobId: _mtToInt(_mtReadKey(json, 'jobId')),
      formName: _mtToStr(_mtReadKey(json, 'formName')),
      machineName: _mtToStr(_mtReadKey(json, 'machineName')),
      description: _mtToNullableStr(_mtReadKey(json, 'description')),
      requestNo: _mtToNullableStr(_mtReadKey(json, 'requestNo')),
      status: _mtToInt(_mtReadKey(json, 'status')),
      statusName: _mtToStr(_mtReadKey(json, 'statusName')),
      createUser: _mtToNullableStr(_mtReadKey(json, 'createUser')),
      createDate: _mtToNullableStr(_mtReadKey(json, 'createDate')),
      sentUser: _mtToNullableStr(_mtReadKey(json, 'sentUser')),
      sentDate: _mtToNullableStr(_mtReadKey(json, 'sentDate')),
      closeUser: _mtToNullableStr(_mtReadKey(json, 'closeUser')),
      closeDate: _mtToNullableStr(_mtReadKey(json, 'closeDate')),
      closeNote: _mtToNullableStr(_mtReadKey(json, 'closeNote')),
      caseCount: _mtToInt(_mtReadKey(json, 'caseCount')),
      closedCaseCount: _mtToInt(_mtReadKey(json, 'closedCaseCount')),
    );
  }
}

/// Header row from Detail (and write commands) -> Table[0]
class MtRequestHeader {
  final int id;
  final int jobId;
  final String formName;
  final String machineName;
  final String? location;
  final String? description;
  final String? requestNo;
  final int status;
  final String statusName;
  final String? createUser;
  final String? createDate;
  final String? updateUser;
  final String? updateDate;
  final String? sentUser;
  final String? sentDate;
  final String? closeUser;
  final String? closeDate;
  final String? closeNote;

  const MtRequestHeader({
    required this.id,
    required this.jobId,
    required this.formName,
    required this.machineName,
    this.location,
    this.description,
    this.requestNo,
    required this.status,
    required this.statusName,
    this.createUser,
    this.createDate,
    this.updateUser,
    this.updateDate,
    this.sentUser,
    this.sentDate,
    this.closeUser,
    this.closeDate,
    this.closeNote,
  });

  bool get isDraft => status == 0;
  bool get isSentToMt => status == 1;
  bool get isClosed => status == 2;
  bool get isCancelled => status == 3;
  bool get isEditable => isDraft || isSentToMt;

  factory MtRequestHeader.fromJson(Map<String, dynamic> json) {
    return MtRequestHeader(
      id: _mtToInt(_mtReadKey(json, 'id')),
      jobId: _mtToInt(_mtReadKey(json, 'jobId')),
      formName: _mtToStr(_mtReadKey(json, 'formName')),
      machineName: _mtToStr(_mtReadKey(json, 'machineName')),
      location: _mtToNullableStr(_mtReadKey(json, 'location')),
      description: _mtToNullableStr(_mtReadKey(json, 'description')),
      requestNo: _mtToNullableStr(_mtReadKey(json, 'requestNo')),
      status: _mtToInt(_mtReadKey(json, 'status')),
      statusName: _mtToStr(_mtReadKey(json, 'statusName')),
      createUser: _mtToNullableStr(_mtReadKey(json, 'createUser')),
      createDate: _mtToNullableStr(_mtReadKey(json, 'createDate')),
      updateUser: _mtToNullableStr(_mtReadKey(json, 'updateUser')),
      updateDate: _mtToNullableStr(_mtReadKey(json, 'updateDate')),
      sentUser: _mtToNullableStr(_mtReadKey(json, 'sentUser')),
      sentDate: _mtToNullableStr(_mtReadKey(json, 'sentDate')),
      closeUser: _mtToNullableStr(_mtReadKey(json, 'closeUser')),
      closeDate: _mtToNullableStr(_mtReadKey(json, 'closeDate')),
      closeNote: _mtToNullableStr(_mtReadKey(json, 'closeNote')),
    );
  }
}

/// Case item row from Detail (and write commands) -> Table1
class MtRequestCaseItem {
  final int problemId;
  final String documentId;
  final String documentName;
  final int? phaseId;
  final String phaseName;
  final String tagName;
  final String value;
  final String? description;
  final String? caseCreateDate;
  final String? caseCreateUser;
  final int caseStatus; // current status: 0 open, 1 closed
  final String? caseCloseDate;
  final String? caseCloseUser;
  final String? addUser;
  final String? addDate;
  final int? result;
  final String? resultName;
  final String? resultNote;
  final bool? caseClosed;
  final String? otherRequests;

  const MtRequestCaseItem({
    required this.problemId,
    required this.documentId,
    required this.documentName,
    this.phaseId,
    required this.phaseName,
    required this.tagName,
    required this.value,
    this.description,
    this.caseCreateDate,
    this.caseCreateUser,
    required this.caseStatus,
    this.caseCloseDate,
    this.caseCloseUser,
    this.addUser,
    this.addDate,
    this.result,
    this.resultName,
    this.resultNote,
    this.caseClosed,
    this.otherRequests,
  });

  factory MtRequestCaseItem.fromJson(Map<String, dynamic> json) {
    return MtRequestCaseItem(
      problemId: _mtToInt(_mtReadKey(json, 'problemId')),
      documentId: _mtToStr(_mtReadKey(json, 'documentId')),
      documentName: _mtToStr(_mtReadKey(json, 'documentName')),
      phaseId: _mtToNullableInt(_mtReadKey(json, 'phaseId')),
      phaseName: _mtToStr(_mtReadKey(json, 'phaseName')),
      tagName: _mtToStr(_mtReadKey(json, 'tagName')),
      value: _mtToStr(_mtReadKey(json, 'value')),
      description: _mtToNullableStr(_mtReadKey(json, 'description')),
      caseCreateDate: _mtToNullableStr(_mtReadKey(json, 'caseCreateDate')),
      caseCreateUser: _mtToNullableStr(_mtReadKey(json, 'caseCreateUser')),
      caseStatus: _mtToInt(_mtReadKey(json, 'caseStatus')),
      caseCloseDate: _mtToNullableStr(_mtReadKey(json, 'caseCloseDate')),
      caseCloseUser: _mtToNullableStr(_mtReadKey(json, 'caseCloseUser')),
      addUser: _mtToNullableStr(_mtReadKey(json, 'addUser')),
      addDate: _mtToNullableStr(_mtReadKey(json, 'addDate')),
      result: _mtToNullableInt(_mtReadKey(json, 'result')),
      resultName: _mtToNullableStr(_mtReadKey(json, 'resultName')),
      resultNote: _mtToNullableStr(_mtReadKey(json, 'resultNote')),
      caseClosed: _mtToNullableBool(_mtReadKey(json, 'caseClosed')),
      otherRequests: _mtToNullableStr(_mtReadKey(json, 'otherRequests')),
    );
  }
}

/// Complete detail payload for 1 MT Request.
class MtRequestDetail {
  final MtRequestHeader header;
  final List<MtRequestCaseItem> cases;

  const MtRequestDetail({
    required this.header,
    required this.cases,
  });
}

/// Input row for Close command -> results[]
class MtCloseCaseInput {
  final int problemId;
  final int result;
  final String? note;
  final bool closeCase;

  const MtCloseCaseInput({
    required this.problemId,
    required this.result,
    this.note,
    required this.closeCase,
  });

  Map<String, dynamic> toJson() {
    final trimmedNote = note?.trim();
    return {
      'problemId': problemId,
      'result': result,
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      'closeCase': closeCase,
    };
  }
}
