// lib/presentation/screens/checksheet_audit/checksheet_audit_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:biochecksheet7_flutter/core/utils/csv_downloader.dart';
import 'package:biochecksheet7_flutter/data/models/checksheet_audit_models.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';

class ChecksheetAuditViewModel extends ChangeNotifier {
  final DocumentOnlineApiService _apiService;

  ChecksheetAuditViewModel(this._apiService) {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
  }

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String? _loadedFromDate;
  String? _loadedToDate;

  List<AuditDocumentRow> _allDocs = [];
  String? _selectedForm;
  String? _selectedPhase;

  AuditDocumentRow? _currentDocument;
  AuditDocumentDetail? _currentDetail;

  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  String? _listError;
  String? _detailError;

  int _listSeq = 0;
  int _detailSeq = 0;

  // --- Public Getters ---
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  String get fromDateIso => _iso(_fromDate);
  String get toDateIso => _iso(_toDate);
  String? get loadedFromDate => _loadedFromDate;
  String? get loadedToDate => _loadedToDate;
  bool get hasLoadedOnce => _loadedFromDate != null && _loadedToDate != null;

  String? get selectedForm => _selectedForm;
  String? get selectedPhase => _selectedPhase;

  AuditDocumentRow? get currentDocument => _currentDocument;
  AuditDocumentDetail? get currentDetail => _currentDetail;
  bool get isInDetailView => _currentDocument != null;

  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get listError => _listError;
  String? get detailError => _detailError;

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _matchesForm(AuditDocumentRow d) =>
      _selectedForm == null ||
      _selectedForm!.isEmpty ||
      d.formName.trim() == _selectedForm;

  bool _matchesPhase(AuditDocumentRow d) =>
      _selectedPhase == null ||
      _selectedPhase!.isEmpty ||
      d.phaseList.contains(_selectedPhase);

