// lib/presentation/screens/mt_request/mt_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/models/mt_request_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/mt_request/mt_request_viewmodel.dart';

class MtRequestDetailScreen extends StatefulWidget {
  final int requestId;
  final MtRequestDetail? initialDetail;

  const MtRequestDetailScreen({
    super.key,
    required this.requestId,
    this.initialDetail,
  });

  @override
  State<MtRequestDetailScreen> createState() => _MtRequestDetailScreenState();
}

class _MtRequestDetailScreenState extends State<MtRequestDetailScreen> {
  static final DateFormat _dtFmt = DateFormat('dd/MM/yy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<MtRequestViewModel>();
      if (widget.initialDetail != null &&
          widget.initialDetail!.header.id == widget.requestId) {
        vm.setCurrentDetail(widget.initialDetail!);
        vm.ensureLookupsLoaded();
      } else {
        vm.loadDetail(widget.requestId);
      }
    });
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '–';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return _dtFmt.format(parsed);
  }

  void _showResultFeedback(MtRequestActionResult res) {
    if (!mounted) return;
    final msg = res.message ?? (res.success ? 'ดำเนินการสำเร็จ' : 'เกิดข้อผิดพลาด');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: res.success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openOnlineDocument(MtRequestHeader header, MtRequestCaseItem item) {
    final userId =
        context.read<LoginViewModel>().loggedInUser?.userId ?? '600201';
    Navigator.pushNamed(
      context,
      '/document_machine_online',
      arguments: {
        'title': header.machineName.isNotEmpty
            ? header.machineName
            : item.documentId,
        'documentId': item.documentId,
        'jobId': header.jobId.toString(),
        'userId': userId,
      },
    );
  }

  // --- Dialog: Update Description ---
  Future<void> _showUpdateDescriptionDialog(
      MtRequestViewModel vm, MtRequestHeader header) async {
    final controller = TextEditingController(text: header.description ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('แก้ไขรายละเอียดปัญหา'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'รายละเอียดปัญหา',
              hintText: 'ระบุรายละเอียดสำหรับ MT (เว้นว่างเพื่อล้างค่า)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    final desc = controller.text;
    controller.dispose();
    if (confirmed != true || !mounted) return;

    final res = await vm.updateCurrentDescription(desc);
    _showResultFeedback(res);
  }

  // --- Dialog: SetRequestNo ---
  Future<void> _showSetRequestNoDialog(
      MtRequestViewModel vm, MtRequestHeader header) async {
    final controller = TextEditingController(text: header.requestNo ?? '');
    final isDraft = header.isDraft;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isDraft ? 'บันทึกเลขใบแจ้งซ่อม MT' : 'แก้ไขเลขใบแจ้งซ่อม MT'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDraft
                    ? 'เมื่อบันทึกเลขใบ MT แล้ว สถานะจะเปลี่ยนเป็น "ส่ง MT แล้ว" และจะไม่สามารถเพิ่มหรือลบเคสได้'
                    : 'แก้ไขเลขใบแจ้งซ่อมในระบบ MT (ห้ามซ้ำกับใบอื่น)',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'เลขใบแจ้งซ่อม (RequestNo)',
                  hintText: 'เช่น REQ2611-0001',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogCtx, true);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    final reqNo = controller.text.trim();
    controller.dispose();
    if (confirmed != true || reqNo.isEmpty || !mounted) return;

    final res = await vm.setCurrentRequestNo(reqNo);
    _showResultFeedback(res);
  }

  // --- Dialog: AddCases (Draft only) ---
  Future<void> _showAddCasesDialog(
      MtRequestViewModel vm, MtRequestHeader header) async {
    List<MtCaseListItem> available = [];
    String? loadError;
    bool loading = true;
    final selectedIds = <int>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (loading && loadError == null) {
              vm.fetchAvailableCasesForJob(header.jobId).then((items) {
                if (!dialogCtx.mounted) return;
                setDialogState(() {
                  available = items;
                  loading = false;
                });
              }).catchError((e) {
                if (!dialogCtx.mounted) return;
                setDialogState(() {
                  loadError = e.toString().replaceFirst('Exception: ', '');
                  loading = false;
                });
              });
            }

            return AlertDialog(
              title: Text('เพิ่มเคสเข้าใบร่าง (Job ${header.jobId})'),
              content: SizedBox(
                width: 480,
                height: 380,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : loadError != null
                        ? Center(
                            child: Text(
                              'โหลดเคสไม่สำเร็จ: $loadError',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : available.isEmpty
                            ? const Center(
                                child: Text(
                                  'ไม่มีเคสเปิดที่ว่างให้เพิ่มในใบงานนี้',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: available.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = available[index];
                                  final checked =
                                      selectedIds.contains(item.problemId);
                                  return CheckboxListTile(
                                    value: checked,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      '#${item.problemId} · ${item.tagName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.phaseName} · ค่า: ${item.value}\n'
                                      '${item.description ?? '-'}\n'
                                      'เปิดเมื่อ ${_fmtDateTime(item.createDate)} โดย ${item.createUser ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    isThreeLine: true,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          selectedIds.add(item.problemId);
                                        } else {
                                          selectedIds.remove(item.problemId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () => Navigator.pop(dialogCtx, true),
                  child: Text('เพิ่ม (${selectedIds.length} เคส)'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedIds.isEmpty || !mounted) return;
    final res = await vm.addCasesToCurrent(selectedIds.toList());
    _showResultFeedback(res);
  }

  // --- Dialog: RemoveCase (Draft only, > 1 case) ---
  Future<void> _confirmRemoveCase(
      MtRequestViewModel vm, MtRequestCaseItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันการลบเคสออกจากใบ'),
        content: Text(
          'ต้องการลบเคส #${item.problemId} (${item.tagName}) ออกจากใบร่างนี้ใช่หรือไม่?\n'
          '(ตัวเคสจะยังคงเปิดอยู่และสามารถนำไปสร้างใบแจ้งซ่อมใหม่ได้)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('ลบเคส', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final res = await vm.removeCaseFromCurrent(item.problemId);
    _showResultFeedback(res);
  }

  // --- Dialog: Close Request (Per-case results from Lookups + closeCase checkbox) ---
  Future<void> _showCloseRequestDialog(
      MtRequestViewModel vm, MtRequestDetail detail) async {
    await vm.ensureLookupsLoaded();
    if (!mounted) return;

    final resultLookups = vm.lookups?.results ?? const <MtRequestResultLookup>[];
    if (resultLookups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถโหลดรายการผลปิดงาน (Lookups) ได้ กรุณาลองใหม่'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final defaultLookup = resultLookups.first;
    final selectedResults = <int, int>{};
    final closeCaseFlags = <int, bool>{};
    final noteControllers = <int, TextEditingController>{};
    final closeNoteController = TextEditingController();

    for (final c in detail.cases) {
      selectedResults[c.problemId] = defaultLookup.id;
      closeCaseFlags[c.problemId] = defaultLookup.defaultCloseCase;
      noteControllers[c.problemId] = TextEditingController();
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'ปิดงานใบแจ้งซ่อม ${detail.header.requestNo ?? '#${detail.header.id}'}',
              ),
              content: SizedBox(
                width: 520,
                height: 460,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ระบุผลให้ครบทั้ง ${detail.cases.length} เคส และเลือกว่าจะปิดแต่ละเคสด้วยหรือไม่',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: detail.cases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = detail.cases[index];
                          final curResultId = selectedResults[c.problemId]!;
                          final curCloseCase = closeCaseFlags[c.problemId]!;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${c.problemId} · ${c.tagName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                if (c.description != null &&
                                    c.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      c.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  initialValue: curResultId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'ผลดำเนินการ',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: resultLookups
                                      .map(
                                        (lk) => DropdownMenuItem<int>(
                                          value: lk.id,
                                          child: Text(
                                            lk.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    final matched = resultLookups.firstWhere(
                                      (lk) => lk.id == val,
                                      orElse: () => defaultLookup,
                                    );
                                    setDialogState(() {
                                      selectedResults[c.problemId] = val;
                                      // Auto-set closeCase from Lookups defaultCloseCase; user can still override.
                                      closeCaseFlags[c.problemId] =
                                          matched.defaultCloseCase;
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  value: curCloseCase,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    curCloseCase
                                        ? 'ปิดเคสนี้ด้วย'
                                        : 'ไม่ปิดเคส (ยังเปิดอยู่ นำไปออกใบใหม่ได้)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: curCloseCase
                                          ? Colors.green.shade800
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      closeCaseFlags[c.problemId] = v ?? false;
                                    });
                                  },
                                ),
                                TextField(
                                  controller: noteControllers[c.problemId],
                                  maxLength: 500,
                                  decoration: const InputDecoration(
                                    labelText: 'หมายเหตุของเคส (ไม่บังคับ)',
                                    isDense: true,
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: closeNoteController,
                      maxLength: 1000,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'หมายเหตุการปิดใบ (ไม่บังคับ)',
                        hintText: 'เช่น MT ปิดงานเรียบร้อย',
                        isDense: true,
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('ยืนยันปิดงาน'),
                ),
              ],
            );
          },
        );
      },
    );

    final inputs = detail.cases
        .map(
          (c) => MtCloseCaseInput(
            problemId: c.problemId,
            result: selectedResults[c.problemId]!,
            note: noteControllers[c.problemId]!.text,
            closeCase: closeCaseFlags[c.problemId]!,
          ),
        )
        .toList();
    final closeNote = closeNoteController.text;

    for (final ctrl in noteControllers.values) {
      ctrl.dispose();
    }
    closeNoteController.dispose();

    if (confirmed != true || !mounted) return;

    final res = await vm.closeCurrentRequest(
      results: inputs,
      closeNote: closeNote,
    );
    _showResultFeedback(res);
  }

  // --- Dialog: Cancel Request ---
  Future<void> _showCancelRequestDialog(
      MtRequestViewModel vm, MtRequestHeader header) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันการยกเลิกใบแจ้งซ่อม'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เมื่อยกเลิกใบ ${header.requestNo ?? '#${header.id}'} แล้ว เคสทั้งหมดในใบจะยังคงเปิดอยู่และนำไปออกใบใหม่ได้',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'เหตุผลการยกเลิก (ไม่บังคับ)',
                  hintText: 'เช่น MT ยกเลิกใบ / สร้างผิดใบงาน',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('ไม่ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('ยืนยันยกเลิกใบ'),
          ),
        ],
      ),
    );

    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true || !mounted) return;

    final res = await vm.cancelCurrentRequest(note: note);
    _showResultFeedback(res);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MtRequestViewModel>(
      builder: (context, vm, _) {
        final detail = vm.currentDetail;
        final header = detail?.header;
        final titleText = header == null
            ? 'ใบแจ้งซ่อม #${widget.requestId}'
            : (header.requestNo != null && header.requestNo!.isNotEmpty
                ? header.requestNo!
                : 'ใบร่าง #${header.id}');

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              titleText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'โหลดข้อมูลใหม่',
                onPressed: vm.isLoadingDetail || vm.isSubmitting
                    ? null
                    : () => vm.loadDetail(widget.requestId),
              ),
            ],
          ),
          body: Stack(
            children: [
              if (vm.isLoadingDetail && detail == null)
                const Center(child: CircularProgressIndicator())
              else if (vm.detailError != null && detail == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          vm.detailError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => vm.loadDetail(widget.requestId),
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (detail == null)
                const Center(child: Text('ไม่พบข้อมูลใบแจ้งซ่อม'))
              else
                RefreshIndicator(
                  onRefresh: () => vm.loadDetail(detail.header.id),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderCard(vm, detail),
                        const SizedBox(height: 12),
                        _buildActionCard(vm, detail),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'เคสในใบแจ้งซ่อม (${detail.cases.length} เคส)',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (detail.header.isDraft)
                              TextButton.icon(
                                onPressed: vm.isSubmitting
                                    ? null
                                    : () => _showAddCasesDialog(
                                        vm, detail.header),
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                label: const Text('เพิ่มเคส'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...detail.cases.map(
                          (c) => _buildCaseCard(vm, detail, c),
                        ),
                      ],
                    ),
                  ),
                ),
              if (vm.isSubmitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('กำลังบันทึกข้อมูล...'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(MtRequestViewModel vm, MtRequestDetail detail) {
    final h = detail.header;
    final statusName = vm.lookups?.statusNameFor(h.status, fallback: h.statusName) ??
        (h.statusName.isNotEmpty ? h.statusName : 'สถานะ ${h.status}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    h.requestNo != null && h.requestNo!.isNotEmpty
                        ? '${h.requestNo} (ID #${h.id})'
                        : 'ใบร่าง #${h.id} (ยังไม่มีเลข MT)',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _mtStatusBadge(h.status, statusName),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${h.machineName}${h.location != null && h.location!.isNotEmpty ? ' (${h.location})' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${h.formName} · Job ${h.jobId}',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายละเอียดปัญหา',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (h.description != null && h.description!.isNotEmpty)
                            ? h.description!
                            : '– (ยังไม่ได้ระบุ)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (h.isEditable)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'แก้ไขรายละเอียดปัญหา',
                    color: Colors.blue.shade800,
                    onPressed: vm.isSubmitting
                        ? null
                        : () => _showUpdateDescriptionDialog(vm, h),
                  ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _metaChip('สร้างใบ', '${h.createUser ?? '-'} · ${_fmtDateTime(h.createDate)}'),
                if (h.sentDate != null)
                  _metaChip('ส่ง MT', '${h.sentUser ?? '-'} · ${_fmtDateTime(h.sentDate)}'),
                if (h.closeDate != null)
                  _metaChip(
                    h.isCancelled ? 'ยกเลิก' : 'ปิดงาน',
                    '${h.closeUser ?? '-'} · ${_fmtDateTime(h.closeDate)}',
                  ),
              ],
            ),
            if (h.closeNote != null && h.closeNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: h.isCancelled
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${h.isCancelled ? 'เหตุผลยกเลิก' : 'หมายเหตุปิดงาน'}: ${h.closeNote}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: h.isCancelled
                        ? Colors.red.shade900
                        : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(MtRequestViewModel vm, MtRequestDetail detail) {
    final h = detail.header;
    if (!h.isEditable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                h.isClosed
                    ? 'ใบแจ้งซ่อมนี้ปิดงานแล้ว (อ่านอย่างเดียว)'
                    : 'ใบแจ้งซ่อมนี้ถูกยกเลิกแล้ว (อ่านอย่างเดียว)',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: vm.isSubmitting
                  ? null
                  : () => _showSetRequestNoDialog(vm, h),
              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
              label: Text(h.isDraft ? 'บันทึกเลขใบ MT' : 'แก้เลขใบ MT'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: vm.isSubmitting || detail.cases.isEmpty
                  ? null
                  : () => _showCloseRequestDialog(vm, detail),
              icon: const Icon(Icons.task_alt, size: 18),
              label: const Text('ปิดงาน'),
            ),
            if (h.isDraft)
              OutlinedButton.icon(
                onPressed: vm.isSubmitting
                    ? null
                    : () => _showAddCasesDialog(vm, h),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มเคส'),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: vm.isSubmitting
                  ? null
                  : () => _showCancelRequestDialog(vm, h),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('ยกเลิกใบ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(
    MtRequestViewModel vm,
    MtRequestDetail detail,
    MtRequestCaseItem c,
  ) {
    final canRemove = detail.header.isDraft && detail.cases.length > 1;
    final isLastCaseInDraft = detail.header.isDraft && detail.cases.length <= 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '#${c.problemId} · ${c.tagName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          _smallPill(
                            c.caseStatus == 1 ? 'เคสปิดแล้ว' : 'เคสเปิดอยู่',
                            c.caseStatus == 1
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            c.caseStatus == 1
                                ? Colors.green.shade800
                                : Colors.orange.shade900,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.phaseName} · ค่า: ${c.value.isEmpty ? '-' : c.value}',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade800),
                      ),
                      Text(
                        'เอกสาร: ${c.documentName} (${c.documentId})',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 19),
                  tooltip: 'เปิดเอกสารออนไลน์',
                  color: Colors.blue.shade700,
                  onPressed: () => _openOnlineDocument(detail.header, c),
                ),
                if (detail.header.isDraft)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    tooltip: isLastCaseInDraft
                        ? 'ลบเคสสุดท้ายไม่ได้ (ให้ยกเลิกใบแทน)'
                        : 'ลบเคสออกจากใบ',
                    color: canRemove ? Colors.red.shade600 : Colors.grey.shade400,
                    onPressed: canRemove && !vm.isSubmitting
                        ? () => _confirmRemoveCase(vm, c)
                        : null,
                  ),
              ],
            ),
            if (c.description != null && c.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'หมายเหตุเปิดเคส: ${c.description}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'เปิดเคส: ${c.caseCreateUser ?? '-'} · ${_fmtDateTime(c.caseCreateDate)} | เพิ่มเข้าใบ: ${c.addUser ?? '-'} · ${_fmtDateTime(c.addDate)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (c.otherRequests != null && c.otherRequests!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ประวัติใบอื่น: ${c.otherRequests}',
                  style: TextStyle(
                      fontSize: 11.5, color: Colors.blueGrey.shade800),
                ),
              ),
            ],
            if (c.result != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.caseClosed == true
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: c.caseClosed == true
                        ? Colors.green.shade200
                        : Colors.amber.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'ผลปิดงาน: ${c.resultName ?? 'ผล #${c.result}'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        if (c.caseClosed != null)
                          _smallPill(
                            c.caseClosed! ? 'ปิดเคสแล้ว' : 'ยังไม่ปิดเคส',
                            Colors.white,
                            c.caseClosed!
                                ? Colors.green.shade800
                                : Colors.orange.shade900,
                          ),
                      ],
                    ),
                    if (c.resultNote != null && c.resultNote!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'หมายเหตุ: ${c.resultNote}',
                          style: const TextStyle(fontSize: 12),
                        ),
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

  Widget _metaChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _mtStatusBadge(int status, String label) {
    final Color bg;
    final Color fg;
    switch (status) {
      case 0:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case 1:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case 2:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case 3:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return _smallPill(label, bg, fg);
  }

  Widget _smallPill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
