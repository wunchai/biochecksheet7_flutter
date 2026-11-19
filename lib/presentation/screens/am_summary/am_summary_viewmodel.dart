// lib/presentation/screens/am_summary/am_summary_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:biochecksheet7_flutter/data/models/am_summary_models.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';

class AmSummaryJobOption {
  final int jobId;
  final String label;

  const AmSummaryJobOption({required this.jobId, required this.label});
}

class AmSummaryViewModel extends ChangeNotifier {
  final DocumentOnlineApiService _apiService;

  AmSummaryViewModel(this._apiService);

  List<AmSummaryMonthlyRow> _monthlyRows = [];
  List<AmSummaryDocumentRow>? _docCache;
  List<AmSummaryAbnormalRow>? _abnCache;

  String? _selectedJobId;
  DateTime? _fromMonth;
  DateTime? _toMonth;
  String? _selectedDocumentId;
  AmSummaryDetailMode _detailMode = AmSummaryDetailMode.pending;

  bool _isLoadingMonthly = false;
  bool _isRefreshing = false;
  bool _isLoadingDetail = false;
  bool _hasInitialized = false;
  String? _errorMessage;
  String? _detailErrorMessage;

  int _monthlySeq = 0;
  int _detailSeq = 0;

  // --- Public Getters ---
  List<AmSummaryMonthlyRow> get monthlyRows => _monthlyRows;
  String? get selectedJobId => _selectedJobId;
  DateTime? get fromMonth => _fromMonth;
  DateTime? get toMonth => _toMonth;
  String? get selectedDocumentId => _selectedDocumentId;
  AmSummaryDetailMode get detailMode => _detailMode;

  bool get isLoadingMonthly => _isLoadingMonthly;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get hasInitialized => _hasInitialized;
  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  String? get lastRefreshDate =>
      _monthlyRows.isNotEmpty ? _monthlyRows.first.refreshDate : null;

  String? get fromDateParam {
    if (_fromMonth == null) return null;
    final y = _fromMonth!.year.toString().padLeft(4, '0');
    final m = _fromMonth!.month.toString().padLeft(2, '0');
    return '$y-$m-01';
  }

  String? get toDateParam {
    if (_toMonth == null) return null;
    final y = _toMonth!.year;
    final m = _toMonth!.month;
    final lastDay = DateTime(y, m + 1, 0).day;
    return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
  }

  /// Unique sorted job options for the dropdown filter.
  List<AmSummaryJobOption> get jobOptions {
    final seen = <int, AmSummaryJobOption>{};
    for (final r in _monthlyRows) {
      seen.putIfAbsent(
        r.jobId,
        () => AmSummaryJobOption(
          jobId: r.jobId,
          label:
              '${r.jobId} · ${r.machineName.isNotEmpty ? r.machineName : r.jobName}',
        ),
      );
    }
    final list = seen.values.toList()
      ..sort((a, b) => a.jobId.compareTo(b.jobId));
    return list;
  }

  /// Rows filtered by current selectedJobId (used by KPIs and Monthly table).
  List<AmSummaryMonthlyRow> get rowsInScope {
    if (_selectedJobId == null || _selectedJobId!.isEmpty) {
      return _monthlyRows;
    }
    return _monthlyRows
        .where((r) => r.jobId.toString() == _selectedJobId)
        .toList();
  }

  // --- KPI Aggregations ---
  int get totalDocs => rowsInScope.fold(0, (a, r) => a + r.documentCount);
  int get totalTags => rowsInScope.fold(0, (a, r) => a + r.tagCount);
  int get totalIssues => rowsInScope.fold(0, (a, r) => a + r.issueCount);
  int get totalPendingVerify =>
      rowsInScope.fold(0, (a, r) => a + r.pendingVerifyCount);
  int get totalOpenCase => rowsInScope.fold(0, (a, r) => a + r.caseOpenCount);
  int get totalSupervisorCheckedDocs =>
      rowsInScope.fold(0, (a, r) => a + r.documentSupervisorCheckedCount);
  int get totalNoSupervisor => totalDocs - totalSupervisorCheckedDocs;

  double get issuePct => totalTags > 0 ? (totalIssues * 100.0 / totalTags) : 0;
  double get noSupervisorPct =>
      totalDocs > 0 ? (totalNoSupervisor * 100.0 / totalDocs) : 0;

