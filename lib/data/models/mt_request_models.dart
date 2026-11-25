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

  /// Reload on stale/rule errors (400/404), except non-stale input/search/MT-temp errors.
  bool get shouldReload =>
      (httpStatus == 400 || httpStatus == 404) &&
      code != 50038 &&
      code != 50062 &&
      code != 50063 &&
      code != 50070 &&
      code != 50071;

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

/// Formats a local DateTime as `yyyy-MM-ddTHH:mm` (Thai local time, NO `Z` suffix).
String formatMtLocalDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return '$y-$mo-${d}T$h:$mi';
}

/// Simple { id, name } lookup row used by Table (statuses), Table2 (statusEquiType), Table3 (planImpact).
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

/// From Lookups -> Table4 (requestJobType)
class MtRequestJobTypeLookup {
  final int id;
  final String name;
  final String? nameEn;

  const MtRequestJobTypeLookup({
    required this.id,
    required this.name,
    this.nameEn,
  });

  String get displayLabel =>
      (nameEn != null && nameEn!.isNotEmpty) ? '$name ($nameEn)' : name;

  factory MtRequestJobTypeLookup.fromJson(Map<String, dynamic> json) {
    return MtRequestJobTypeLookup(
      id: _mtToInt(_mtReadKey(json, 'id')),
      name: _mtToStr(_mtReadKey(json, 'name')),
      nameEn: _mtToNullableStr(_mtReadKey(json, 'nameEn')),
    );
  }
}

/// From Lookups -> Table5 (departments: preserve leading zeros in [code], e.g. "052")
class MtDepartmentLookup {
  final String code;
  final String name;
  final String? description;

  const MtDepartmentLookup({
    required this.code,
    required this.name,
    this.description,
  });

  String get displayLabel {
    final desc = (description != null && description!.isNotEmpty)
        ? ' - $description'
        : '';
    return '$code · $name$desc';
  }

  factory MtDepartmentLookup.fromJson(Map<String, dynamic> json) {
    return MtDepartmentLookup(
      code: _mtToStr(_mtReadKey(json, 'code')),
      name: _mtToStr(_mtReadKey(json, 'name')),
      description: _mtToNullableStr(_mtReadKey(json, 'description')),
    );
  }
}

/// From Lookups -> Table6 (qualityIssueType)
class MtQualityIssueTypeLookup {
  final int id;
  final String name;
  final String? description;

  const MtQualityIssueTypeLookup({
    required this.id,
    required this.name,
    this.description,
  });

  String get displayLabel => (description != null && description!.isNotEmpty)
      ? '$name ($description)'
      : name;

  factory MtQualityIssueTypeLookup.fromJson(Map<String, dynamic> json) {
    return MtQualityIssueTypeLookup(
      id: _mtToInt(_mtReadKey(json, 'id')),
      name: _mtToStr(_mtReadKey(json, 'name')),
      description: _mtToNullableStr(_mtReadKey(json, 'description')),
    );
  }
}

/// Row from EmployeeSearch -> Table
class MtEmployeeSearchItem {
  final String employeeId;
  final String employeeName;
  final String? positionName;
  final String? departmentCode;
  final String? departmentName;
  final String? email;
  final String? adUser;
  final bool active;

  const MtEmployeeSearchItem({
    required this.employeeId,
    required this.employeeName,
    this.positionName,
    this.departmentCode,
    this.departmentName,
    this.email,
    this.adUser,
    this.active = true,
  });

  factory MtEmployeeSearchItem.fromJson(Map<String, dynamic> json) {
    return MtEmployeeSearchItem(
      employeeId: _mtToStr(_mtReadKey(json, 'employeeId')),
      employeeName: _mtToStr(_mtReadKey(json, 'employeeName')),
      positionName: _mtToNullableStr(_mtReadKey(json, 'positionName')),
      departmentCode: _mtToNullableStr(_mtReadKey(json, 'departmentCode')),
      departmentName: _mtToNullableStr(_mtReadKey(json, 'departmentName')),
      email: _mtToNullableStr(_mtReadKey(json, 'email')),
      adUser: _mtToNullableStr(_mtReadKey(json, 'adUser')),
      active: _mtToBool(_mtReadKey(json, 'active'), fallback: true),
    );
  }
}

/// Row from EquipmentSearch -> Table
class MtEquipmentSearchItem {
  final String equipmentId;
  final String equipmentName;
  final String? equipmentName2;
  final String? model;
  final String? assetNo;
  final String? serialNo;

  const MtEquipmentSearchItem({
    required this.equipmentId,
    required this.equipmentName,
    this.equipmentName2,
    this.model,
    this.assetNo,
    this.serialNo,
  });

