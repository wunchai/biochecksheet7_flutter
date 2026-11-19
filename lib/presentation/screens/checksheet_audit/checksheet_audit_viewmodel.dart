// lib/presentation/screens/checksheet_audit/checksheet_audit_viewmodel.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biochecksheet7_flutter/data/models/checksheet_audit_models.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';

class ChecksheetAuditViewModel extends ChangeNotifier {
  static const _prefFromKey = 'csAuditFrom';
  static const _prefToKey = 'csAuditTo';
  static const _prefFormKey = 'csAuditForm';
  static const _prefPhaseKey = 'csAuditPhase';

  final DocumentOnlineApiService _apiService;

  ChecksheetAuditViewModel(this._apiService) {
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate.subtract(const Duration(days: 6));
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

  bool _hasInitialized = false;
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
  Future<void> initializeIfNeeded() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFrom = prefs.getString(_prefFromKey);
      final savedTo = prefs.getString(_prefToKey);
      final savedForm = prefs.getString(_prefFormKey);
      final savedPhase = prefs.getString(_prefPhaseKey);

      if (savedFrom != null) {
        final d = DateTime.tryParse(savedFrom);
        if (d != null) _fromDate = DateTime(d.year, d.month, d.day);
      }
      if (savedTo != null) {
        final d = DateTime.tryParse(savedTo);
        if (d != null) _toDate = DateTime(d.year, d.month, d.day);
      }
      if (savedForm != null && savedForm.isNotEmpty) {
        _selectedForm = savedForm;
      }
      if (savedPhase != null && savedPhase.isNotEmpty) {
        _selectedPhase = savedPhase;
      }
    } catch (_) {
      // Ignore preference read errors and keep default 7-day window.
    }

    await loadDocuments();
  }

  void setFromDate(DateTime date) {
    _fromDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setToDate(DateTime date) {
    _toDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<void> setSelectedForm(String? form) async {
    _selectedForm = (form == null || form.isEmpty) ? null : form;
    _currentDocument = null;
    _currentDetail = null;
    _detailError = null;
    notifyListeners();
    await _saveFilters();
  }

  Future<void> setSelectedPhase(String? phase) async {
    _selectedPhase = (phase == null || phase.isEmpty) ? null : phase;
    _currentDocument = null;
    _currentDetail = null;
    _detailError = null;
    notifyListeners();
    await _saveFilters();
  }

  Future<void> _saveRange(String from, String to) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFromKey, from);
      await prefs.setString(_prefToKey, to);
    } catch (_) {}
  }

  Future<void> _saveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFormKey, _selectedForm ?? '');
      await prefs.setString(_prefPhaseKey, _selectedPhase ?? '');
    } catch (_) {}
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

      await _saveRange(from, to);
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

    String escapeCell(Object? raw) {
      final s = raw?.toString() ?? '';
      if (s.contains('"') ||
          s.contains(',') ||
          s.contains('\n') ||
          s.contains('\r')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    final lines = <String>[
      headers.map(escapeCell).join(','),
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
        return cols.map(escapeCell).join(',');
      }),
    ];

    return '\uFEFF${lines.join('\r\n')}';
  }

  /// Saves CSV file to Downloads (or App Documents fallback). Returns saved file path, or null on Web.
  Future<String?> exportCsvFile() async {
    if (filteredDocs.isEmpty) return null;
    final content = buildCsvContent();
    if (kIsWeb) return null;

    Directory? targetDir;
    try {
      targetDir = await getDownloadsDirectory();
    } catch (_) {
      targetDir = null;
    }
    targetDir ??= await getApplicationDocumentsDirectory();

    final from = _loadedFromDate ?? fromDateIso;
    final to = _loadedToDate ?? toDateIso;
    final fileName = 'checksheet_${from}_$to.csv';
    final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(utf8.encode(content), flush: true);
    return file.path;
  }
}