  // --- Job Summary Table (always shows all jobs in date range, sorted by backlog) ---
  List<AmSummaryJobAggregate> get jobAggregates {
    final grouped = <int, List<AmSummaryMonthlyRow>>{};
    for (final r in _monthlyRows) {
      grouped.putIfAbsent(r.jobId, () => []).add(r);
    }

    final result = grouped.entries.map((entry) {
      final rows = entry.value;
      final first = rows.first;
      final docs = rows.fold(0, (a, r) => a + r.documentCount);
      final tags = rows.fold(0, (a, r) => a + r.tagCount);
      final supChecked =
          rows.fold(0, (a, r) => a + r.documentSupervisorCheckedCount);
      final lagRows =
          rows.where((r) => r.avgSupervisorLagHours != null).toList();
      final double? avgLag = lagRows.isEmpty
          ? null
          : lagRows.fold(0.0, (a, r) => a + r.avgSupervisorLagHours!) /
              lagRows.length;

      return AmSummaryJobAggregate(
        jobId: first.jobId,
        jobName: first.jobName,
        machineName: first.machineName,
        location: first.location,
        documentCount: docs,
        tagCount: tags,
        abnormalRunningCount:
            rows.fold(0, (a, r) => a + r.abnormalRunningCount),
        abnormalStoppedCount:
            rows.fold(0, (a, r) => a + r.abnormalStoppedCount),
        outOfSpecCount: rows.fold(0, (a, r) => a + r.outOfSpecCount),
        unreadableCount: rows.fold(0, (a, r) => a + r.unreadableCount),
        issueCount: rows.fold(0, (a, r) => a + r.issueCount),
        pendingVerifyCount: rows.fold(0, (a, r) => a + r.pendingVerifyCount),
        caseOpenCount: rows.fold(0, (a, r) => a + r.caseOpenCount),
        supervisorNotCheckedCount: docs - supChecked,
        avgSupervisorLagHours: avgLag,
      );
    }).toList();

    result.sort((a, b) => (b.pendingVerifyCount + b.caseOpenCount)
        .compareTo(a.pendingVerifyCount + a.caseOpenCount));
    return result;
  }

  // --- Monthly Summary Table (filtered by selectedJobId, newest month first) ---
  List<AmSummaryMonthAggregate> get monthAggregates {
    final grouped = <String, List<AmSummaryMonthlyRow>>{};
    for (final r in rowsInScope) {
      grouped.putIfAbsent(r.yearMonth, () => []).add(r);
    }

    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return months.map((m) {
      final rows = grouped[m]!;
      return AmSummaryMonthAggregate(
        yearMonth: m,
        documentCount: rows.fold(0, (a, r) => a + r.documentCount),
        tagCount: rows.fold(0, (a, r) => a + r.tagCount),
        issueCount: rows.fold(0, (a, r) => a + r.issueCount),
        pendingVerifyCount: rows.fold(0, (a, r) => a + r.pendingVerifyCount),
        caseSelfRepairCount: rows.fold(0, (a, r) => a + r.caseSelfRepairCount),
        caseRepairRequestCount:
            rows.fold(0, (a, r) => a + r.caseRepairRequestCount),
        caseOpenCount: rows.fold(0, (a, r) => a + r.caseOpenCount),
        documentSupervisorCheckedCount:
            rows.fold(0, (a, r) => a + r.documentSupervisorCheckedCount),
      );
    }).toList();
  }

  // --- Detail Table Rows ---
  List<AmSummaryDocumentRow> get filteredDocuments {
    final cache = _docCache;
    if (cache == null) return [];
    Iterable<AmSummaryDocumentRow> rows = cache;
    if (_selectedJobId != null && _selectedJobId!.isNotEmpty) {
      rows = rows.where((r) => r.jobId.toString() == _selectedJobId);
    }
    if (_selectedDocumentId != null && _selectedDocumentId!.isNotEmpty) {
      rows = rows.where((r) => r.documentId == _selectedDocumentId);
    }
    if (_detailMode == AmSummaryDetailMode.nosup) {
      rows = rows.where((r) => !r.isSupervisorChecked);
    }
    return rows.toList();
  }