  factory MtEquipmentSearchItem.fromJson(Map<String, dynamic> json) {
    return MtEquipmentSearchItem(
      equipmentId: _mtToStr(_mtReadKey(json, 'equipmentId')),
      equipmentName: _mtToStr(_mtReadKey(json, 'equipmentName')),
      equipmentName2: _mtToNullableStr(_mtReadKey(json, 'equipmentName2')),
      model: _mtToNullableStr(_mtReadKey(json, 'model')),
      assetNo: _mtToNullableStr(_mtReadKey(json, 'assetNo')),
      serialNo: _mtToNullableStr(_mtReadKey(json, 'serialNo')),
    );
  }
}

/// Row from DeviationSearch -> Table
class MtDeviationSearchItem {
  final int? systemId;
  final String? systemName;
  final String deviationNo;
  final String? deviationDate;
  final String? heading;
  final String? ownerDepartment;
  final String? statusName;

  const MtDeviationSearchItem({
    this.systemId,
    this.systemName,
    required this.deviationNo,
    this.deviationDate,
    this.heading,
    this.ownerDepartment,
    this.statusName,
  });

  factory MtDeviationSearchItem.fromJson(Map<String, dynamic> json) {
    return MtDeviationSearchItem(
      systemId: _mtToNullableInt(_mtReadKey(json, 'systemId')),
      systemName: _mtToNullableStr(_mtReadKey(json, 'systemName')),
      deviationNo: _mtToStr(_mtReadKey(json, 'deviationNo')),
      deviationDate: _mtToNullableStr(_mtReadKey(json, 'deviationDate')),
      heading: _mtToNullableStr(_mtReadKey(json, 'heading')),
      ownerDepartment: _mtToNullableStr(_mtReadKey(json, 'ownerDepartment')),
      statusName: _mtToNullableStr(_mtReadKey(json, 'statusName')),
    );
  }
}

class MtRequestLookups {
  final List<MtRequestStatusLookup> statuses; // Table
  final List<MtRequestResultLookup> results; // Table1
  final List<MtRequestStatusLookup> statusEquiTypes; // Table2
  final List<MtRequestStatusLookup> planImpacts; // Table3
  final List<MtRequestJobTypeLookup> requestJobTypes; // Table4
  final List<MtDepartmentLookup> departments; // Table5
  final List<MtQualityIssueTypeLookup> qualityIssueTypes; // Table6

