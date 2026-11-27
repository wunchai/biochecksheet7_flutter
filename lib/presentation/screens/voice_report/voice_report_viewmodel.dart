// lib/presentation/screens/voice_report/voice_report_viewmodel.dart
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/core/utils/voice_file_helper.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/models/voice_report_models.dart';
import 'package:biochecksheet7_flutter/data/network/voice_report_api_service.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/services/device_info_service.dart';

class VoiceActionFeedback {
  final bool success;
  final String message;

  const VoiceActionFeedback({required this.success, required this.message});
}

class VoiceReportViewModel extends ChangeNotifier {
  static const String _prefShiftJobIdKey = 'voice_shift_job_id_v1';
  static const String _prefOfflineQueueKey = 'voice_offline_queue_v1';
  static const int maxDurationSeconds =
      120; // Hard 2-minute cutoff per Section 4.1

  final VoiceReportApiService _apiService;
  final JobDao _jobDao;
  final LoginRepository _loginRepository;
  final DeviceInfoService _deviceInfoService;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Uuid _uuid = const Uuid();

  VoiceReportViewModel({
    required VoiceReportApiService apiService,
    required AppDatabase appDatabase,
    required LoginRepository loginRepository,
    required DeviceInfoService deviceInfoService,
  })  : _apiService = apiService,
        _jobDao = appDatabase.jobDao,
        _loginRepository = loginRepository,
        _deviceInfoService = deviceInfoService {
    _initPlayerListeners();
  }

  bool _initialized = false;
  bool _isTabActive = false;

  // --- Shift Job (remembered across the shift per Section 10.1) ---
  int? _shiftJobId;
  int? get shiftJobId => _shiftJobId;

  Stream<List<DbJob>> get jobsStream =>
      _jobDao.watchAllJobs(showCanceledJobs: false);

  String get currentUserId => _loginRepository.loggedInUser?.userId ?? '000000';

  // --- Lookups ---
  VoiceLookups? _lookups;
  VoiceLookups? get lookups => _lookups;
  bool _isLoadingLookups = false;

  // --- Recording State ---
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  double _recordingElapsedSec = 0.0;
  double get recordingElapsedSec => _recordingElapsedSec;
  Timer? _recordingTimer;
  DateTime? _recordingStartedAt;
  String? _activeRecordingClientId;
  String _activeRecordingMime = 'audio/mp4';
  String _activeRecordingFileName = 'voice.m4a';

  // --- Draft Preview State (after stop, before submit) ---
  String? _draftClientRecordId;
  String? _draftFilePath;
  Uint8List? _draftWebBytes;
  String? _draftMimeType;
  String? _draftFileName;
  DateTime? _draftRecordedAt;
  double _draftDurationSec = 0.0;
  String? _recordingNotice;

  bool get hasDraft =>
      _draftClientRecordId != null &&
      ((_draftFilePath != null && _draftFilePath!.isNotEmpty) ||
          _draftWebBytes != null);
  double get draftDurationSec => _draftDurationSec;
  DateTime? get draftRecordedAt => _draftRecordedAt;
  String? get recordingNotice => _recordingNotice;

  // --- Audio Playback State (Draft preview OR Remote report audioUrl) ---
  String? _playingSourceKey; // 'draft' or report.id or queued.clientRecordId
  String? get playingSourceKey => _playingSourceKey;
  bool _isPlayingAudio = false;
  bool get isPlayingAudio => _isPlayingAudio;
  Duration _playbackPosition = Duration.zero;
  Duration get playbackPosition => _playbackPosition;
  Duration _playbackDuration = Duration.zero;
  Duration get playbackDuration => _playbackDuration;

  // --- Offline Queue (Section 4.3) ---
  List<VoiceQueuedRecord> _offlineQueue = [];
  List<VoiceQueuedRecord> get offlineQueue => List.unmodifiable(_offlineQueue);
  bool _isProcessingQueue = false;
  bool get isProcessingQueue => _isProcessingQueue;
  Timer? _queueRetryTimer;
  // In-memory web audio bytes keyed by clientRecordId for current session retries on Web
  final Map<String, Uint8List> _webQueuedBytes = {};