  /// Cross-filtered form options (counted over docs matching selectedPhase).
  List<AuditFilterOption> get formOptions {
    final counts = <String, int>{};
    for (final d in _allDocs.where(_matchesPhase)) {
      final k = d.formName.trim();
      if (k.isNotEmpty) {
        counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    if (_selectedForm != null &&
        _selectedForm!.isNotEmpty &&
        !counts.containsKey(_selectedForm)) {
      counts[_selectedForm!] = 0;
    }
    final keys = counts.keys.toList()..sort((a, b) => a.compareTo(b));
    return keys
        .map((k) => AuditFilterOption(value: k, count: counts[k]!))
        .toList();
  }

  /// Cross-filtered phase options (counted over docs matching selectedForm).
  List<AuditFilterOption> get phaseOptions {
    final counts = <String, int>{};
    for (final d in _allDocs.where(_matchesForm)) {
      for (final p in d.phaseList) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }
    if (_selectedPhase != null &&
        _selectedPhase!.isNotEmpty &&
        !counts.containsKey(_selectedPhase)) {
      counts[_selectedPhase!] = 0;
    }
    final keys = counts.keys.toList()..sort((a, b) => a.compareTo(b));
    return keys
        .map((k) => AuditFilterOption(value: k, count: counts[k]!))
        .toList();
  }

  List<AuditDocumentRow> get filteredDocs =>
      _allDocs.where((d) => _matchesForm(d) && _matchesPhase(d)).toList();

  int get distinctJobCount => filteredDocs.map((d) => d.jobId).toSet().length;

  // --- Lifecycle & Actions ---
  void setFromDate(DateTime date) {
    _fromDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setToDate(DateTime date) {
    _toDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setSelectedForm(String? form) {
    _selectedForm = (form == null || form.isEmpty) ? null : form;
    _currentDocument = null;
    _currentDetail = null;
    _detailError = null;
    notifyListeners();
  }

  void setSelectedPhase(String? phase) {
    _selectedPhase = (phase == null || phase.isEmpty) ? null : phase;
    _currentDocument = null;
    _currentDetail = null;
    _detailError = null;
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    if (_fromDate.isAfter(_toDate)) {
      _listError = 'วันที่เริ่มต้องไม่เกินวันที่สิ้นสุด';
      notifyListeners();
      return;
    }

    final seq = ++_listSeq;
    final from = fromDateIso;
    final to = toDateIso;

    _isLoadingList = true;
    _listError = null;
    notifyListeners();

    try {
      final rows = await _apiService.getAuditDocuments(
        fromDate: from,
        toDate: to,
      );
      if (seq != _listSeq) return;

      _allDocs = rows;
      _loadedFromDate = from;
      _loadedToDate = to;
      _currentDocument = null;
      _currentDetail = null;
      _detailError = null;
      _isLoadingList = false;
      notifyListeners();
    } catch (e) {
      if (seq != _listSeq) return;
      _isLoadingList = false;
      _listError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> openDocument(AuditDocumentRow doc) async {
    final seq = ++_detailSeq;
    _currentDocument = doc;
    _currentDetail = null;
    _detailError = null;
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final detail = await _apiService.getAuditDocumentDetail(doc.documentId);
      if (seq != _detailSeq) return;
      _currentDetail = detail;
      _isLoadingDetail = false;
      notifyListeners();
    } catch (e) {
      if (seq != _detailSeq) return;
      _isLoadingDetail = false;
      _detailError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void backToList() {
    _currentDocument = null;
    _currentDetail = null;
    _detailError = null;
    _isLoadingDetail = false;
    notifyListeners();
  }

  // --- CSV Export (matches CHECKSHEET_AUDIT.cs columns & UTF-8 BOM) ---
  String _escapeCsvCell(Object? raw) {
    final s = raw?.toString() ?? '';
    if (s.contains('"') ||
        s.contains(',') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _resultThaiLabel(String result) {
    switch (result) {
      case 'NORMAL':
        return 'ปกติ';
      case 'IN_SPEC':
        return 'ในสเปก';
      case 'ABNORMAL':
        return 'ผิดปกติ';
      case 'OUT_OF_SPEC':
        return 'นอกสเปก';
      case 'UNREADABLE':
        return 'อ่านค่าไม่ได้';
      case 'BLANK':
        return 'ไม่ได้บันทึก';
      case 'NOT_NUMBER':
        return 'ไม่ใช่ตัวเลข';
      case 'NO_SPEC':
        return 'ไม่มีสเปก';
      case 'RECORDED':
        return 'บันทึก';
      default:
        return result;
    }
  }

  String _fmtShortDt(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    final clean = s.replaceAll('T', ' ').trim();
    return clean.length >= 16 ? clean.substring(0, 16) : clean;
  }

  String buildCsvContent() {
    const headers = [
      'วันเวลาที่บันทึก',
      'ใบงาน',
      'เครื่องจักร',
      'พื้นที่',
      'ช่วงการตรวจ',
      'Lot',
      'ผู้บันทึก',
      'รายการตรวจ',
      'ปกติ',
      'ผิดปกติ',
      'นอกสเปก',
      'อ่านค่าไม่ได้',
      'ไม่ได้บันทึก',
      'Verify แล้ว',
      'เคสทั้งหมด',
      'เคสยังเปิด',
      'หัวหน้าผู้ตรวจ',
      'หัวหน้าตรวจเมื่อ',
      'สถานะ',
      'เลขเอกสาร',
      'Sync ล่าสุด',
    ];

    final lines = <String>[
      headers.map(_escapeCsvCell).join(','),
      ...filteredDocs.map((d) {
        final cols = <Object?>[
          d.createDate ?? '',
          d.formName,
          d.machineName,
          d.location,
          d.phases,
          d.lot,
          d.createUser,
          d.itemCount,
          d.normalCount,
          d.abnormalCount,
          d.outOfSpecCount,
          d.unreadableCount,
          d.blankCount,
          d.verifiedCount,
          d.caseCount,
          d.openCaseCount,
          d.supervisorUser ?? '',
          d.supervisorCheck ?? '',
          d.isFinished ? 'บันทึกเสร็จ' : 'บันทึกยังไม่เสร็จ',
          d.documentId,
          d.lastSync ?? '',
        ];
        return cols.map(_escapeCsvCell).join(',');
      }),
    ];

    return '\uFEFF${lines.join('\r\n')}';
  }

  /// Downloads list CSV directly in browser (Web) or saves to Downloads/Documents (Desktop/Mobile).
  Future<String?> exportCsvFile() async {
    if (filteredDocs.isEmpty) return null;
    final content = buildCsvContent();
    final from = _loadedFromDate ?? fromDateIso;
    final to = _loadedToDate ?? toDateIso;
    final fileName = 'checksheet_${from}_$to.csv';
    return saveCsvFile(fileName, content);
  }

  /// Builds CSV for all Tag items of the currently opened audit document (UTF-8 BOM).
  String buildDetailCsvContent() {
    final doc = _currentDocument;
    final detail = _currentDetail;
    if (doc == null || detail == null) return '';

    const headers = [
      'ลำดับ',
      'เลขเอกสาร',
      'ใบงาน',
      'เครื่องจักร',
      'พื้นที่',
      'Lot',
      'ผู้บันทึก',
      'วันเวลาที่บันทึก',
      'ช่วงการตรวจ',
      'หมวด',
      'รายการตรวจ (Tag)',
      'เกณฑ์ / รายละเอียด',
      'สเปก',
      'ค่าที่บันทึก',
      'หน่วย',
      'ผลตรวจ',
      'หมายเหตุ',
      'ประวัติ Verify',
      'ประวัติเคส',
      'หัวหน้าตรวจ (ช่วงนี้)',
    ];

    final verifiesMap = detail.verifiesByRecordTagId;
    final casesMap = detail.casesByRecordTagId;
    final supByPhase = <String, List<AuditSupervisorCheck>>{};
    for (final s in detail.supervisorChecks) {
      supByPhase.putIfAbsent(s.phaseName.trim(), () => []).add(s);
    }

    final lines = <String>[
      headers.map(_escapeCsvCell).join(','),
    ];

    for (int i = 0; i < detail.items.length; i++) {
      final it = detail.items[i];

      final criteriaParts = <String>[
        if (it.description != null && it.description!.trim().isNotEmpty)
          it.description!.trim(),
        if (it.specification != null && it.specification!.trim().isNotEmpty)
          it.specification!.trim(),
      ];

      final verifyText = (verifiesMap[it.recordTagId] ?? const []).map((v) {
        final remark = (v.remark != null && v.remark!.trim().isNotEmpty)
            ? ' : ${v.remark!.trim()}'
            : '';
        return '${v.verifyTypeName} (${v.verifyBy} ${_fmtShortDt(v.verifyDate)})$remark';
      }).join(' | ');

      final caseText = (casesMap[it.recordTagId] ?? const []).map((c) {
        final state = c.isOpen ? 'ยังเปิด' : 'ปิดแล้ว';
        final closePart = c.isOpen
            ? ''
            : ' ปิด ${c.closeUser ?? '-'} ${_fmtShortDt(c.closeDate)}';
        final solvePart = (c.solvingDescription != null &&
                c.solvingDescription!.trim().isNotEmpty)
            ? ' : ${c.solvingDescription!.trim()}'
            : '';
        return '#${c.problemId} [$state] เปิด ${c.createUser} ${_fmtShortDt(c.createDate)}$closePart$solvePart';
      }).join(' | ');

      final supText = (supByPhase[it.phaseName.trim()] ?? const []).map((s) {
        final comment = (s.comment != null && s.comment!.trim().isNotEmpty)
            ? ' : ${s.comment!.trim()}'
            : '';
        return '${s.userId} ${_fmtShortDt(s.checkDateTime)}$comment';
      }).join(' | ');

      final cols = <Object?>[
        i + 1,
        doc.documentId,
        doc.formName,
        doc.machineName,
        doc.location,
        doc.lot,
        doc.createUser,
        _fmtShortDt(doc.createDate),
        it.phaseName,
        it.groupName,
        it.tagName,
        criteriaParts.join(' / '),
        it.formattedSpec,
        it.value ?? '',
        it.unit?.trim() ?? '',
        _resultThaiLabel(it.result),
        it.remark ?? '',
        verifyText,
        caseText,
        supText,
      ];
      lines.add(cols.map(_escapeCsvCell).join(','));
    }

    return '\uFEFF${lines.join('\r\n')}';
  }

  /// Downloads Tag detail CSV directly in browser (Web) or saves to Downloads/Documents (Desktop/Mobile).
  Future<String?> exportDetailCsvFile() async {
    final doc = _currentDocument;
    final detail = _currentDetail;
    if (doc == null || detail == null || detail.items.isEmpty) return null;

    final content = buildDetailCsvContent();
    final safeDocId =
        doc.documentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'checksheet_detail_$safeDocId.csv';
    return saveCsvFile(fileName, content);
  }
}
