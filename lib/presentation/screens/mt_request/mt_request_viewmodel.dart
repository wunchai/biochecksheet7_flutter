// lib/presentation/screens/mt_request/mt_request_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/models/mt_request_models.dart';
import 'package:biochecksheet7_flutter/data/network/mt_request_api_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';

class MtRequestActionResult {
  final bool success;
  final String? message;
  final MtRequestDetail? detail;

  const MtRequestActionResult({
    required this.success,
    this.message,
    this.detail,
  });
}

class MtRequestViewModel extends ChangeNotifier {
  final MtRequestApiService _apiService;
  final JobDao _jobDao;
  final LoginRepository _loginRepository;

  MtRequestViewModel({
    required MtRequestApiService apiService,
    required AppDatabase appDatabase,
    required LoginRepository loginRepository,
  })  : _apiService = apiService,
        _jobDao = appDatabase.jobDao,
        _loginRepository = loginRepository;

  // --- Lookups ---
  MtRequestLookups? _lookups;
  MtRequestLookups? get lookups => _lookups;
  bool _isLoadingLookups = false;
  bool get isLoadingLookups => _isLoadingLookups;

  // --- Request List (List command) ---
  List<MtRequestListItem> _requests = [];
  List<MtRequestListItem> get requests => _requests;
  bool _isLoadingRequests = false;
  bool get isLoadingRequests => _isLoadingRequests;
  bool _hasLoadedRequests = false;
  bool get hasLoadedRequests => _hasLoadedRequests;
  String? _requestsError;
  String? get requestsError => _requestsError;

  DateTime? _fromDate;
  DateTime? _toDate;
  int? _filterStatus;
  int? _filterJobId;

  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int? get filterStatus => _filterStatus;
  int? get filterJobId => _filterJobId;

  String? get fromDateIso => _fromDate == null ? null : _iso(_fromDate!);
  String? get toDateIso => _toDate == null ? null : _iso(_toDate!);

  // --- Case List (CaseList command for creating a new MT Request) ---
  List<MtCaseListItem> _caseList = [];
  List<MtCaseListItem> get caseList => _caseList;
  bool _isLoadingCases = false;
  bool get isLoadingCases => _isLoadingCases;
  bool _hasLoadedCases = false;
  bool get hasLoadedCases => _hasLoadedCases;
  String? _casesError;
  String? get casesError => _casesError;

  int? _caseFilterJobId;
  bool _onlyOpenCases = true;
  final Set<int> _selectedProblemIds = {};
  int? _selectedCasesJobId;

  int? get caseFilterJobId => _caseFilterJobId;
  bool get onlyOpenCases => _onlyOpenCases;
  Set<int> get selectedProblemIds => Set.unmodifiable(_selectedProblemIds);
  int? get selectedCasesJobId => _selectedCasesJobId;

  // --- Detail (Detail & Write commands) ---
  MtRequestDetail? _currentDetail;
  MtRequestDetail? get currentDetail => _currentDetail;
  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  String? _detailError;
  String? get detailError => _detailError;

  Stream<List<DbJob>> get jobsStream =>
      _jobDao.watchAllJobs(showCanceledJobs: false);

  String get currentUserId =>
      _loginRepository.loggedInUser?.userId ?? '000000';

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // --- Lookups ---
  Future<void> ensureLookupsLoaded() async {
    if (_lookups != null || _isLoadingLookups) return;
    _isLoadingLookups = true;
    notifyListeners();
    try {
      _lookups = await _apiService.getLookups();
    } catch (e) {
      debugPrint('[MtRequestViewModel] Failed to load Lookups: $e');
    } finally {
      _isLoadingLookups = false;
      notifyListeners();
    }
  }

  // --- Request List Filters & Loading ---
  void setDateRange({DateTime? from, DateTime? to}) {
    _fromDate = from == null ? null : DateTime(from.year, from.month, from.day);
    _toDate = to == null ? null : DateTime(to.year, to.month, to.day);
    notifyListeners();
  }

  void setFromDate(DateTime? from) {
    _fromDate = from == null ? null : DateTime(from.year, from.month, from.day);
    notifyListeners();
  }

  void setToDate(DateTime? to) {
    _toDate = to == null ? null : DateTime(to.year, to.month, to.day);
    notifyListeners();
  }

  Future<void> setFilterStatus(int? status) async {
    _filterStatus = status;
    notifyListeners();
    await loadRequests();
  }

  Future<void> setFilterJobId(int? jobId) async {
    _filterJobId = jobId;
    notifyListeners();
    await loadRequests();
  }

  Future<void> loadRequests() async {
    await ensureLookupsLoaded();
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      _requestsError = 'วันที่เริ่มต้องไม่เกินวันที่สิ้นสุด';
      notifyListeners();
      return;
    }

