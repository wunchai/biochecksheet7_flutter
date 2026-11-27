// lib/presentation/screens/voice_report/voice_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/models/voice_report_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/voice_report/voice_report_viewmodel.dart';

class VoiceReportScreen extends StatefulWidget {
  final String title;

  const VoiceReportScreen({
    super.key,
    this.title = 'บันทึกเสียงรายงาน',
  });

  @override
  State<VoiceReportScreen> createState() => _VoiceReportScreenState();
}

class _VoiceReportScreenState extends State<VoiceReportScreen> {
  static final DateFormat _dtFmt = DateFormat('dd/MM/yy HH:mm:ss');
  VoiceReportViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm = context.read<VoiceReportViewModel>();
      _vm?.onTabVisibilityChanged(true);
    });
  }

  @override
  void dispose() {
    // Section 5: Stop polling & audio playback when user leaves the screen
    _vm?.onTabVisibilityChanged(false);
    super.dispose();
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '–';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return _dtFmt.format(parsed.toLocal());
  }

  String _fmtMmSs(double totalSec) {
    final sec = totalSec.round().clamp(0, 3600);
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showFeedback(VoiceActionFeedback? fb) {
    if (fb == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fb.message),
        backgroundColor:
            fb.success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: fb.success ? 3 : 5),
      ),
    );
  }

  String _jobLabelFor(List<DbJob> jobs, int? jobId,
      {String emptyText = 'เลือกใบงานประจำกะ'}) {
    if (jobId == null) return emptyText;
    for (final j in jobs) {
      if (j.jobId == jobId.toString()) {
        final machine = (j.machineName != null && j.machineName!.isNotEmpty)
            ? j.machineName!
            : (j.jobName ?? '');
        return 'Job $jobId · $machine';
      }
    }
    return 'Job $jobId';
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _showJobPickerSheet({
    required String title,
    required List<DbJob> jobs,
    required int? selectedJobId,
    required bool allowAllOption,
    required ValueChanged<int?> onSelected,
  }) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = searchCtrl.text.trim().toLowerCase();
            final filtered = jobs.where((j) {
              if (q.isEmpty) return true;
              return (j.jobId ?? '').toLowerCase().contains(q) ||
                  (j.jobName ?? '').toLowerCase().contains(q) ||
                  (j.machineName ?? '').toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.88,
              builder: (context, scrollController) {
                final extraItem = allowAllOption ? 1 : 0;
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
                      child: Row(
                        children: [
                          Icon(Icons.work_outline, color: Colors.blue.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'ค้นหารหัส Job, ชื่องาน หรือเครื่องจักร...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty && !allowAllOption
                          ? Center(
                              child: Text(
                                'ไม่พบรายการใบงาน (กรุณา Sync ข้อมูลที่หน้า Home ก่อน)',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length + extraItem,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (allowAllOption && index == 0) {
                                  return ListTile(
                                    title: const Text(
                                      'ทุกงาน (ทั้งหมด)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: selectedJobId == null
                                        ? Icon(Icons.check_circle,
                                            color: Colors.blue.shade900)
                                        : null,
                                    onTap: () {
                                      Navigator.pop(sheetCtx);
                                      onSelected(null);
                                    },
                                  );
                                }
                                final job = filtered[index - extraItem];
                                final idInt = int.tryParse(job.jobId ?? '');
                                final isSel =
                                    idInt != null && idInt == selectedJobId;
                                return ListTile(
                                  title: Text(
                                    'Job ${job.jobId ?? ''} · ${job.machineName ?? job.jobName ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: job.jobName != null &&
                                          job.jobName!.isNotEmpty
                                      ? Text(
                                          job.jobName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: isSel
                                      ? Icon(Icons.check_circle,
                                          color: Colors.blue.shade900)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(sheetCtx);
                                    onSelected(idInt);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).whenComplete(searchCtrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceReportViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.mic_rounded, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (vm.activePollingIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'รอถอดเสียง ${vm.activePollingIds.length}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'โหลดรายการใหม่',
                onPressed: vm.isLoadingReports
                    ? null
                    : () {
                        vm.loadReports();
                        vm.processOfflineQueue(forceAll: true);
                      },
              ),
            ],
          ),
          body: StreamBuilder<List<DbJob>>(
            stream: vm.jobsStream,
            builder: (context, jobSnap) {
              final jobs = jobSnap.data ?? const <DbJob>[];
              return RefreshIndicator(
                onRefresh: () async {
                  await vm.loadReports();
                  await vm.processOfflineQueue(forceAll: true);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                  children: [
                    _buildRecorderCard(vm, jobs),
                    if (vm.offlineQueue.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildOfflineQueueCard(vm, jobs),
                    ],
                    const SizedBox(height: 16),
                    _buildHistorySection(vm, jobs),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. RECORDER & SHIFT JOB CARD
  // ===========================================================================
  Widget _buildRecorderCard(VoiceReportViewModel vm, List<DbJob> jobs) {
    final shiftJobLabel = _jobLabelFor(
      jobs,
      vm.shiftJobId,
      emptyText: 'แตะเพื่อเลือกใบงาน / เครื่องจักรประจำกะ *',
    );
    final hasJob = vm.shiftJobId != null;
    final progress =
        (vm.recordingElapsedSec / VoiceReportViewModel.maxDurationSeconds)
            .clamp(0.0, 1.0);

    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shift Job Selector (Section 10.1: เริ่มกะ เลือก jobId จำไว้ทั้งกะ)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: vm.isRecording
                  ? null
                  : () => _showJobPickerSheet(
                        title: 'เลือกใบงานประจำกะ (จำค่าไว้ตลอดกะ)',
                        jobs: jobs,
                        selectedJobId: vm.shiftJobId,
                        allowAllOption: false,
                        onSelected: vm.setShiftJobId,
                      ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hasJob ? Colors.blue.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        hasJob ? Colors.blue.shade300 : Colors.amber.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.precision_manufacturing_outlined,
                      size: 20,
                      color:
                          hasJob ? Colors.blue.shade900 : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ใบงานประจำกะ (Job)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasJob
                                  ? Colors.blue.shade800
                                  : Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            shiftJobLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: hasJob
                                  ? Colors.blue.shade900
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color:
                          hasJob ? Colors.blue.shade900 : Colors.amber.shade900,
                    ),
                  ],
                ),
              ),
            ),

            if (vm.recordingNotice != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  vm.recordingNotice!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Recording Active OR Idle State
            if (vm.isRecording) ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'กำลังอัดเสียงรายงาน...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_fmtMmSs(vm.recordingElapsedSec)} / 02:00',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.red.shade100,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () async {
                        final fb = await vm.stopRecording();
                        _showFeedback(fb);
                      },
                      icon: const Icon(Icons.stop_circle_outlined, size: 24),
                      label: const Text(
                        'หยุดอัดเสียง',
                        style: TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (vm.hasDraft) ...[
              // Draft Review Box (Section 10.2: ฟังย้อน / อัดใหม่ได้ / กดส่ง)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.audiotrack,
                            color: Colors.green.shade800, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'เสียงที่อัดไว้ (${vm.draftDurationSec.toStringAsFixed(1)} วินาที)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade900,
                            side: BorderSide(color: Colors.green.shade600),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: vm.togglePlayDraft,
                          icon: Icon(
                            vm.playingSourceKey == 'draft' && vm.isPlayingAudio
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            vm.playingSourceKey == 'draft' && vm.isPlayingAudio
                                ? 'หยุดฟัง'
                                : 'ฟังทวน',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: vm.isProcessingQueue
                                ? null
                                : () async {
                                    await vm.discardDraft();
                                  },
                            icon: const Icon(Icons.replay, size: 18),
                            label: const Text('ลบ / อัดใหม่'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: vm.isProcessingQueue
                                ? null
                                : () async {
                                    final fb = await vm.submitDraft(
                                      jobLabel: shiftJobLabel,
                                    );
                                    _showFeedback(fb);
                                  },
                            icon: vm.isProcessingQueue
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined,
                                    size: 19),
                            label: const Text(
                              'ส่งรายงานเสียง',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Idle Record Button
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasJob
                            ? Colors.blue.shade900
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        final fb = await vm.startRecording();
                        if (!fb.success) _showFeedback(fb);
                      },
                      icon: const Icon(Icons.mic, size: 24),
                      label: const Text(
                        'กดเพื่อเริ่มอัดเสียงรายงาน',
                        style: TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'อัดเสียงรายงานเหตุการณ์ระหว่างผลิต (สูงสุด 2 นาที) ระบบจะถอดเสียงเป็นข้อความให้อัตโนมัติ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. OFFLINE QUEUE CARD (Section 4.3)
  // ===========================================================================
  Widget _buildOfflineQueueCard(VoiceReportViewModel vm, List<DbJob> jobs) {
    final currentJobLabel = _jobLabelFor(jobs, vm.shiftJobId,
        emptyText: 'Job ${vm.shiftJobId ?? ''}');
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_queue,
                    color: Colors.orange.shade900, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'คิวรอส่งในเครื่อง (${vm.offlineQueue.length} รายการ)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: vm.isProcessingQueue
                      ? null
                      : () => vm.processOfflineQueue(forceAll: true),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('ส่งคิวที่ค้าง',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...vm.offlineQueue.map((item) {
              final playKey = 'queue_${item.clientRecordId}';
              final isPlaying =
                  vm.playingSourceKey == playKey && vm.isPlayingAudio;

              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.isRejected400
                        ? Colors.red.shade300
                        : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.jobLabel ?? 'Job ${item.jobId}'} (${item.durationSec.toStringAsFixed(1)} วิ)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        _badge(
                          item.isRejected400
                              ? 'ข้อมูลไม่ผ่าน (400)'
                              : 'รอส่งซ้ำ (ครั้งที่ ${item.attempts})',
                          item.isRejected400
                              ? Colors.red.shade100
                              : Colors.orange.shade100,
                          item.isRejected400
                              ? Colors.red.shade900
                              : Colors.orange.shade900,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'อัดเมื่อ ${_fmtDateTime(item.recordedAtIso)}',
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    if (item.lastError != null &&
                        item.lastError!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.lastError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isRejected400
                              ? Colors.red.shade800
                              : Colors.orange.shade900,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => vm.togglePlayQueued(item),
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 16,
                          ),
                          label: Text(
                            isPlaying ? 'หยุด' : 'ฟังเสียง',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade900,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: vm.isProcessingQueue
                              ? null
                              : () async {
                                  final fb = await vm.retrySingleQueuedItem(
                                    item,
                                    currentShiftJobLabel: currentJobLabel,
                                  );
                                  _showFeedback(fb);
                                },
                          icon:
                              const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text(
                            (vm.shiftJobId != null &&
                                    vm.shiftJobId != item.jobId)
                                ? 'ส่งใหม่ด้วย Job ${vm.shiftJobId}'
                                : 'ลองส่งใหม่',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => vm.removeQueuedItem(item),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('ลบออก',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. HISTORY LIST & FILTERS (`List`, `Detail`, `Lookups`, `Audio`)
  // ===========================================================================
  Widget _buildHistorySection(VoiceReportViewModel vm, List<DbJob> jobs) {
    final statuses = vm.lookups?.statuses.isNotEmpty == true
        ? vm.lookups!.statuses
        : const [
            VoiceStatusLookup(id: 0, name: 'รอถอดเสียง'),
            VoiceStatusLookup(id: 1, name: 'กำลังถอดเสียง'),
            VoiceStatusLookup(id: 2, name: 'ถอดเสียงแล้ว'),
            VoiceStatusLookup(id: 8, name: 'ไม่ได้ถอดเสียง'),
            VoiceStatusLookup(id: 9, name: 'ล้มเหลว'),
          ];
    final filterJobLabel =
        _jobLabelFor(jobs, vm.filterJobId, emptyText: 'ทุกงาน');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 1.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ประวัติรายงานเสียง',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Status chips from Lookups
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('ทุกสถานะ'),
                          selected: vm.filterStatus == null,
                          onSelected: (_) => vm.setFilterStatus(null),
                        ),
                      ),
                      ...statuses.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(s.name),
                            selected: vm.filterStatus == s.id,
                            onSelected: (_) => vm.setFilterStatus(s.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('เฉพาะของฉัน'),
                      selected: vm.onlyMyReports,
                      onSelected: vm.setOnlyMyReports,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.today, size: 16),
                      label: const Text('วันนี้'),
                      onPressed: vm.setTodayFilter,
                    ),
                    _filterChipButton(
                      icon: Icons.work_outline,
                      label: filterJobLabel,
                      active: vm.filterJobId != null,
                      onTap: () => _showJobPickerSheet(
                        title: 'กรองตามใบงาน (Job)',
                        jobs: jobs,
                        selectedJobId: vm.filterJobId,
                        allowAllOption: true,
                        onSelected: vm.setFilterJobId,
                      ),
                    ),
                    _filterChipButton(
                      icon: Icons.date_range,
                      label: vm.fromDateIso != null
                          ? 'จาก ${vm.fromDateIso}'
                          : 'ตั้งแต่วันที่',
                      active: vm.fromDate != null,
                      onTap: () => _pickDate(
                        initial: vm.fromDate,
                        onPicked: vm.setFromDate,
                      ),
                      onClear: vm.fromDate != null
                          ? () => vm.setFromDate(null)
                          : null,
                    ),
                    _filterChipButton(
                      icon: Icons.event,
                      label: vm.toDateIso != null
                          ? 'ถึง ${vm.toDateIso}'
                          : 'ถึงวันที่',
                      active: vm.toDate != null,
                      onTap: () => _pickDate(
                        initial: vm.toDate,
                        onPicked: vm.setToDate,
                      ),
                      onClear:
                          vm.toDate != null ? () => vm.setToDate(null) : null,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: vm.isLoadingReports ? null : vm.loadReports,
                      icon: const Icon(Icons.search, size: 16),
                      label:
                          const Text('โหลด', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (vm.isLoadingReports && vm.reports.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (vm.reportsError != null && vm.reports.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 38),
                  const SizedBox(height: 8),
                  Text(
                    vm.reportsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: vm.loadReports,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          )
        else if (vm.reports.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.mic_off_outlined,
                      size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีรายการเสียงในช่วงที่เลือก',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...vm.reports.map((r) => _buildReportCard(vm, r)),
      ],
    );
  }

  Widget _buildReportCard(VoiceReportViewModel vm, VoiceReportItem r) {
    final statusLabel =
        vm.lookups?.statusNameFor(r.status, fallback: r.statusName) ??
            (r.statusName.isNotEmpty ? r.statusName : 'สถานะ ${r.status}');
    final playKey = 'report_${r.id}';
    final isPlaying = vm.playingSourceKey == playKey && vm.isPlayingAudio;
    final isPolling = vm.activePollingIds.contains(r.id);

    final titleMachine = (r.machineName != null && r.machineName!.isNotEmpty)
        ? r.machineName!
        : ((r.formName != null && r.formName!.isNotEmpty)
            ? r.formName!
            : 'Job ${r.jobId}');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job ${r.jobId} · $titleMachine',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      if (r.formName != null &&
                          r.formName!.isNotEmpty &&
                          r.formName != titleMachine)
                        Text(
                          r.formName!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadgeFor(r.status, statusLabel),
              ],
            ),
            const SizedBox(height: 10),

            // Transcription Result Box
            if (r.shouldKeepPolling)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPolling
                            ? 'ระบบกำลังถอดเสียงเป็นข้อความอัตโนมัติ (อัปเดตทุก 5–30 วินาที)...'
                            : 'รอถอดเสียง...',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'เช็คสถานะทันที',
                      onPressed: () => vm.refreshSingleReport(r.id),
                    ),
                  ],
                ),
              )
            else if (r.text != null && r.text!.trim().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subtitles_outlined,
                            size: 16, color: Colors.blue.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ข้อความที่ถอดได้'
                            '${r.textEngineType != null ? ' (${r.textEngineType})' : ''}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: r.text!));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('คัดลอกข้อความลงคลิปบอร์ดแล้ว'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy,
                                    size: 14, color: Colors.blue.shade800),
                                const SizedBox(width: 3),
                                Text(
                                  'คัดลอก',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      r.text!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            else if (r.isFailed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.errorMessage ?? 'การถอดเสียงล้มเหลว',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              )
            else if (r.isSkipped)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'ระบบปิดการถอดเสียงไว้ชั่วคราว (ไฟล์เสียงถูกเก็บไว้ในระบบเรียบร้อยแล้ว)',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
                ),
              ),

            // Summary Shortcuts in List Card (Channels ③ Cowork & ④ Human)
            if (r.hasHumanSummary || r.hasCoworkSummary) ...[
              const SizedBox(height: 8),
              if (r.hasHumanSummary)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '④ สรุปโดยคน${r.humanBy != null ? ' (${r.humanBy})' : ''}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        r.humanText!,
                        style: const TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              if (r.hasCoworkSummary)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '③ สรุปโดย Cowork',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        r.coworkText!,
                        style: const TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 10),

            // Footer: Audio playback + 4-Channel Detail + Write Summary + timestamps
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade900,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final fb = await vm.togglePlayRemoteReport(r);
                    _showFeedback(fb);
                  },
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    isPlaying
                        ? 'หยุด (${_fmtMmSs(vm.playbackPosition.inSeconds.toDouble())})'
                        : 'ฟังเสียง (${r.durationSec.toStringAsFixed(0)} วิ)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo.shade900,
                    side: BorderSide(color: Colors.indigo.shade300),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showFourChannelDetailSheet(vm, r),
                  icon: const Icon(Icons.view_agenda_outlined, size: 17),
                  label: const Text(
                    'เทียบผล 4 ช่อง',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showSaveSummaryDialog(vm, r),
                  icon: const Icon(Icons.edit_note, size: 17),
                  label: Text(
                    r.hasHumanSummary ? 'แก้สรุป' : 'เขียนสรุป',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ผู้บันทึก: ${r.userId} · ${_fmtDateTime(r.recordedAt ?? r.uploadedAt)}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. FOUR-CHANNEL DETAIL & COMPARISON SHEET (① OpenAI, ② faster-whisper, ③ Cowork, ④ Human + Table3 History)
  // ===========================================================================
  Future<void> _showFourChannelDetailSheet(
    VoiceReportViewModel vm,
    VoiceReportItem initialReport,
  ) async {
    // Section 5: Fetch fresh Detail every time this screen/sheet is opened (never loop-poll for faster-whisper/summary)
    vm.refreshSingleReport(initialReport.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer<VoiceReportViewModel>(
              builder: (context, liveVm, _) {
                final detail = liveVm.detailFor(initialReport.id) ??
                    VoiceReportDetail(report: initialReport);
                final r = detail.report;
                final ch1 = detail.openAiChannel;
                final ch2 = detail.fasterWhisperChannel;
                final ch3 = detail.coworkChannel;
                final ch4 = detail.humanChannel;

                final playKey = 'report_${r.id}';
                final isPlaying =
                    liveVm.playingSourceKey == playKey && liveVm.isPlayingAudio;

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Top Header Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                      child: Row(
                        children: [
                          Icon(Icons.compare_arrows_rounded,
                              color: Colors.blue.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'รายละเอียด & เทียบผล 4 ช่อง (Job ${r.jobId})',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ผู้บันทึก: ${r.userId} · ${_fmtDateTime(r.recordedAt ?? r.uploadedAt)} (${r.durationSec.toStringAsFixed(1)} วิ)',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: liveVm.isLoadingDetail
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            tooltip: 'รีเฟรชข้อมูลล่าสุด',
                            onPressed: liveVm.isLoadingDetail
                                ? null
                                : () => liveVm.refreshSingleReport(r.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    // Quick Action Bar inside Detail Sheet
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade900,
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final fb = await liveVm.togglePlayRemoteReport(r);
                              _showFeedback(fb);
                            },
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_outline,
                              size: 18,
                            ),
                            label: Text(
                              isPlaying
                                  ? 'หยุดฟัง'
                                  : 'ฟังเสียงต้นฉบับ (${r.durationSec.toStringAsFixed(0)} วิ)',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showSaveSummaryDialog(
                                liveVm,
                                r,
                                preloadedDetail: detail,
                              ),
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: Text(
                                ch4.hasSummary
                                    ? 'แก้ไขสรุปโดยคน (ช่อง ④)'
                                    : 'เขียนสรุปโดยคน (ช่อง ④)',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // 4 Mandatory Channels + Table3 History
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(14),
                        children: [
                          // Channel ① OpenAI
                          _buildEngineChannelCard(
                            channelTitle: '① OpenAI (Engine หลัก)',
                            engine: ch1,
                            accentColor: Colors.blue.shade900,
                            bgColor: Colors.blue.shade50,
                          ),
                          const SizedBox(height: 10),

                          // Channel ② faster-whisper
                          _buildEngineChannelCard(
                            channelTitle: '② faster-whisper (Engine ในองค์กร)',
                            engine: ch2,
                            accentColor: Colors.indigo.shade900,
                            bgColor: Colors.indigo.shade50,
                            waitingHint:
                                'อาจใช้เวลาถอดเสียง 1–5 นาที กดปุ่มรีเฟรชด้านบนเพื่อดูผลล่าสุด',
                          ),
                          const SizedBox(height: 10),

                          // Channel ③ สรุปโดย Cowork (always shown even when status == 0 "ยังไม่มีสรุป")
                          _buildSummaryChannelCard(
                            channelTitle:
                                '③ ${ch3.sourceName.isNotEmpty ? ch3.sourceName : 'สรุปโดย Cowork'}',
                            slot: ch3,
                            accentColor: Colors.purple.shade900,
                            bgColor: Colors.purple.shade50,
                            emptyPlaceholder:
                                'ยังไม่มีสรุป (ระบบ AI Cowork จะเปิดใช้งานในเฟสถัดไป)',
                          ),
                          const SizedBox(height: 10),

                          // Channel ④ สรุปโดยคน
                          _buildSummaryChannelCard(
                            channelTitle:
                                '④ ${ch4.sourceName.isNotEmpty ? ch4.sourceName : 'สรุปโดยคน'}',
                            slot: ch4,
                            accentColor: Colors.teal.shade900,
                            bgColor: Colors.teal.shade50,
                            emptyPlaceholder:
                                'ยังไม่มีสรุปโดยคน — กดปุ่ม "เขียนสรุปโดยคน" เพื่อสรุปหรือแก้คำผิดจากผลถอดเสียง',
                            onEditPressed: () => _showSaveSummaryDialog(
                              liveVm,
                              r,
                              preloadedDetail: detail,
                            ),
                          ),

                          // Table3: Summary Version History
                          if (detail.summaryHistory.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ประวัติการบันทึกสรุป (${detail.summaryHistory.length} ฉบับ)',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Divider(height: 14),
                                    ...detail.summaryHistory.map(
                                      (h) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'ฉบับ #${h.summaryId} (${h.source})',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    '${h.createdBy ?? '-'} · ${_fmtDateTime(h.createdAt)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                h.text,
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              if (h.note != null &&
                                                  h.note!.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  'หมายเหตุ: ${h.note}',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade700,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEngineChannelCard({
    required String channelTitle,
    required VoiceEngineResult engine,
    required Color accentColor,
    required Color bgColor,
    String? waitingHint,
  }) {
    final latencyText = engine.latencyMs != null
        ? '${(engine.latencyMs! / 1000.0).toStringAsFixed(1)} วิ'
        : null;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    channelTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                _statusBadgeFor(
                  engine.status,
                  engine.statusName.isNotEmpty
                      ? engine.statusName
                      : 'สถานะ ${engine.status}',
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              [
                'Model: ${engine.model}',
                if (latencyText != null) 'เวลาถอด: $latencyText',
                if (!engine.engineEnabled) 'ปิดอยู่',
              ].join(' · '),
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: engine.hasText ? bgColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: engine.hasText
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          engine.text!,
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: engine.text!));
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('คัดลอกข้อความลงคลิปบอร์ดแล้ว'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 14, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  'คัดลอก',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      engine.error != null && engine.error!.isNotEmpty
                          ? 'ข้อผิดพลาด: ${engine.error}'
                          : (waitingHint ??
                              'ยังไม่มีข้อความ (${engine.statusName.isNotEmpty ? engine.statusName : 'รอผล'})'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: engine.status == 9
                            ? Colors.red.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChannelCard({
    required String channelTitle,
    required VoiceSummarySlot slot,
    required Color accentColor,
    required Color bgColor,
    required String emptyPlaceholder,
    VoidCallback? onEditPressed,
  }) {
    final badgeBg =
        slot.hasSummary ? Colors.green.shade100 : Colors.grey.shade200;
    final badgeFg =
        slot.hasSummary ? Colors.green.shade900 : Colors.grey.shade800;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    channelTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                if (onEditPressed != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onEditPressed,
                    icon: const Icon(Icons.edit, size: 15),
                    label: Text(
                      slot.hasSummary ? 'แก้ไข' : 'เขียนสรุป',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 6),
                _badge(
                  slot.statusName.isNotEmpty
                      ? slot.statusName
                      : (slot.hasSummary ? 'มีสรุปแล้ว' : 'ยังไม่มีสรุป'),
                  badgeBg,
                  badgeFg,
                ),
              ],
            ),
            if (slot.hasSummary &&
                (slot.createdBy != null ||
                    slot.createdAt != null ||
                    slot.versions > 0)) ...[
              const SizedBox(height: 3),
              Text(
                [
                  if (slot.createdBy != null && slot.createdBy!.isNotEmpty)
                    'โดย ${slot.createdBy}',
                  if (slot.createdAt != null && slot.createdAt!.isNotEmpty)
                    _fmtDateTime(slot.createdAt),
                  if (slot.versions > 0) 'แก้ไขแล้ว ${slot.versions} ครั้ง',
                ].join(' · '),
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: slot.hasSummary ? bgColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: slot.hasSummary
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          slot.text!,
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                        if (slot.note != null && slot.note!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'หมายเหตุ: ${slot.note}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      emptyPlaceholder,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. SAVE SUMMARY DIALOG (Section 9.1: Start from OpenAI or faster-whisper text)
  // ===========================================================================
  Future<void> _showSaveSummaryDialog(
    VoiceReportViewModel vm,
    VoiceReportItem report, {
    VoiceReportDetail? preloadedDetail,
  }) async {
    final detail = preloadedDetail ??
        vm.detailFor(report.id) ??
        await vm.refreshSingleReport(report.id) ??
        VoiceReportDetail(report: report);
    if (!mounted) return;

    final openAiText = detail.openAiChannel.text ?? report.text ?? '';
    final whisperText = detail.fasterWhisperChannel.text ?? '';
    final existingHumanText =
        detail.humanChannel.text ?? report.humanText ?? '';
    final existingHumanNote = detail.humanChannel.note ?? '';

    final initialText = existingHumanText.isNotEmpty
        ? existingHumanText
        : (openAiText.isNotEmpty ? openAiText : whisperText);

    final textCtrl = TextEditingController(text: initialText);
    final noteCtrl = TextEditingController(text: existingHumanNote);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เขียนสรุปโดยคน (ช่อง ④)'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'เลือกดึงข้อความตั้งต้นจาก Engine ด้านล่างแล้วแก้ไขคำผิดหรือสรุปใจความได้เลย (บันทึกทุกครั้งเป็นฉบับใหม่)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: Icon(Icons.auto_awesome,
                                size: 16, color: Colors.blue.shade900),
                            label: const Text('ใช้ข้อความ ① OpenAI'),
                            onPressed: openAiText.isEmpty
                                ? null
                                : () {
                                    textCtrl.text = openAiText;
                                  },
                          ),
                          ActionChip(
                            avatar: Icon(Icons.graphic_eq,
                                size: 16, color: Colors.indigo.shade900),
                            label: Text(
                              whisperText.isEmpty
                                  ? '② faster-whisper (ยังไม่มีผล)'
                                  : 'ใช้ข้อความ ② faster-whisper',
                            ),
                            onPressed: whisperText.isEmpty
                                ? null
                                : () {
                                    textCtrl.text = whisperText;
                                  },
                          ),
                          if (existingHumanText.isNotEmpty)
                            ActionChip(
                              avatar: Icon(Icons.history,
                                  size: 16, color: Colors.teal.shade900),
                              label: const Text('ใช้สรุปคนฉบับล่าสุด'),
                              onPressed: () {
                                textCtrl.text = existingHumanText;
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: textCtrl,
                        maxLength: 4000,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'ข้อความสรุป *',
                          hintText:
                              'เช่น เครื่องบรรจุไลน์ 2 หยุดเพราะสายพานหลุด แก้แล้ว',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteCtrl,
                        maxLength: 1000,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'หมายเหตุการแก้ไข (ไม่บังคับ)',
                          hintText: 'เช่น แก้ชื่อเครื่องที่ถอดผิด',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('บันทึกสรุป'),
                ),
              ],
            );
          },
        );
      },
    );

    final summaryText = textCtrl.text;
    final summaryNote = noteCtrl.text;
    textCtrl.dispose();
    noteCtrl.dispose();

    if (confirmed != true || !mounted) return;
    final fb = await vm.saveHumanSummary(
      reportId: report.id,
      text: summaryText,
      note: summaryNote,
    );
    _showFeedback(fb);
  }

  Widget _filterChipButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? Colors.blue.shade700 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? Colors.blue.shade900 : Colors.grey.shade700),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 165),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? Colors.blue.shade900 : Colors.grey.shade800,
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                child: Icon(Icons.close, size: 15, color: Colors.blue.shade900),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadgeFor(int status, String label) {
    final Color bg;
    final Color fg;
    switch (status) {
      case 0:
      case 1:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case 2:
      case 3:
      case 4:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case 8:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        break;
      case 9:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      default:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
    }
    return _badge(label, bg, fg);
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