  List<AmSummaryAbnormalRow> get filteredAbnormals {
    final cache = _abnCache;
    if (cache == null) return [];
    Iterable<AmSummaryAbnormalRow> rows = cache;
    if (_selectedJobId != null && _selectedJobId!.isNotEmpty) {
      rows = rows.where((r) => r.jobId.toString() == _selectedJobId);
    }
    if (_selectedDocumentId != null && _selectedDocumentId!.isNotEmpty) {
      rows = rows.where((r) => r.documentId == _selectedDocumentId);
    }
    if (_detailMode == AmSummaryDetailMode.pending) {
      rows = rows.where((r) => r.isPendingVerify);
    } else if (_detailMode == AmSummaryDetailMode.opencase) {
      rows = rows.where((r) => r.isOpenCase);
    }
    final list = rows.toList();
    list.sort((a, b) {
      final ageCmp = (b.caseAgeDays ?? 0).compareTo(a.caseAgeDays ?? 0);
      if (ageCmp != 0) return ageCmp;
      final aDate = a.documentCreateDate ?? '';
      final bDate = b.documentCreateDate ?? '';
      return bDate.compareTo(aDate);
    });
    return list;
  }

  // --- Actions ---
  Future<void> initializeIfNeeded() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    await load(refresh: true);
  }

  Future<void> load({required bool refresh}) async {
    final seq = ++_monthlySeq;
    _isLoadingMonthly = true;
    _isRefreshing = refresh;
    _errorMessage = null;
    _detailErrorMessage = null;
    _docCache = null;
    _abnCache = null;
    notifyListeners();

    try {
      final rows = await _apiService.getAmSummaryMonthly(
        fromDate: fromDateParam,
        toDate: toDateParam,
        refresh: refresh,
      );

      if (seq != _monthlySeq) return;

      _monthlyRows = rows;

      // Ensure selectedJobId still exists in options to prevent Dropdown crash.
      if (_selectedJobId != null &&
          !_monthlyRows.any((r) => r.jobId.toString() == _selectedJobId)) {
        _selectedJobId = null;
      }

      _isLoadingMonthly = false;
      _isRefreshing = false;
      notifyListeners();

      await _ensureDetailLoaded();
    } catch (e) {
      if (seq != _monthlySeq) return;
      _isLoadingMonthly = false;
      _isRefreshing = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void setFromMonth(DateTime? month) {
    _fromMonth = month == null ? null : DateTime(month.year, month.month);
    notifyListeners();
  }

  void setToMonth(DateTime? month) {
    _toMonth = month == null ? null : DateTime(month.year, month.month);
    notifyListeners();
  }

  Future<void> applyFilters() async {
    _selectedDocumentId = null;
    await load(refresh: false);
  }

  Future<void> selectJob(String? jobId) async {
    _selectedJobId = (jobId == null || jobId.isEmpty) ? null : jobId;
    _selectedDocumentId = null;
    notifyListeners();
    await _ensureDetailLoaded();
  }

  /// Clicking a job row toggles selection; when selecting a job, switches detail to docs.
  Future<bool> toggleJobRow(int jobId) async {
    final idStr = jobId.toString();
    final isSelecting = _selectedJobId != idStr;
    _selectedJobId = isSelecting ? idStr : null;
    _selectedDocumentId = null;
    if (isSelecting) {
      _detailMode = AmSummaryDetailMode.docs;
    }
    notifyListeners();
    await _ensureDetailLoaded();
    return isSelecting;
  }

  Future<void> setDetailMode(AmSummaryDetailMode mode) async {
    _detailMode = mode;
    notifyListeners();
    await _ensureDetailLoaded();
  }

  Future<void> selectDocumentForDrilldown(String documentId) async {
    _selectedDocumentId = documentId;
    _detailMode = AmSummaryDetailMode.abnormal;
    notifyListeners();
    await _ensureDetailLoaded();
  }

  void clearDocumentFilter() {
    _selectedDocumentId = null;
    notifyListeners();
  }

  Future<void> _ensureDetailLoaded() async {
    final needsDocs = _detailMode.usesDocuments;
    if (needsDocs && _docCache != null) return;
    if (!needsDocs && _abnCache != null) return;

    final seq = ++_detailSeq;
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      if (needsDocs) {
        final docs = await _apiService.getAmSummaryDocuments(
          fromDate: fromDateParam,
          toDate: toDateParam,
        );
        if (seq != _detailSeq) return;
        _docCache = docs;
      } else {
        final abns = await _apiService.getAmSummaryAbnormals(
          fromDate: fromDateParam,
          toDate: toDateParam,
        );
        if (seq != _detailSeq) return;
        _abnCache = abns;
      }
      _isLoadingDetail = false;
      notifyListeners();
    } catch (e) {
      if (seq != _detailSeq) return;
      _isLoadingDetail = false;
      _detailErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