    _isLoadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      _requests = await _apiService.getRequestList(
        fromDate: fromDateIso,
        toDate: toDateIso,
        status: _filterStatus,
        jobId: _filterJobId,
      );
      _hasLoadedRequests = true;
    } catch (e) {
      _requestsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  // --- Case List Filters, Selection & Loading ---
  Future<void> setCaseFilterJobId(int? jobId) async {
    _caseFilterJobId = jobId;
    _selectedProblemIds.clear();
    _selectedCasesJobId = null;
    notifyListeners();
    await loadCases();
  }

  Future<void> setOnlyOpenCases(bool value) async {
    _onlyOpenCases = value;
    _selectedProblemIds.clear();
    _selectedCasesJobId = null;
    notifyListeners();
    await loadCases();
  }

  Future<void> loadCases() async {
    await ensureLookupsLoaded();
    _isLoadingCases = true;
    _casesError = null;
    notifyListeners();

    try {
      _caseList = await _apiService.getCaseList(
        jobId: _caseFilterJobId,
        onlyOpen: _onlyOpenCases,
      );
      _hasLoadedCases = true;

      // Remove any previously selected IDs that are no longer selectable.
      final validIds = _caseList
          .where((c) => c.canSelectForNewRequest)
          .map((c) => c.problemId)
          .toSet();
      _selectedProblemIds.removeWhere((id) => !validIds.contains(id));
      if (_selectedProblemIds.isEmpty) {
        _selectedCasesJobId = null;
      }
    } catch (e) {
      _casesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingCases = false;
      notifyListeners();
    }
  }

  /// Fetches open & available cases for a specific job (used by AddCases dialog).
  Future<List<MtCaseListItem>> fetchAvailableCasesForJob(int jobId) async {
    final all = await _apiService.getCaseList(jobId: jobId, onlyOpen: true);
    return all.where((c) => c.canSelectForNewRequest).toList();
  }

  bool canToggleCase(MtCaseListItem item) {
    if (!item.canSelectForNewRequest) return false;
    if (_selectedCasesJobId != null && _selectedCasesJobId != item.jobId) {
      return false;
    }
    return true;
  }

  void toggleCaseSelection(MtCaseListItem item) {
    if (_selectedProblemIds.contains(item.problemId)) {
      _selectedProblemIds.remove(item.problemId);
      if (_selectedProblemIds.isEmpty) {
        _selectedCasesJobId = null;
      }
      notifyListeners();
      return;
    }

    if (!canToggleCase(item)) return;
    _selectedProblemIds.add(item.problemId);
    _selectedCasesJobId = item.jobId;
    notifyListeners();
  }

  void clearCaseSelection() {
    _selectedProblemIds.clear();
    _selectedCasesJobId = null;
    notifyListeners();
  }

  // --- Detail Loading ---
  Future<void> loadDetail(int id) async {
    await ensureLookupsLoaded();
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      _currentDetail = await _apiService.getDetail(id);
    } catch (e) {
      _detailError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void setCurrentDetail(MtRequestDetail detail) {
    _currentDetail = detail;
    _detailError = null;
    notifyListeners();
  }

  // --- Write Commands (all return fresh Detail per API spec) ---
  Future<MtRequestActionResult> createRequest({String? description}) async {
    if (_selectedProblemIds.isEmpty) {
      return const MtRequestActionResult(
        success: false,
        message: 'กรุณาเลือกอย่างน้อย 1 เคส',
      );
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final detail = await _apiService.create(
        problemIds: _selectedProblemIds.toList(),
        description: description,
        user: currentUserId,
      );
      _currentDetail = detail;
      _selectedProblemIds.clear();
      _selectedCasesJobId = null;
      _isSubmitting = false;
      notifyListeners();

      // Refresh background lists silently.
      loadCases();
      loadRequests();

      return MtRequestActionResult(
        success: true,
        message: 'สร้างใบแจ้งซ่อม (ร่าง #${detail.header.id}) สำเร็จ',
        detail: detail,
      );
    } on MtRequestApiException catch (e) {
      _isSubmitting = false;
      notifyListeners();
      if (e.shouldReload) {
        loadCases();
        loadRequests();
      }
      return MtRequestActionResult(success: false, message: e.message);
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return MtRequestActionResult(
        success: false,
        message: 'สร้างใบแจ้งซ่อมไม่สำเร็จ: $e',
      );
    }
  }

  Future<MtRequestActionResult> addCasesToCurrent(List<int> problemIds) async {
    final detail = _currentDetail;
    if (detail == null || problemIds.isEmpty) {
      return const MtRequestActionResult(
          success: false, message: 'กรุณาเลือกเคสที่ต้องการเพิ่ม');
    }
    return _runDetailWrite(
      action: () => _apiService.addCases(
        id: detail.header.id,
        problemIds: problemIds,
        user: currentUserId,
      ),
      successMessage: 'เพิ่มเคสเข้าใบแจ้งซ่อมสำเร็จ',
      refreshCasesToo: true,
    );
  }

  Future<MtRequestActionResult> removeCaseFromCurrent(int problemId) async {
    final detail = _currentDetail;
    if (detail == null) {
      return const MtRequestActionResult(
          success: false, message: 'ไม่พบข้อมูลใบแจ้งซ่อม');
    }
    return _runDetailWrite(
      action: () => _apiService.removeCase(
        id: detail.header.id,
        problemId: problemId,
        user: currentUserId,
      ),
      successMessage: 'ลบเคส #$problemId ออกจากใบแจ้งซ่อมแล้ว',
      refreshCasesToo: true,
    );
  }

  Future<MtRequestActionResult> updateCurrentDescription(
      String? description) async {
    final detail = _currentDetail;
    if (detail == null) {
      return const MtRequestActionResult(
          success: false, message: 'ไม่พบข้อมูลใบแจ้งซ่อม');
    }
    return _runDetailWrite(
      action: () => _apiService.updateDescription(
        id: detail.header.id,
        description: description,
        user: currentUserId,
      ),
      successMessage: 'บันทึกรายละเอียดปัญหาแล้ว',
    );
  }

  Future<MtRequestActionResult> setCurrentRequestNo(String requestNo) async {
    final detail = _currentDetail;
    if (detail == null) {
      return const MtRequestActionResult(
          success: false, message: 'ไม่พบข้อมูลใบแจ้งซ่อม');
    }
    if (requestNo.trim().isEmpty) {
      return const MtRequestActionResult(
          success: false, message: 'กรุณาระบุเลขใบแจ้งซ่อม (RequestNo)');
    }
    return _runDetailWrite(
      action: () => _apiService.setRequestNo(
        id: detail.header.id,
        requestNo: requestNo,
        user: currentUserId,
      ),
      successMessage: 'บันทึกเลขใบแจ้งซ่อม ${requestNo.trim()} สำเร็จ',
      refreshCasesToo: true,
    );
  }

  Future<MtRequestActionResult> closeCurrentRequest({
    required List<MtCloseCaseInput> results,
    String? closeNote,
  }) async {
    final detail = _currentDetail;
    if (detail == null) {
      return const MtRequestActionResult(
          success: false, message: 'ไม่พบข้อมูลใบแจ้งซ่อม');
    }
    return _runDetailWrite(
      action: () => _apiService.close(
        id: detail.header.id,
        results: results,
        closeNote: closeNote,
        user: currentUserId,
      ),
      successMessage: 'ปิดงานใบแจ้งซ่อมสำเร็จ',
      refreshCasesToo: true,
    );
  }

  Future<MtRequestActionResult> cancelCurrentRequest({String? note}) async {
    final detail = _currentDetail;
    if (detail == null) {
      return const MtRequestActionResult(
          success: false, message: 'ไม่พบข้อมูลใบแจ้งซ่อม');
    }
    return _runDetailWrite(
      action: () => _apiService.cancel(
        id: detail.header.id,
        note: note,
        user: currentUserId,
      ),
      successMessage: 'ยกเลิกใบแจ้งซ่อมแล้ว (เคสทั้งหมดยังคงเปิดอยู่)',
      refreshCasesToo: true,
    );
  }

  Future<MtRequestActionResult> _runDetailWrite({
    required Future<MtRequestDetail> Function() action,
    required String successMessage,
    bool refreshCasesToo = false,
  }) async {
    final currentId = _currentDetail?.header.id;
    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await action();
      _currentDetail = updated;
      _detailError = null;
      _isSubmitting = false;
      notifyListeners();

      loadRequests();
      if (refreshCasesToo) loadCases();

      return MtRequestActionResult(
        success: true,
        message: successMessage,
        detail: updated,
      );
    } on MtRequestApiException catch (e) {
      _isSubmitting = false;
      notifyListeners();
      // Per API spec Section 2 & 4: on 400/404 show Thai message and reload fresh state.
      if (e.shouldReload) {
        if (currentId != null && e.httpStatus != 404) {
          loadDetail(currentId);
        }
        loadRequests();
        if (refreshCasesToo) loadCases();
      }
      return MtRequestActionResult(success: false, message: e.message);
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return MtRequestActionResult(
        success: false,
        message: 'ดำเนินการไม่สำเร็จ: $e',
      );
    }
  }
}
