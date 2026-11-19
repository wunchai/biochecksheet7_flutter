// lib/data/models/am_summary_models.dart

enum AmSummaryDetailMode {
  pending,
  opencase,
  nosup,
  docs,
  abnormal,
}

extension AmSummaryDetailModeExt on AmSummaryDetailMode {
  String get label {
    switch (this) {
      case AmSummaryDetailMode.pending:
        return 'ยังไม่ verify';
      case AmSummaryDetailMode.opencase:
        return 'เคสค้าง';
      case AmSummaryDetailMode.nosup:
        return 'หัวหน้ายังไม่ตรวจ';
      case AmSummaryDetailMode.docs:
        return 'เอกสารทั้งหมด';
      case AmSummaryDetailMode.abnormal:
        return 'จุดผิดปกติทั้งหมด';
    }
  }

  bool get usesDocuments =>
      this == AmSummaryDetailMode.docs || this == AmSummaryDetailMode.nosup;
}

/// Case-insensitive JSON lookup helpers for SQL DataTable serialization.
dynamic _readKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return null;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

String _toStr(dynamic value) => value?.toString() ?? '';

String? _toNullableStr(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

/// Level: JOB_MONTHLY (from CheckSheet_Summary_Level2_JobMonthly)
class AmSummaryMonthlyRow {
  final int jobId;
  final String jobName;
  final String machineName;
  final String location;
  final String yearMonth;
  final int documentCount;
  final int tagCount;
  final int issueCount;
  final int abnormalRunningCount;
  final int abnormalStoppedCount;
  final int outOfSpecCount;
  final int unreadableCount;
  final int pendingVerifyCount;
  final int caseOpenCount;
  final int caseSelfRepairCount;
  final int caseRepairRequestCount;
  final int documentSupervisorCheckedCount;
  final double? avgSupervisorLagHours;
  final String? refreshDate;

  const AmSummaryMonthlyRow({
    required this.jobId,
    required this.jobName,
    required this.machineName,
    required this.location,
    required this.yearMonth,
    required this.documentCount,
    required this.tagCount,
    required this.issueCount,
    required this.abnormalRunningCount,
    required this.abnormalStoppedCount,
    required this.outOfSpecCount,
    required this.unreadableCount,
    required this.pendingVerifyCount,
    required this.caseOpenCount,
    required this.caseSelfRepairCount,
    required this.caseRepairRequestCount,
    required this.documentSupervisorCheckedCount,
    this.avgSupervisorLagHours,
    this.refreshDate,
  });

  factory AmSummaryMonthlyRow.fromJson(Map<String, dynamic> json) {
    return AmSummaryMonthlyRow(
      jobId: _toInt(_readKey(json, 'jobId')),
      jobName: _toStr(_readKey(json, 'jobName')),
      machineName: _toStr(_readKey(json, 'machineName')),
      location: _toStr(_readKey(json, 'location')),
      yearMonth: _toStr(_readKey(json, 'yearMonth')),
      documentCount: _toInt(_readKey(json, 'documentCount')),
      tagCount: _toInt(_readKey(json, 'tagCount')),
      issueCount: _toInt(_readKey(json, 'issueCount')),
      abnormalRunningCount: _toInt(_readKey(json, 'abnormalRunningCount')),
      abnormalStoppedCount: _toInt(_readKey(json, 'abnormalStoppedCount')),
      outOfSpecCount: _toInt(_readKey(json, 'outOfSpecCount')),
      unreadableCount: _toInt(_readKey(json, 'unreadableCount')),
      pendingVerifyCount: _toInt(_readKey(json, 'pendingVerifyCount')),
      caseOpenCount: _toInt(_readKey(json, 'caseOpenCount')),
      caseSelfRepairCount: _toInt(_readKey(json, 'caseSelfRepairCount')),
      caseRepairRequestCount: _toInt(_readKey(json, 'caseRepairRequestCount')),
      documentSupervisorCheckedCount:
          _toInt(_readKey(json, 'documentSupervisorCheckedCount')),
      avgSupervisorLagHours:
          _toNullableDouble(_readKey(json, 'avgSupervisorLagHours')),
      refreshDate: _toNullableStr(_readKey(json, 'refreshDate')),
    );
  }
}

/// Level: DOCUMENT (from CheckSheet_Summary_Level1_Document)
class AmSummaryDocumentRow {
  final String documentId;
  final int jobId;
  final String? documentCreateDate;
  final String machineName;
  final String lot;
  final String createUser;
  final String phaseList;
  final int phaseCount;
  final int tagCount;
  final int issueCount;
  final int pendingVerifyCount;
  final int caseOpenCount;
  final bool isSupervisorChecked;
  final int supervisorCheckedPhaseCount;
  final String? firstSupervisorCheckDate;
  final double? supervisorLagHours;

  const AmSummaryDocumentRow({
    required this.documentId,
    required this.jobId,
    this.documentCreateDate,
    required this.machineName,
    required this.lot,
    required this.createUser,
    required this.phaseList,
    required this.phaseCount,
    required this.tagCount,
    required this.issueCount,
    required this.pendingVerifyCount,
    required this.caseOpenCount,
    required this.isSupervisorChecked,
    required this.supervisorCheckedPhaseCount,
    this.firstSupervisorCheckDate,
    this.supervisorLagHours,
  });

  factory AmSummaryDocumentRow.fromJson(Map<String, dynamic> json) {
    return AmSummaryDocumentRow(
      documentId: _toStr(_readKey(json, 'documentId')),
      jobId: _toInt(_readKey(json, 'jobId')),
      documentCreateDate: _toNullableStr(_readKey(json, 'documentCreateDate')),
      machineName: _toStr(_readKey(json, 'machineName')),
      lot: _toStr(_readKey(json, 'lot')),
      createUser: _toStr(_readKey(json, 'createUser')),
      phaseList: _toStr(_readKey(json, 'phaseList')),
      phaseCount: _toInt(_readKey(json, 'phaseCount')),
      tagCount: _toInt(_readKey(json, 'tagCount')),
      issueCount: _toInt(_readKey(json, 'issueCount')),
      pendingVerifyCount: _toInt(_readKey(json, 'pendingVerifyCount')),
      caseOpenCount: _toInt(_readKey(json, 'caseOpenCount')),
      isSupervisorChecked: _toBool(_readKey(json, 'isSupervisorChecked')),
      supervisorCheckedPhaseCount:
          _toInt(_readKey(json, 'supervisorCheckedPhaseCount')),
      firstSupervisorCheckDate:
          _toNullableStr(_readKey(json, 'firstSupervisorCheckDate')),
      supervisorLagHours:
          _toNullableDouble(_readKey(json, 'supervisorLagHours')),
    );
  }
}

/// Level: ABNORMAL (from CheckSheet_Summary_Level1_Abnormal)
class AmSummaryAbnormalRow {
  final String documentId;
  final int jobId;
  final String? documentCreateDate;
  final String machineName;
  final String phaseName;
  final String tagGroupName;
  final String tagName;
  final String? recordRemark;
  final String issueType;
  final String value;
  final String? specMin;
  final String? specMax;
  final String? unit;
  final int? lastVerifyType;
  final String? lastVerifyTypeName;
  final String? lastVerifyBy;
  final String? lastVerifyDate;
  final int verifyCount;
  final String? lastVerifyRemark;
  final int? problemId;
  final String? problemCloseDate;
  final int? caseAgeDays;
  final String? caseType;

  const AmSummaryAbnormalRow({
    required this.documentId,
    required this.jobId,
    this.documentCreateDate,
    required this.machineName,
    required this.phaseName,
    required this.tagGroupName,
    required this.tagName,
    this.recordRemark,
    required this.issueType,
    required this.value,
    this.specMin,
    this.specMax,
    this.unit,
    this.lastVerifyType,
    this.lastVerifyTypeName,
    this.lastVerifyBy,
    this.lastVerifyDate,
    required this.verifyCount,
    this.lastVerifyRemark,
    this.problemId,
    this.problemCloseDate,
    this.caseAgeDays,
    this.caseType,
  });

  bool get isPendingVerify =>
      lastVerifyType == null && issueType != 'VERIFIED_ONLY';

  bool get isOpenCase =>
      problemId != null &&
      (problemCloseDate == null || problemCloseDate!.trim().isEmpty);

  factory AmSummaryAbnormalRow.fromJson(Map<String, dynamic> json) {
    return AmSummaryAbnormalRow(
      documentId: _toStr(_readKey(json, 'documentId')),
      jobId: _toInt(_readKey(json, 'jobId')),
      documentCreateDate: _toNullableStr(_readKey(json, 'documentCreateDate')),
      machineName: _toStr(_readKey(json, 'machineName')),
      phaseName: _toStr(_readKey(json, 'phaseName')),
      tagGroupName: _toStr(_readKey(json, 'tagGroupName')),
      tagName: _toStr(_readKey(json, 'tagName')),
      recordRemark: _toNullableStr(_readKey(json, 'recordRemark')),
      issueType: _toStr(_readKey(json, 'issueType')),
      value: _toStr(_readKey(json, 'value')),
      specMin: _toNullableStr(_readKey(json, 'specMin')),
      specMax: _toNullableStr(_readKey(json, 'specMax')),
      unit: _toNullableStr(_readKey(json, 'unit')),
      lastVerifyType: _toNullableInt(_readKey(json, 'lastVerifyType')),
      lastVerifyTypeName: _toNullableStr(_readKey(json, 'lastVerifyTypeName')),
      lastVerifyBy: _toNullableStr(_readKey(json, 'lastVerifyBy')),
      lastVerifyDate: _toNullableStr(_readKey(json, 'lastVerifyDate')),
      verifyCount: _toInt(_readKey(json, 'verifyCount')),
      lastVerifyRemark: _toNullableStr(_readKey(json, 'lastVerifyRemark')),
      problemId: _toNullableInt(_readKey(json, 'problemId')),
      problemCloseDate: _toNullableStr(_readKey(json, 'problemCloseDate')),
      caseAgeDays: _toNullableInt(_readKey(json, 'caseAgeDays')),
      caseType: _toNullableStr(_readKey(json, 'caseType')),
    );
  }
}

/// Aggregated per-job summary for the "รายใบงาน" table.
class AmSummaryJobAggregate {
  final int jobId;
  final String jobName;
  final String machineName;
  final String location;
  final int documentCount;
  final int tagCount;
  final int abnormalRunningCount;
  final int abnormalStoppedCount;
  final int outOfSpecCount;
  final int unreadableCount;
  final int issueCount;
  final int pendingVerifyCount;
  final int caseOpenCount;
  final int supervisorNotCheckedCount;
  final double? avgSupervisorLagHours;

  const AmSummaryJobAggregate({
    required this.jobId,
    required this.jobName,
    required this.machineName,
    required this.location,
    required this.documentCount,
    required this.tagCount,
    required this.abnormalRunningCount,
    required this.abnormalStoppedCount,
    required this.outOfSpecCount,
    required this.unreadableCount,
    required this.issueCount,
    required this.pendingVerifyCount,
    required this.caseOpenCount,
    required this.supervisorNotCheckedCount,
    this.avgSupervisorLagHours,
  });

  double get issuePct => tagCount > 0 ? (issueCount * 100.0 / tagCount) : 0.0;
}

/// Aggregated per-month summary for the "รายเดือน" table.
class AmSummaryMonthAggregate {
  final String yearMonth;
  final int documentCount;
  final int tagCount;
  final int issueCount;
  final int pendingVerifyCount;
  final int caseSelfRepairCount;
  final int caseRepairRequestCount;
  final int caseOpenCount;
  final int documentSupervisorCheckedCount;

  const AmSummaryMonthAggregate({
    required this.yearMonth,
    required this.documentCount,
    required this.tagCount,
    required this.issueCount,
    required this.pendingVerifyCount,
    required this.caseSelfRepairCount,
    required this.caseRepairRequestCount,
    required this.caseOpenCount,
    required this.documentSupervisorCheckedCount,
  });

  double get issuePct => tagCount > 0 ? (issueCount * 100.0 / tagCount) : 0.0;

  double get supervisorCheckedPct => documentCount > 0
      ? (documentSupervisorCheckedCount * 100.0 / documentCount)
      : 0.0;
}