  // --- History List & Active Polling (`List` & `Detail`, Section 5 & 6) ---
  List<VoiceReportItem> _reports = [];
  List<VoiceReportItem> get reports => List.unmodifiable(_reports);
  bool _isLoadingReports = false;
  bool get isLoadingReports => _isLoadingReports;
  String? _reportsError;
  String? get reportsError => _reportsError;

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();
  int? _filterStatus;
  int? _filterJobId;
  bool _onlyMyReports = true;

  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int? get filterStatus => _filterStatus;
  int? get filterJobId => _filterJobId;
  bool get onlyMyReports => _onlyMyReports;

  String? get fromDateIso => _fromDate == null ? null : _isoDate(_fromDate!);
  String? get toDateIso => _toDate == null ? null : _isoDate(_toDate!);

  // Polling tracking: reportId -> first poll timestamp
  final Map<String, DateTime> _pollingStartedAt = {};
  final Map<String, Timer> _pollingTimers = {};
  Set<String> get activePollingIds => Set.unmodifiable(_pollingTimers.keys);

  // Full 4-table Detail cache keyed by report.id
  final Map<String, VoiceReportDetail> _detailsById = {};
  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;
  bool _isSavingSummary = false;
  bool get isSavingSummary => _isSavingSummary;

  VoiceReportDetail? detailFor(String reportId) => _detailsById[reportId];

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _initPlayerListeners() {
    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlayingAudio != playing) {
        _isPlayingAudio = playing;
        notifyListeners();
      }
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _isPlayingAudio = false;
        _playbackPosition = Duration.zero;
        notifyListeners();
      }
    });
    _player.onPositionChanged.listen((pos) {
      _playbackPosition = pos;
      notifyListeners();
    });
    _player.onDurationChanged.listen((dur) {
      _playbackDuration = dur;
      notifyListeners();
    });
  }

  /// Called when the Voice Report tab becomes visible or hidden.
  Future<void> onTabVisibilityChanged(bool visible) async {
    _isTabActive = visible;
    if (!visible) {
      // Section 5: "และหยุดถามเมื่อผู้ใช้ออกจากหน้าจอ"
      _stopAllPollingTimers();
      await stopAudioPlayback();
      return;
    }

    if (!_initialized) {
      _initialized = true;
      await _loadPersistedState();
      await ensureLookupsLoaded();
      await loadReports();
      processOfflineQueue();
    } else {
      _resumePollingForPendingReports();
      processOfflineQueue();
    }
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _shiftJobId = prefs.getInt(_prefShiftJobIdKey);

      final rawQueue = prefs.getString(_prefOfflineQueueKey);
      if (rawQueue != null && rawQueue.isNotEmpty) {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          final loaded = <VoiceQueuedRecord>[];
          for (final item in decoded) {
            if (item is Map) {
              final rec =
                  VoiceQueuedRecord.fromJson(Map<String, dynamic>.from(item));
              if (!kIsWeb && await voiceFileExists(rec.filePath)) {
                loaded.add(rec);
              }
            }
          }
          _offlineQueue = loaded;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceReportViewModel] Failed to load persisted state: $e');
    }
  }

  Future<void> _persistOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_offlineQueue.map((e) => e.toJson()).toList());
      await prefs.setString(_prefOfflineQueueKey, encoded);
    } catch (e) {
      debugPrint('[VoiceReportViewModel] Failed to persist offline queue: $e');
    }
  }

  Future<void> setShiftJobId(int? jobId) async {
    _shiftJobId = jobId;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (jobId == null) {
        await prefs.remove(_prefShiftJobIdKey);
      } else {
        await prefs.setInt(_prefShiftJobIdKey, jobId);
      }
    } catch (_) {}
  }

  Future<void> ensureLookupsLoaded() async {
    if (_lookups != null || _isLoadingLookups) return;
    _isLoadingLookups = true;
    try {
      _lookups = await _apiService.getLookups();
    } catch (e) {
      debugPrint('[VoiceReportViewModel] Lookups load error: $e');
    } finally {
      _isLoadingLookups = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 1. AUDIO RECORDING (AAC-LC .m4a on Mobile/Desktop, Opus .webm on Web, 120s cutoff)
  // ===========================================================================
  Future<VoiceActionFeedback> startRecording() async {
    if (_isRecording) {
      return const VoiceActionFeedback(
          success: false, message: 'กำลังบันทึกเสียงอยู่แล้ว');
    }
    if (_shiftJobId == null) {
      return const VoiceActionFeedback(
          success: false,
          message: 'กรุณาเลือกใบงาน (Job) ประจำกะก่อนเริ่มบันทึกเสียง');
    }

    await stopAudioPlayback();

    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        return const VoiceActionFeedback(
          success: false,
          message:
              'ไม่ได้รับอนุญาตให้ใช้ไมโครโฟน กรุณาเปิดสิทธิ์ไมโครโฟนในการตั้งค่า',
        );
      }

      // Discard previous unsent draft if any
      await discardDraft();

      final clientId = _uuid.v4();
      _activeRecordingClientId = clientId;
      _recordingNotice = null;

      RecordConfig config;
      String? targetPath;

      if (kIsWeb) {
        final opusSupported =
            await _recorder.isEncoderSupported(AudioEncoder.opus);
        if (opusSupported) {
          config = const RecordConfig(encoder: AudioEncoder.opus);
          _activeRecordingMime = 'audio/webm';
          _activeRecordingFileName = 'voice.webm';
        } else {
          // Safari fallback (.mp4 / .m4a)
          config = const RecordConfig(encoder: AudioEncoder.aacLc);
          _activeRecordingMime = 'audio/mp4';
          _activeRecordingFileName = 'voice.m4a';
        }
        targetPath = '';
      } else {
        // Section 4.1 & 11: Android/iOS MUST use AAC-LC in .m4a container (NEVER raw .aac ADTS)
        config = const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
        _activeRecordingMime = 'audio/mp4';
        _activeRecordingFileName = 'voice.m4a';
        targetPath = await prepareVoiceRecordingPath(clientId, 'm4a') ?? '';
      }

      _recordingStartedAt = DateTime.now();
      _recordingElapsedSec = 0.0;
      _isRecording = true;
      notifyListeners();

      await _recorder.start(config, path: targetPath);

      _recordingTimer?.cancel();
      _recordingTimer =
          Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (!_isRecording || _recordingStartedAt == null) {
          timer.cancel();
          return;
        }
        final elapsedMs =
            DateTime.now().difference(_recordingStartedAt!).inMilliseconds;
        _recordingElapsedSec = elapsedMs / 1000.0;

        // Hard cutoff at 2 minutes (120 seconds) per Section 4.1 & 11
        if (_recordingElapsedSec >= maxDurationSeconds) {
          _recordingElapsedSec = maxDurationSeconds.toDouble();
          _recordingNotice =
              'ครบกำหนดเวลาสูงสุด 2 นาที ระบบหยุดอัดเสียงอัตโนมัติ';
          stopRecording();
        } else {
          notifyListeners();
        }
      });

      return const VoiceActionFeedback(
          success: true, message: 'เริ่มบันทึกเสียงแล้ว');
    } catch (e) {
      _isRecording = false;
      _recordingTimer?.cancel();
      notifyListeners();
      return VoiceActionFeedback(
          success: false, message: 'เริ่มอัดเสียงไม่สำเร็จ: $e');
    }
  }

  Future<VoiceActionFeedback> stopRecording() async {
    if (!_isRecording) {
      return const VoiceActionFeedback(
          success: false, message: 'ไม่ได้อยู่ในสถานะกำลังอัดเสียง');
    }

    _recordingTimer?.cancel();
    _recordingTimer = null;
    final recordedAt = _recordingStartedAt ?? DateTime.now();
    final duration =
        _recordingElapsedSec.clamp(0.5, maxDurationSeconds.toDouble());
    _isRecording = false;
    notifyListeners();

    try {
      final pathOrUrl = await _recorder.stop();
      if (pathOrUrl == null || pathOrUrl.isEmpty) {
        return const VoiceActionFeedback(
            success: false, message: 'ไม่พบข้อมูลเสียงที่บันทึก');
      }

      if (kIsWeb) {
        final res = await http.get(Uri.parse(pathOrUrl));
        _draftWebBytes = res.bodyBytes;
        _draftFilePath = pathOrUrl;
      } else {
        _draftFilePath = pathOrUrl;
        _draftWebBytes = null;
      }

      _draftClientRecordId = _activeRecordingClientId ?? _uuid.v4();
      _draftMimeType = _activeRecordingMime;
      _draftFileName = _activeRecordingFileName;
      _draftRecordedAt = recordedAt;
      _draftDurationSec = duration;
      notifyListeners();

      return const VoiceActionFeedback(
        success: true,
        message: 'บันทึกเสียงเรียบร้อย สามารถฟังทวนหรือกดส่งได้',
      );
    } catch (e) {
      notifyListeners();
      return VoiceActionFeedback(
          success: false, message: 'หยุดบันทึกเสียงไม่สำเร็จ: $e');
    }
  }

  Future<void> discardDraft() async {
    await stopAudioPlayback();
    final oldPath = _draftFilePath;
    _draftClientRecordId = null;
    _draftFilePath = null;
    _draftWebBytes = null;
    _draftRecordedAt = null;
    _draftDurationSec = 0.0;
    _recordingNotice = null;
    notifyListeners();
    if (!kIsWeb && oldPath != null) {
      await deleteVoiceFileIfExists(oldPath);
    }
  }

  // ===========================================================================
  // 2. AUDIO PLAYBACK (Draft preview, Queued local file, or Remote audioUrl)
  // ===========================================================================
  Future<void> togglePlayDraft() async {
    if (!hasDraft) return;
    if (_playingSourceKey == 'draft' && _isPlayingAudio) {
      await _player.pause();
      return;
    }
    await _startPlayback(
      sourceKey: 'draft',
      localPath: _draftFilePath,
      webBytes: _draftWebBytes,
      mimeType: _draftMimeType,
    );
  }

  Future<void> togglePlayQueued(VoiceQueuedRecord item) async {
    final key = 'queue_${item.clientRecordId}';
    if (_playingSourceKey == key && _isPlayingAudio) {
      await _player.pause();
      return;
    }
    await _startPlayback(
      sourceKey: key,
      localPath: item.filePath,
      webBytes: _webQueuedBytes[item.clientRecordId],
      mimeType: item.mimeType,
    );
  }

  Future<VoiceActionFeedback?> togglePlayRemoteReport(
      VoiceReportItem report) async {
    final key = 'report_${report.id}';
    if (_playingSourceKey == key && _isPlayingAudio) {
      await _player.pause();
      return null;
    }
    final url = report.resolveAudioUrl(AppConfig.baseUrl);
    try {
      await _player.stop();
      _playingSourceKey = key;
      _playbackPosition = Duration.zero;
      _playbackDuration =
          Duration(milliseconds: (report.durationSec * 1000).round());
      notifyListeners();
      await _player.play(UrlSource(url));
      return null;
    } catch (e) {
      _playingSourceKey = null;
      _isPlayingAudio = false;
      notifyListeners();
      return VoiceActionFeedback(
          success: false, message: 'เปิดฟังไฟล์เสียงไม่สำเร็จ: $e');
    }
  }

  Future<void> _startPlayback({
    required String sourceKey,
    String? localPath,
    Uint8List? webBytes,
    String? mimeType,
  }) async {
    try {
      await _player.stop();
      _playingSourceKey = sourceKey;
      _playbackPosition = Duration.zero;
      notifyListeners();

      if (kIsWeb) {
        if (webBytes != null) {
          await _player.play(BytesSource(webBytes, mimeType: mimeType));
        } else if (localPath != null && localPath.isNotEmpty) {
          await _player.play(UrlSource(localPath));
        }
      } else if (localPath != null && localPath.isNotEmpty) {
        await _player.play(DeviceFileSource(localPath));
      }
    } catch (e) {
      _playingSourceKey = null;
      _isPlayingAudio = false;
      notifyListeners();
      debugPrint('[VoiceReportViewModel] Playback error: $e');
    }
  }

  Future<void> stopAudioPlayback() async {
    try {
      await _player.stop();
    } catch (_) {}
    _playingSourceKey = null;
    _isPlayingAudio = false;
    _playbackPosition = Duration.zero;
    notifyListeners();
  }

  // ===========================================================================
  // 3. SUBMIT DRAFT -> OFFLINE QUEUE -> UPLOAD (Section 4.2, 4.3, 4.5)
  // ===========================================================================
  Future<VoiceActionFeedback> submitDraft({String? jobLabel}) async {
    if (!hasDraft || _draftClientRecordId == null) {
      return const VoiceActionFeedback(
          success: false, message: 'ไม่มีไฟล์เสียงที่รอส่ง');
    }
    if (_shiftJobId == null) {
      return const VoiceActionFeedback(
          success: false, message: 'กรุณาเลือกใบงาน (Job) ก่อนส่ง');
    }

    await stopAudioPlayback();

    final appVersion = await _deviceInfoService.getAppVersion();
    final clientRecordId = _draftClientRecordId!;
    final recordedAtIso =
        formatVoiceIsoWithOffset(_draftRecordedAt ?? DateTime.now());

    final queuedItem = VoiceQueuedRecord(
      clientRecordId: clientRecordId,
      userId: currentUserId,
      jobId: _shiftJobId!,
      jobLabel: jobLabel,
      recordedAtIso: recordedAtIso,
      durationSec: _draftDurationSec,
      platform: detectVoicePlatformName(),
      appVersion: appVersion,
      filePath: _draftFilePath,
      mimeType: _draftMimeType ?? 'audio/mp4',
      fileName: _draftFileName ?? 'voice.m4a',
    );

    if (kIsWeb && _draftWebBytes != null) {
      _webQueuedBytes[clientRecordId] = _draftWebBytes!;
    }

    // 1. Save to local queue FIRST before attempting upload (Section 4.3 rule 1)
    _offlineQueue.insert(0, queuedItem);
    await _persistOfflineQueue();

    // Clear draft pointer (do NOT delete the file on disk because it now belongs to the queue!)
    _draftClientRecordId = null;
    _draftFilePath = null;
    _draftWebBytes = null;
    _draftRecordedAt = null;
    _draftDurationSec = 0.0;
    _recordingNotice = null;
    notifyListeners();

    // 2. Immediately attempt to upload this item
    return _uploadQueuedItem(queuedItem, isManualTrigger: true);
  }

  Future<VoiceActionFeedback> _uploadQueuedItem(
    VoiceQueuedRecord item, {
    bool isManualTrigger = false,
  }) async {
    _isProcessingQueue = true;
    notifyListeners();

    try {
      final uploaded = await _apiService.uploadVoice(
        filePath: kIsWeb ? null : item.filePath,
        fileBytes: kIsWeb ? _webQueuedBytes[item.clientRecordId] : null,
        fileName: item.fileName,
        mimeType: item.mimeType,
        clientRecordId: item.clientRecordId,
        userId: item.userId,
        jobId: item.jobId,
        recordedAtIso: item.recordedAtIso,
        durationSec: item.durationSec,
        platform: item.platform,
        appVersion: item.appVersion,
      );

      // Rule 2: HTTP 200 -> remove from offline queue & delete local file, then poll Detail
      _offlineQueue.removeWhere((q) => q.clientRecordId == item.clientRecordId);
      _webQueuedBytes.remove(item.clientRecordId);
      await _persistOfflineQueue();
      if (!kIsWeb) {
        await deleteVoiceFileIfExists(item.filePath);
      }

      _cacheDetail(uploaded);
      if (uploaded.report.shouldKeepPolling && _isTabActive) {
        _startPollingReport(uploaded.report.id);
      }

      _isProcessingQueue = false;
      notifyListeners();
      return const VoiceActionFeedback(
        success: true,
        message: 'ส่งไฟล์เสียงสำเร็จ ระบบกำลังถอดเสียงเป็นข้อความ...',
      );
    } on VoiceRejectedException catch (e) {
      // Rule 3: HTTP 400 -> do NOT auto-retry! Mark rejected and show Thai message.
      final idx = _offlineQueue
          .indexWhere((q) => q.clientRecordId == item.clientRecordId);
      if (idx != -1) {
        _offlineQueue[idx] = _offlineQueue[idx].copyWith(
          attempts: _offlineQueue[idx].attempts + 1,
          lastError: e.message,
          isRejected400: true,
          clearNextRetry: true,
        );
        await _persistOfflineQueue();
      }
      _isProcessingQueue = false;
      notifyListeners();
      return VoiceActionFeedback(success: false, message: e.message);
    } catch (e) {
      // Rule 4 & 5: HTTP 500 / timeout / network offline -> NEVER delete file; schedule backoff retry
      final newAttempts = item.attempts + 1;
      final backoff = VoiceQueuedRecord.backoffForAttempt(newAttempts);
      final nextRetryMs = DateTime.now().add(backoff).millisecondsSinceEpoch;
      final errMsg = e.toString().replaceFirst('Exception: ', '');

      final idx = _offlineQueue
          .indexWhere((q) => q.clientRecordId == item.clientRecordId);
      if (idx != -1) {
        _offlineQueue[idx] = _offlineQueue[idx].copyWith(
          attempts: newAttempts,
          lastError: errMsg,
          isRejected400: false,
          nextRetryAtMs: nextRetryMs,
        );
        await _persistOfflineQueue();
      }

      _scheduleQueueRetry(backoff);
      _isProcessingQueue = false;
      notifyListeners();
      return VoiceActionFeedback(
        success: false,
        message: isManualTrigger
            ? 'ยังส่งไม่ได้ ($errMsg) — เก็บไฟล์ไว้ในคิวออฟไลน์แล้ว จะส่งใหม่อัตโนมัติ'
            : errMsg,
      );
    }
  }

  void _scheduleQueueRetry(Duration delay) {
    _queueRetryTimer?.cancel();
    _queueRetryTimer = Timer(delay, () {
      processOfflineQueue();
    });
  }

  /// Processes any non-400 items in the offline queue whose backoff timer has elapsed.
  Future<void> processOfflineQueue({bool forceAll = false}) async {
    if (_isProcessingQueue || _offlineQueue.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final pending = _offlineQueue.where((q) {
      if (q.isRejected400) return false;
      if (forceAll) return true;
      return q.nextRetryAtMs == null || q.nextRetryAtMs! <= nowMs;
    }).toList();

    for (final item in pending) {
      await _uploadQueuedItem(item, isManualTrigger: forceAll);
    }
  }

  /// Allows manual retry of a single queued item using the currently selected shift jobId
  /// (useful when user initially recorded against a jobId from another environment).
  Future<VoiceActionFeedback> retrySingleQueuedItem(
    VoiceQueuedRecord item, {
    String? currentShiftJobLabel,
  }) async {
    final idx = _offlineQueue
        .indexWhere((q) => q.clientRecordId == item.clientRecordId);
    if (idx == -1) {
      return const VoiceActionFeedback(
          success: false, message: 'ไม่พบรายการในคิว');
    }
    final updated = _offlineQueue[idx].copyWith(
      jobId: _shiftJobId ?? item.jobId,
      jobLabel: (_shiftJobId != null && _shiftJobId != item.jobId)
          ? (currentShiftJobLabel ?? 'Job $_shiftJobId')
          : item.jobLabel,
      isRejected400: false,
      clearNextRetry: true,
    );
    _offlineQueue[idx] = updated;
    await _persistOfflineQueue();
    notifyListeners();
    return _uploadQueuedItem(updated, isManualTrigger: true);
  }

  /// Deletes a queued item (e.g. when user chooses to discard a 400-rejected item).
  Future<void> removeQueuedItem(VoiceQueuedRecord item) async {
    await stopAudioPlayback();
    _offlineQueue.removeWhere((q) => q.clientRecordId == item.clientRecordId);
    _webQueuedBytes.remove(item.clientRecordId);
    await _persistOfflineQueue();
    if (!kIsWeb) {
      await deleteVoiceFileIfExists(item.filePath);
    }
    notifyListeners();
  }

  // ===========================================================================
  // 4. POLLING `Detail` (Section 5: every 5s for 1st min, then 30s; stop when status != 0/1)
  // ===========================================================================
  void _startPollingReport(String reportId) {
    if (reportId.isEmpty || !_isTabActive) return;
    _pollingStartedAt.putIfAbsent(reportId, () => DateTime.now());
    _pollingTimers[reportId]?.cancel();

    final startedAt = _pollingStartedAt[reportId]!;
    final elapsedSec = DateTime.now().difference(startedAt).inSeconds;
    final interval = elapsedSec < 60
        ? const Duration(seconds: 5)
        : const Duration(seconds: 30);

    _pollingTimers[reportId] = Timer(interval, () async {
      if (!_isTabActive) {
        _stopPollingReport(reportId);
        return;
      }
      try {
        final detail = await _apiService.getDetail(id: reportId);
        _cacheDetail(detail);
        // Section 5: Poll every 5s only until status is not 0 or 1; do NOT poll waiting for faster-whisper or summary.
        if (detail.report.shouldKeepPolling && _isTabActive) {
          _startPollingReport(reportId);
        } else {
          _stopPollingReport(reportId);
        }
      } catch (_) {
        // On transient network error while polling, schedule next check at 10s if still active
        if (_isTabActive) {
          _pollingTimers[reportId] = Timer(
            const Duration(seconds: 10),
            () => _startPollingReport(reportId),
          );
        }
      }
    });
    notifyListeners();
  }

  void _stopPollingReport(String reportId) {
    _pollingTimers.remove(reportId)?.cancel();
    _pollingStartedAt.remove(reportId);
    notifyListeners();
  }

  void _stopAllPollingTimers() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
  }

  void _resumePollingForPendingReports() {
    if (!_isTabActive) return;
    for (final r in _reports) {
      if (r.shouldKeepPolling && !_pollingTimers.containsKey(r.id)) {
        _startPollingReport(r.id);
      }
    }
  }

  Future<VoiceReportDetail?> refreshSingleReport(String reportId) async {
    _isLoadingDetail = true;
    notifyListeners();
    try {
      final detail = await _apiService.getDetail(id: reportId);
      _cacheDetail(detail);
      if (detail.report.shouldKeepPolling && _isTabActive) {
        _startPollingReport(detail.report.id);
      } else {
        _stopPollingReport(detail.report.id);
      }
      return detail;
    } catch (e) {
      debugPrint('[VoiceReportViewModel] refreshSingleReport error: $e');
      return _detailsById[reportId];
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// 9.1 SaveSummary (Channel ④: สรุปโดยคน)
  Future<VoiceActionFeedback> saveHumanSummary({
    required String reportId,
    required String text,
    String? note,
  }) async {
    if (text.trim().isEmpty) {
      return const VoiceActionFeedback(
        success: false,
        message: 'กรุณากรอกข้อความสรุป',
      );
    }

    _isSavingSummary = true;
    notifyListeners();
    try {
      final detail = await _apiService.saveSummary(
        id: reportId,
        text: text,
        note: note,
        user: currentUserId,
      );
      _cacheDetail(detail);
      _isSavingSummary = false;
      notifyListeners();
      return const VoiceActionFeedback(
        success: true,
        message: 'บันทึกข้อความสรุปเรียบร้อยแล้ว',
      );
    } catch (e) {
      _isSavingSummary = false;
      notifyListeners();
      final msg = e.toString().replaceFirst('Exception: ', '');
      return VoiceActionFeedback(
        success: false,
        message: 'บันทึกสรุปไม่สำเร็จ: $msg',
      );
    }
  }

  void _cacheDetail(VoiceReportDetail detail) {
    if (detail.report.id.isNotEmpty) {
      _detailsById[detail.report.id] = detail;
    }
    _upsertReport(detail.report);
  }

  void _upsertReport(VoiceReportItem item) {
    final idx = _reports.indexWhere(
      (r) =>
          (item.id.isNotEmpty && r.id == item.id) ||
          (item.clientRecordId.isNotEmpty &&
              r.clientRecordId == item.clientRecordId),
    );
    if (idx != -1) {
      _reports[idx] = item;
    } else {
      _reports.insert(0, item);
    }
    notifyListeners();
  }

  // ===========================================================================
  // 5. HISTORY LIST & FILTERS (`List`, Section 6)
  // ===========================================================================
  void setFromDate(DateTime? date) {
    _fromDate = date == null ? null : DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setToDate(DateTime? date) {
    _toDate = date == null ? null : DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<void> setTodayFilter() async {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate = DateTime(now.year, now.month, now.day);
    notifyListeners();
    await loadReports();
  }

  Future<void> setFilterStatus(int? status) async {
    _filterStatus = status;
    notifyListeners();
    await loadReports();
  }

  Future<void> setFilterJobId(int? jobId) async {
    _filterJobId = jobId;
    notifyListeners();
    await loadReports();
  }

  Future<void> setOnlyMyReports(bool value) async {
    _onlyMyReports = value;
    notifyListeners();
    await loadReports();
  }

  Future<void> loadReports() async {
    await ensureLookupsLoaded();
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      _reportsError = 'วันที่เริ่มต้องไม่เกินวันที่สิ้นสุด';
      notifyListeners();
      return;
    }

    _isLoadingReports = true;
    _reportsError = null;
    notifyListeners();

    try {
      final list = await _apiService.getList(
        fromDate: fromDateIso,
        toDate: toDateIso,
        status: _filterStatus,
        jobId: _filterJobId,
        userId: _onlyMyReports ? currentUserId : null,
        top: 100,
      );
      _reports = list;
      _stopAllPollingTimers();
      _resumePollingForPendingReports();
    } catch (e) {
      _reportsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _queueRetryTimer?.cancel();
    _stopAllPollingTimers();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
