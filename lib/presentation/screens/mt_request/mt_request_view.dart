// lib/presentation/screens/mt_request/mt_request_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/models/mt_request_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/mt_request/mt_request_detail_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/mt_request/mt_request_viewmodel.dart';

/// Embeddable MT Request management view (used inside the "ใบแจ้งซ่อม MT" sub-tab of CaseHubScreen).
class MtRequestView extends StatefulWidget {
  const MtRequestView({super.key});

  @override
  State<MtRequestView> createState() => _MtRequestViewState();
}

class _MtRequestViewState extends State<MtRequestView>
    with AutomaticKeepAliveClientMixin {
  static final DateFormat _dtFmt = DateFormat('dd/MM/yy HH:mm');

  // 0 = รายการใบแจ้งซ่อม (List), 1 = เลือกเคสเปิดใบใหม่ (CaseList)
  int _subMode = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<MtRequestViewModel>();
      vm.ensureLookupsLoaded();
      if (!vm.hasLoadedRequests) {
        vm.loadRequests();
      }
    });
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '–';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return _dtFmt.format(parsed);
  }

  Future<void> _openDetail(int requestId, {MtRequestDetail? initialDetail}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MtRequestDetailScreen(
          requestId: requestId,
          initialDetail: initialDetail,
        ),
      ),
    );
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

  void _showJobFilterSheet({
    required List<DbJob> jobs,
    required int? selectedJobId,
    required ValueChanged<int?> onSelected,
  }) {
    final searchController = TextEditingController();
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
            final q = searchController.text.trim().toLowerCase();
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
                          const Expanded(
                            child: Text(
                              'เลือกใบงาน (Job)',
                              style: TextStyle(
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
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่องาน, รหัส Job หรือเครื่องจักร...',
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
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ListTile(
                              title: const Text('ทุกงาน (ทั้งหมด)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
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
                          final job = filtered[index - 1];
                          final idInt = int.tryParse(job.jobId ?? '');
                          final isSel =
                              idInt != null && idInt == selectedJobId;
                          return ListTile(
                            title: Text(
                              '${job.jobId ?? ''} · ${job.jobName ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: job.machineName != null &&
                                    job.machineName!.isNotEmpty
                                ? Text(job.machineName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)
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
    ).whenComplete(searchController.dispose);
  }

  Future<void> _showCreateRequestDialog(MtRequestViewModel vm) async {
    final descController = TextEditingController();
    final selectedCount = vm.selectedProblemIds.length;
    final jobId = vm.selectedCasesJobId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('สร้างใบแจ้งซ่อมใหม่ (ร่าง)'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รวมเคสที่เลือกจำนวน $selectedCount เคส (Job ${jobId ?? '-'})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดปัญหา (ไม่บังคับ)',
                  hintText: 'เช่น สายพานสั่น เสียงดังผิดปกติ',
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
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('สร้างใบร่าง'),
          ),
        ],
      ),
    );

    final desc = descController.text;
    descController.dispose();
    if (confirmed != true || !mounted) return;

    final res = await vm.createRequest(description: desc);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message ?? ''),
        backgroundColor:
            res.success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (res.success && res.detail != null) {
      await _openDetail(res.detail!.header.id, initialDetail: res.detail);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MtRequestViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // Sub-mode switcher: รายการใบแจ้งซ่อม | เลือกเคสเปิดใบใหม่
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _modeButton(
                      selected: _subMode == 0,
                      icon: Icons.assignment_outlined,
                      label: 'รายการใบแจ้งซ่อม',
                      onTap: () {
                        setState(() => _subMode = 0);
                        if (!vm.hasLoadedRequests) vm.loadRequests();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeButton(
                      selected: _subMode == 1,
                      icon: Icons.add_box_outlined,
                      label: 'เลือกเคสเปิดใบใหม่',
                      onTap: () {
                        setState(() => _subMode = 1);
                        if (!vm.hasLoadedCases) vm.loadCases();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _subMode == 0
                  ? _buildRequestListTab(vm)
                  : _buildCasePickerTab(vm),
            ),
          ],
        );
      },
    );
  }

  Widget _modeButton({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.blue.shade900 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.grey.shade800,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SUB-MODE 0: REQUEST LIST ----------------
  Widget _buildRequestListTab(MtRequestViewModel vm) {
    final statuses = vm.lookups?.statuses ??
        const [
          MtRequestStatusLookup(id: 0, name: 'ร่าง'),
          MtRequestStatusLookup(id: 1, name: 'ส่ง MT แล้ว'),
          MtRequestStatusLookup(id: 2, name: 'ปิดงาน'),
          MtRequestStatusLookup(id: 3, name: 'ยกเลิก'),
        ];

    return Column(
      children: [
        // Filters container
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status chips + MT Ended quick filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('ทั้งหมด'),
                        selected:
                            !vm.filterMtEndedOnly && vm.filterStatus == null,
                        onSelected: (_) => vm.setFilterStatus(null),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.task_alt,
                          size: 16,
                          color: vm.filterMtEndedOnly
                              ? Colors.teal.shade900
                              : Colors.teal.shade700,
                        ),
                        label: const Text('MT จบแล้ว (รอปิด)'),
                        selected: vm.filterMtEndedOnly,
                        selectedColor: Colors.teal.shade100,
                        onSelected: (_) => vm.setFilterMtEndedOnly(true),
                      ),
                    ),
                    ...statuses.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(s.name),
                          selected:
                              !vm.filterMtEndedOnly && vm.filterStatus == s.id,
                          onSelected: (_) => vm.setFilterStatus(s.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Job + Date range + Refresh
              StreamBuilder<List<DbJob>>(
                stream: vm.jobsStream,
                builder: (context, snapshot) {
                  final jobs = snapshot.data ?? const <DbJob>[];
                  final jobLabel = _jobLabelFor(jobs, vm.filterJobId);

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _filterChipButton(
                        icon: Icons.work_outline,
                        label: jobLabel,
                        active: vm.filterJobId != null,
                        onTap: () => _showJobFilterSheet(
                          jobs: jobs,
                          selectedJobId: vm.filterJobId,
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
                        onClear: vm.toDate != null
                            ? () => vm.setToDate(null)
                            : null,
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
                        onPressed:
                            vm.isLoadingRequests ? null : vm.loadRequests,
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('โหลด',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: vm.loadRequests,
            child: vm.isLoadingRequests && vm.requests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vm.requestsError != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 42),
                                const SizedBox(height: 8),
                                Text(vm.requestsError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: vm.loadRequests,
                                  child: const Text('ลองใหม่'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : vm.requests.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(36),
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_outlined,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text(
                                      'ไม่พบใบแจ้งซ่อมตามเงื่อนไขที่เลือก',
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: vm.requests.length,
                            itemBuilder: (context, index) {
                              final r = vm.requests[index];
                              return _buildRequestCard(vm, r);
                            },
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(MtRequestViewModel vm, MtRequestListItem r) {
    final statusName =
        vm.lookups?.statusNameFor(r.status, fallback: r.statusName) ??
            r.statusName;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(r.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.requestNo != null && r.requestNo!.isNotEmpty
                          ? r.requestNo!
                          : 'ใบร่าง #${r.id}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _statusPill(r.status, statusName),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${r.machineName} · Job ${r.jobId}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              Text(
                r.formName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (r.description != null && r.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  r.description!,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (r.hasMtTracking || r.isWaitingFieldClose) ...[
                const SizedBox(height: 8),
                _buildCardMtTrackingBox(r),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 15, color: Colors.blue.shade800),
                  const SizedBox(width: 4),
                  Text(
                    '${r.caseCount} เคส (ปิดแล้ว ${r.closedCaseCount})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'สร้าง ${_fmtDateTime(r.createDate)}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMtTrackingBox(MtRequestListItem r) {
    final isEndedWaiting = r.isWaitingFieldClose;
    final isCancelled = r.isMtCancelled;

    final Color bg = isEndedWaiting
        ? (isCancelled ? Colors.red.shade50 : Colors.teal.shade50)
        : Colors.indigo.shade50;
    final Color border = isEndedWaiting
        ? (isCancelled ? Colors.red.shade200 : Colors.teal.shade300)
        : Colors.indigo.shade100;
    final Color accent = isEndedWaiting
        ? (isCancelled ? Colors.red.shade900 : Colors.teal.shade900)
        : Colors.indigo.shade900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined, size: 15, color: accent),
              if (r.mtStatusName != null && r.mtStatusName!.isNotEmpty)
                Text(
                  'MT: ${r.mtStatusName!}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              if (isEndedWaiting)
                _tinyBadge(
                  isCancelled ? 'MT ยกเลิก · รอจัดการ' : 'MT จบแล้ว · รอปิดงาน',
                  isCancelled ? Colors.red.shade100 : Colors.teal.shade100,
                  accent,
                ),
            ],
          ),
          if ((r.mtJobNo != null && r.mtJobNo!.isNotEmpty) ||
              (r.mtJobStatusName != null && r.mtJobStatusName!.isNotEmpty) ||
              (r.mtEngineerName != null && r.mtEngineerName!.isNotEmpty)) ...[
            const SizedBox(height: 3),
            Text(
              [
                if (r.mtJobNo != null && r.mtJobNo!.isNotEmpty)
                  'ใบงาน ${r.mtJobNo}',
                if (r.mtJobStatusName != null && r.mtJobStatusName!.isNotEmpty)
                  r.mtJobStatusName!,
                if (r.mtEngineerName != null && r.mtEngineerName!.isNotEmpty)
                  'ช่าง: ${r.mtEngineerName}',
              ].join(' · '),
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- SUB-MODE 1: CASE PICKER (CREATE NEW REQUEST) ----------------
  Widget _buildCasePickerTab(MtRequestViewModel vm) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: StreamBuilder<List<DbJob>>(
            stream: vm.jobsStream,
            builder: (context, snapshot) {
              final jobs = snapshot.data ?? const <DbJob>[];
              final jobLabel = _jobLabelFor(jobs, vm.caseFilterJobId);

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _filterChipButton(
                    icon: Icons.work_outline,
                    label: jobLabel,
                    active: vm.caseFilterJobId != null,
                    onTap: () => _showJobFilterSheet(
                      jobs: jobs,
                      selectedJobId: vm.caseFilterJobId,
                      onSelected: vm.setCaseFilterJobId,
                    ),
                  ),
                  FilterChip(
                    label: const Text('เฉพาะเคสเปิดอยู่'),
                    selected: vm.onlyOpenCases,
                    onSelected: (v) => vm.setOnlyOpenCases(v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'โหลดรายการเคสใหม่',
                    onPressed: vm.isLoadingCases ? null : vm.loadCases,
                  ),
                ],
              );
            },
          ),
        ),
        if (vm.selectedCasesJobId != null)
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'เลือกเคสจาก Job ${vm.selectedCasesJobId} อยู่ (1 ใบแจ้งซ่อมรวมได้เฉพาะเคสใน Job เดียวกัน)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: vm.loadCases,
            child: vm.isLoadingCases && vm.caseList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vm.casesError != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 42),
                                const SizedBox(height: 8),
                                Text(vm.casesError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: vm.loadCases,
                                  child: const Text('ลองใหม่'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : vm.caseList.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(36),
                                child: Center(
                                  child: Text(
                                    'ไม่พบรายการเคส',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: vm.caseList.length,
                            itemBuilder: (context, index) {
                              return _buildCaseItemCard(vm, vm.caseList[index]);
                            },
                          ),
          ),
        ),
        // Bottom Create Bar
        if (vm.selectedProblemIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'เลือกแล้ว ${vm.selectedProblemIds.length} เคส',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Job ${vm.selectedCasesJobId ?? '-'}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: vm.clearCaseSelection,
                  child: const Text('ล้าง'),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: vm.isSubmitting
                      ? null
                      : () => _showCreateRequestDialog(vm),
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  label: const Text('สร้างใบแจ้งซ่อม'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCaseItemCard(MtRequestViewModel vm, MtCaseListItem item) {
    final isSelected = vm.selectedProblemIds.contains(item.problemId);
    final canToggle = isSelected || vm.canToggleCase(item);
    final blockedByOtherJob = item.canSelectForNewRequest &&
        vm.selectedCasesJobId != null &&
        vm.selectedCasesJobId != item.jobId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 3 : 1,
      color: isSelected
          ? Colors.blue.shade50
          : (!canToggle ? Colors.grey.shade50 : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canToggle ? () => vm.toggleCaseSelection(item) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged:
                    canToggle ? (_) => vm.toggleCaseSelection(item) : null,
              ),
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
                          '#${item.problemId} · ${item.tagName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: canToggle
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (!item.isOpen)
                          _tinyBadge(
                            'ปิดแล้ว',
                            Colors.green.shade50,
                            Colors.green.shade800,
                          ),
                        if (item.requestCount > 0)
                          _tinyBadge(
                            'เคยออก ${item.requestCount} ใบ',
                            Colors.grey.shade200,
                            Colors.grey.shade800,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Job ${item.jobId} · ${item.machineName} (${item.phaseName})',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                    Text(
                      'ค่า: ${item.value.isEmpty ? '-' : item.value} · เอกสาร: ${item.documentName}',
                      style:
                          TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.description!,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'เปิดเมื่อ ${_fmtDateTime(item.createDate)} โดย ${item.createUser ?? '-'}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (item.isInActiveRequest) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openDetail(item.activeMTRequestId!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link,
                                  size: 14, color: Colors.amber.shade900),
                              const SizedBox(width: 4),
                              Text(
                                'อยู่ในใบ ${item.activeRequestNo ?? '#${item.activeMTRequestId}'} (แตะเพื่อดูใบ)',
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
                    ] else if (blockedByOtherJob) ...[
                      const SizedBox(height: 4),
                      Text(
                        'อยู่คนละ Job กับเคสที่เลือกไว้ (Job ${vm.selectedCasesJobId})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _jobLabelFor(List<DbJob> jobs, int? jobId) {
    if (jobId == null) return 'ทุกงาน';
    for (final j in jobs) {
      if (j.jobId == jobId.toString()) {
        return 'Job $jobId · ${j.machineName ?? j.jobName ?? ''}';
      }
    }
    return 'Job $jobId';
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

  Widget _statusPill(int status, String label) {
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
    return _tinyBadge(label, bg, fg);
  }

  Widget _tinyBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