  const MtRequestLookups({
    required this.statuses,
    required this.results,
    this.statusEquiTypes = const [],
    this.planImpacts = const [],
    this.requestJobTypes = const [],
    this.departments = const [],
    this.qualityIssueTypes = const [],
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

  String statusEquiTypeNameFor(int? id) {
    if (id == null) return '–';
    for (final item in statusEquiTypes) {
      if (item.id == id) return item.name;
    }
    return id == 0
        ? 'Break Down เครื่องเสีย'
        : id == 1
            ? 'Near Fail เครื่องใกล้เสีย'
            : '$id';
  }

  String planImpactNameFor(int? id) {
    if (id == null) return '–';
    for (final item in planImpacts) {
      if (item.id == id) return item.name;
    }
    return id == 0
        ? 'ไม่กระทบแผนผลิต'
        : id == 1
            ? 'กระทบแผนผลิต'
            : '$id';
  }

  String requestJobTypeNameFor(int? id) {
    if (id == null) return '–';
    for (final item in requestJobTypes) {
      if (item.id == id) return item.displayLabel;
    }
    return '$id';
  }

  String departmentDisplayFor(String? code) {
    if (code == null || code.trim().isEmpty) return '–';
    final trimmed = code.trim();
    for (final d in departments) {
      if (d.code == trimmed) return d.displayLabel;
    }
    return trimmed;
  }

  String qualityIssueTypeNameFor(int? id) {
    if (id == null) return '–';
    for (final item in qualityIssueTypes) {
      if (item.id == id) return item.displayLabel;
    }
    return '$id';
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

  // --- Read-only MT System Status (from MTSystem DB via List) ---
  final int? mtStatus;
  final String? mtStatusName;
  final String? mtJobNo;
  final int? mtJobStatus;
  final String? mtJobStatusName;
  final String? mtEngineerName;
  final bool? mtEnded;

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
    this.mtStatus,
    this.mtStatusName,
    this.mtJobNo,
    this.mtJobStatus,
    this.mtJobStatusName,
    this.mtEngineerName,
    this.mtEnded,
  });

  bool get isMtEnded => mtEnded == true;
  bool get isMtCancelled => mtStatus == 9;
  bool get isWaitingFieldClose => status == 1 && mtEnded == true;
  bool get hasMtTracking =>
      mtStatus != null ||
      (mtStatusName != null && mtStatusName!.isNotEmpty) ||
      (mtJobNo != null && mtJobNo!.isNotEmpty) ||
      mtJobStatus != null ||
      (mtJobStatusName != null && mtJobStatusName!.isNotEmpty) ||
      (mtEngineerName != null && mtEngineerName!.isNotEmpty);

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
      mtStatus: _mtToNullableInt(_mtReadKey(json, 'mtStatus')),
      mtStatusName: _mtToNullableStr(_mtReadKey(json, 'mtStatusName')),
      mtJobNo: _mtToNullableStr(_mtReadKey(json, 'mtJobNo')),
      mtJobStatus: _mtToNullableInt(_mtReadKey(json, 'mtJobStatus')),
      mtJobStatusName: _mtToNullableStr(_mtReadKey(json, 'mtJobStatusName')),
      mtEngineerName: _mtToNullableStr(_mtReadKey(json, 'mtEngineerName')),
      mtEnded: _mtToNullableBool(_mtReadKey(json, 'mtEnded')),
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

  // --- MT Request Form Fields (v2) ---
  final String? requesterName;
  final String? requesterDepartmentCode;
  final String? requesterTel;
  final String? requesterEmail;
  final int? requestJobType;
  final String? equipmentDepartmentCode;
  final String? equipmentId;
  final String? equipmentLocation;
  final int? statusEquiType;
  final String? problemDate;
  final int? planImpact;
  final int? qualityIssueType;
  final String? qualityIssueNo;
  final String? onsiteName;
  final String? onsiteTel;

  // --- MT Send Readiness & Reference ---
  final int? mtRecId;
  final String? missingFields;
  final bool readyToSend;

  // --- Read-only MT System Status (from MTSystem DB via Detail) ---
  final int? mtStatus;
  final String? mtStatusName;
  final String? mtLastAction;
  final String? mtLastActionDate;
  final String? mtCancelDate;
  final String? mtJobNo;
  final int? mtJobStatus;
  final String? mtJobStatusName;
  final String? mtEngineerName;
  final String? mtRepairDate;
  final String? mtCloseJobDate;
  final String? mtFinishDate;
  final String? mtCorrectiveAction;
  final String? mtCloseJobDescription;
  final bool? mtEnded;

  // --- Display Names resolved from MT Master (from Detail) ---
  final String? requestJobTypeName;
  final String? requesterDepartmentName;
  final String? equipmentDepartmentName;
  final String? equipmentName;
  final String? statusEquiTypeName;
  final String? planImpactName;
  final String? qualityIssueTypeName;

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
    this.requesterName,
    this.requesterDepartmentCode,
    this.requesterTel,
    this.requesterEmail,
    this.requestJobType,
    this.equipmentDepartmentCode,
    this.equipmentId,
    this.equipmentLocation,
    this.statusEquiType,
    this.problemDate,
    this.planImpact,
    this.qualityIssueType,
    this.qualityIssueNo,
    this.onsiteName,
    this.onsiteTel,
    this.mtRecId,
    this.missingFields,
    this.readyToSend = false,
    this.mtStatus,
    this.mtStatusName,
    this.mtLastAction,
    this.mtLastActionDate,
    this.mtCancelDate,
    this.mtJobNo,
    this.mtJobStatus,
    this.mtJobStatusName,
    this.mtEngineerName,
    this.mtRepairDate,
    this.mtCloseJobDate,
    this.mtFinishDate,
    this.mtCorrectiveAction,
    this.mtCloseJobDescription,
    this.mtEnded,
    this.requestJobTypeName,
    this.requesterDepartmentName,
    this.equipmentDepartmentName,
    this.equipmentName,
    this.statusEquiTypeName,
    this.planImpactName,
    this.qualityIssueTypeName,
  });

  bool get isDraft => status == 0;
  bool get isSentToMt => status == 1;
  bool get isClosed => status == 2;
  bool get isCancelled => status == 3;
  bool get isEditable => isDraft || isSentToMt;

  bool get isMtEnded => mtEnded == true;
  bool get isMtCancelled => mtStatus == 9;
  bool get isWaitingFieldClose => isSentToMt && mtEnded == true;
  bool get hasMtTracking =>
      mtStatus != null ||
      (mtStatusName != null && mtStatusName!.isNotEmpty) ||
      (mtLastAction != null && mtLastAction!.isNotEmpty) ||
      (mtJobNo != null && mtJobNo!.isNotEmpty) ||
      mtJobStatus != null ||
      (mtJobStatusName != null && mtJobStatusName!.isNotEmpty) ||
      (mtEngineerName != null && mtEngineerName!.isNotEmpty) ||
      (mtCorrectiveAction != null && mtCorrectiveAction!.isNotEmpty) ||
      (mtCloseJobDescription != null && mtCloseJobDescription!.isNotEmpty);

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
      requesterName: _mtToNullableStr(_mtReadKey(json, 'requesterName')),
      requesterDepartmentCode:
          _mtToNullableStr(_mtReadKey(json, 'requesterDepartmentCode')),
      requesterTel: _mtToNullableStr(_mtReadKey(json, 'requesterTel')),
      requesterEmail: _mtToNullableStr(_mtReadKey(json, 'requesterEmail')),
      requestJobType: _mtToNullableInt(_mtReadKey(json, 'requestJobType')),
      equipmentDepartmentCode:
          _mtToNullableStr(_mtReadKey(json, 'equipmentDepartmentCode')),
      equipmentId: _mtToNullableStr(_mtReadKey(json, 'equipmentId')),
      equipmentLocation:
          _mtToNullableStr(_mtReadKey(json, 'equipmentLocation')),
      statusEquiType: _mtToNullableInt(_mtReadKey(json, 'statusEquiType')),
      problemDate: _mtToNullableStr(_mtReadKey(json, 'problemDate')),
      planImpact: _mtToNullableInt(_mtReadKey(json, 'planImpact')),
      qualityIssueType: _mtToNullableInt(_mtReadKey(json, 'qualityIssueType')),
      qualityIssueNo: _mtToNullableStr(_mtReadKey(json, 'qualityIssueNo')),
      onsiteName: _mtToNullableStr(_mtReadKey(json, 'onsiteName')),
      onsiteTel: _mtToNullableStr(_mtReadKey(json, 'onsiteTel')),
      mtRecId: _mtToNullableInt(_mtReadKey(json, 'mtRecId')),
      missingFields: _mtToNullableStr(_mtReadKey(json, 'missingFields')),
      readyToSend: _mtToBool(_mtReadKey(json, 'readyToSend')),
      mtStatus: _mtToNullableInt(_mtReadKey(json, 'mtStatus')),
      mtStatusName: _mtToNullableStr(_mtReadKey(json, 'mtStatusName')),
      mtLastAction: _mtToNullableStr(_mtReadKey(json, 'mtLastAction')),
      mtLastActionDate: _mtToNullableStr(_mtReadKey(json, 'mtLastActionDate')),
      mtCancelDate: _mtToNullableStr(_mtReadKey(json, 'mtCancelDate')),
      mtJobNo: _mtToNullableStr(_mtReadKey(json, 'mtJobNo')),
      mtJobStatus: _mtToNullableInt(_mtReadKey(json, 'mtJobStatus')),
      mtJobStatusName: _mtToNullableStr(_mtReadKey(json, 'mtJobStatusName')),
      mtEngineerName: _mtToNullableStr(_mtReadKey(json, 'mtEngineerName')),
      mtRepairDate: _mtToNullableStr(_mtReadKey(json, 'mtRepairDate')),
      mtCloseJobDate: _mtToNullableStr(_mtReadKey(json, 'mtCloseJobDate')),
      mtFinishDate: _mtToNullableStr(_mtReadKey(json, 'mtFinishDate')),
      mtCorrectiveAction:
          _mtToNullableStr(_mtReadKey(json, 'mtCorrectiveAction')),
      mtCloseJobDescription:
          _mtToNullableStr(_mtReadKey(json, 'mtCloseJobDescription')),
      mtEnded: _mtToNullableBool(_mtReadKey(json, 'mtEnded')),
      requestJobTypeName:
          _mtToNullableStr(_mtReadKey(json, 'requestJobTypeName')),
      requesterDepartmentName:
          _mtToNullableStr(_mtReadKey(json, 'requesterDepartmentName')),
      equipmentDepartmentName:
          _mtToNullableStr(_mtReadKey(json, 'equipmentDepartmentName')),
      equipmentName: _mtToNullableStr(_mtReadKey(json, 'equipmentName')),
      statusEquiTypeName:
          _mtToNullableStr(_mtReadKey(json, 'statusEquiTypeName')),
      planImpactName: _mtToNullableStr(_mtReadKey(json, 'planImpactName')),
      qualityIssueTypeName:
          _mtToNullableStr(_mtReadKey(json, 'qualityIssueTypeName')),
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
