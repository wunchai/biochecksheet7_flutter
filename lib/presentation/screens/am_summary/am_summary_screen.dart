// lib/presentation/screens/am_summary/am_summary_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/models/am_summary_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/am_summary/am_summary_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart';

class AmSummaryScreen extends StatefulWidget {
  final String title;

  const AmSummaryScreen({
    super.key,
    this.title = 'สรุปผลการตรวจ AM',
  });

  @override
  State<AmSummaryScreen> createState() => _AmSummaryScreenState();
}

class _AmSummaryScreenState extends State<AmSummaryScreen>
    with AutomaticKeepAliveClientMixin {
  // Editorial palette matched to CHECKSHEET_SUMMARY_GET demo
  static const Color _bg = Color(0xFFF1EFE9);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surface2 = Color(0xFFF7F5F0);
  static const Color _border = Color(0xFFDDD9CE);
  static const Color _fg = Color(0xFF20241F);
  static const Color _fgMuted = Color(0xFF636A5E);
  static const Color _fgFaint = Color(0xFF8D9284);
  static const Color _accent = Color(0xFF2F6E63);
  static const Color _accentSoft = Color(0xFFE3EFEC);
  static const Color _good = Color(0xFF2E7D4F);
  static const Color _goodSoft = Color(0xFFE3F1E8);
  static const Color _warn = Color(0xFFA96A0A);
  static const Color _warnSoft = Color(0xFFFAF0DD);
  static const Color _critical = Color(0xFFAB3D28);
  static const Color _criticalSoft = Color(0xFFF8E7E2);

  static final NumberFormat _intFmt = NumberFormat('#,##0');
  static final DateFormat _dtFmt = DateFormat('dd/MM/yy HH:mm');

  final GlobalKey _detailSectionKey = GlobalKey();
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _jobTableScrollController = ScrollController();
  final ScrollController _monthTableScrollController = ScrollController();
  final ScrollController _detailTableScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mainScrollController.dispose();
    _jobTableScrollController.dispose();
    _monthTableScrollController.dispose();
    _detailTableScrollController.dispose();
    super.dispose();
  }

  void _scrollToDetail() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _detailSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
    });
  }

  String _fmtInt(int value) => _intFmt.format(value);

  String _fmtPct(double value) => '${value.toStringAsFixed(2)}%';

  String _fmtMonth(DateTime? dt) {
    if (dt == null) return 'ทั้งหมด';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '–';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return _dtFmt.format(parsed);
  }

  void _openOnlineDocument({
    required String documentId,
    required int jobId,
    required String machineName,
    String? lot,
  }) {
    final userId =
        context.read<LoginViewModel>().loggedInUser?.userId ?? '600201';
    Navigator.pushNamed(
      context,
      '/document_machine_online',
      arguments: {
        'title': machineName.isNotEmpty ? machineName : documentId,
        'documentId': documentId,
        'jobId': jobId.toString(),
        'userId': userId,
        'lot': (lot != null && lot.isNotEmpty) ? lot : null,
      },
    );
  }

  Future<void> _pickMonth({
    required String title,
    required DateTime? initial,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final now = DateTime.now();
    int year = initial?.year ?? now.year;
    final int? initialMonth = initial?.month;
    final int? initialYear = initial?.year;

    const thaiMonths = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    final result = await showDialog<_MonthPickResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _fg,
                ),
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setDialogState(() => year--),
                        ),
                        Text(
                          '$year',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _fg,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setDialogState(() => year++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.1,
                      ),
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected =
                            initialYear == year && initialMonth == monthNum;
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.pop(
                            dialogContext,
                            _MonthPickResult(DateTime(year, monthNum)),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? _accent : _surface2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? _accent : _border,
                              ),
                            ),
                            child: Text(
                              '${thaiMonths[index]} (${monthNum.toString().padLeft(2, '0')})',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _fg,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, const _MonthPickResult(null)),
                  child: const Text(
                    'ล้างค่า',
                    style: TextStyle(color: _critical),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก', style: TextStyle(color: _fgMuted)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onSelected(result.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const Text(
              'SCADA · CheckSheet AM Dashboard',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AmSummaryViewModel>(
            builder: (context, vm, _) => IconButton(
              icon: vm.isLoadingMonthly
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'คำนวณใหม่',
              onPressed: vm.isLoadingMonthly
                  ? null
                  : () => vm.load(refresh: true),
            ),
          ),
        ],
      ),
      body: Consumer<AmSummaryViewModel>(
        builder: (context, vm, _) {
          return RefreshIndicator(
            color: _accent,
            onRefresh: () => vm.load(refresh: true),
            child: SingleChildScrollView(
              controller: _mainScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIntroBanner(),
                      const SizedBox(height: 14),
                      _buildFilterCard(vm),
                      const SizedBox(height: 14),
                      _buildKpiSection(vm),
                      const SizedBox(height: 16),
                      _buildJobSummaryCard(vm),
                      const SizedBox(height: 16),
                      _buildMonthlySummaryCard(vm),
                      const SizedBox(height: 16),
                      _buildDetailSection(vm),
                      const SizedBox(height: 16),
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SCADA · CHECKSHEET AM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _accent,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: _fgMuted, height: 1.5),
            children: [
              TextSpan(
                  text:
                      'ภาพรวมเอกสาร Autonomous Maintenance (ใบงาน UiType = 1) ตั้งแต่ 1 ส.ค. 2026 — ตัวเลขสีแดง/ส้มคือ '),
              TextSpan(
                text: 'งานค้าง',
                style: TextStyle(fontWeight: FontWeight.w700, color: _fg),
              ),
              TextSpan(text: ' แตะเพื่อดูรายการ'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    Key? key,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _buildFilterCard(AmSummaryViewModel vm) {
    final statusText = vm.errorMessage != null
        ? 'ผิดพลาด: ${vm.errorMessage}'
        : vm.isLoadingMonthly
            ? (vm.isRefreshing ? 'กำลังคำนวณใหม่…' : 'กำลังโหลด…')
            : !vm.hasLoadedOnce
                ? 'เลือกตัวกรองแล้วกด "แสดง" หรือ "คำนวณใหม่" เพื่อดูข้อมูล'
                : 'อัปเดตล่าสุด ${_fmtDateTime(vm.lastRefreshDate)}';

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // Job dropdown
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ใบงาน',
                        style: TextStyle(fontSize: 11.5, color: _fgMuted)),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: vm.selectedJobId,
                          dropdownColor: _surface,
                          style: const TextStyle(fontSize: 13, color: _fg),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('ทั้งหมด',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            ...vm.jobOptions.map(
                              (opt) => DropdownMenuItem<String?>(
                                value: opt.jobId.toString(),
                                child: Text(
                                  opt.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => vm.selectJob(val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // From month
              _buildMonthField(
                label: 'ตั้งแต่เดือน',
                valueText: _fmtMonth(vm.fromMonth),
                hasValue: vm.fromMonth != null,
                onTap: () => _pickMonth(
                  title: 'เลือกเดือนเริ่มต้น',
                  initial: vm.fromMonth,
                  onSelected: vm.setFromMonth,
                ),
              ),
              // To month
              _buildMonthField(
                label: 'ถึงเดือน',
                valueText: _fmtMonth(vm.toMonth),
                hasValue: vm.toMonth != null,
                onTap: () => _pickMonth(
                  title: 'เลือกเดือนสิ้นสุด',
                  initial: vm.toMonth,
                  onSelected: vm.setToMonth,
                ),
              ),
              // Apply button (refresh=0)
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    backgroundColor: _surface,
                    side: const BorderSide(color: _accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed:
                      vm.isLoadingMonthly ? null : () => vm.applyFilters(),
                  child: const Text(
                    'แสดง',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              // Refresh button (refresh=1)
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: vm.isLoadingMonthly
                      ? null
                      : () => vm.load(refresh: true),
                  icon: vm.isLoadingMonthly && vm.isRefreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync, size: 16),
                  label: const Text(
                    'คำนวณใหม่',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (vm.isLoadingMonthly) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: vm.errorMessage != null ? _critical : _fgMuted,
                    fontWeight: vm.errorMessage != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthField({
    required String label,
    required String valueText,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: _fgMuted)),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasValue ? _accent : _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasValue ? _fg : _fgMuted,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_month, size: 16, color: _fgMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(AmSummaryViewModel vm) {
    final tiles = [
      _KpiData(
        label: 'เอกสารที่บันทึก',
        value: _fmtInt(vm.totalDocs),
        hint: 'จุดตรวจ ${_fmtInt(vm.totalTags)} จุด',
        tone: _KpiTone.normal,
        mode: AmSummaryDetailMode.docs,
      ),
      _KpiData(
        label: '% จุดผิดปกติ',
        value: _fmtPct(vm.issuePct),
        hint: '${_fmtInt(vm.totalIssues)} จุด (ผิดปกติ/หลุดสเปก/อ่านไม่ได้)',
        tone: _KpiTone.normal,
        mode: AmSummaryDetailMode.abnormal,
      ),
      _KpiData(
        label: 'ยังไม่ verify',
        value: _fmtInt(vm.totalPendingVerify),
        hint: 'จุดผิดปกติที่ยังไม่มีใครตอบรับ',
        tone: vm.totalPendingVerify > 0 ? _KpiTone.alert : _KpiTone.normal,
        mode: AmSummaryDetailMode.pending,
      ),
      _KpiData(
        label: 'เคสค้าง',
        value: _fmtInt(vm.totalOpenCase),
        hint: 'เปิดแล้ว ยังไม่ปิด',
        tone: vm.totalOpenCase > 0 ? _KpiTone.alert : _KpiTone.normal,
        mode: AmSummaryDetailMode.opencase,
      ),
      _KpiData(
        label: 'หัวหน้ายังไม่ตรวจ',
        value: _fmtInt(vm.totalNoSupervisor),
        hint: 'เอกสาร (${_fmtPct(vm.noSupervisorPct)})',
        tone: vm.totalNoSupervisor > 0 ? _KpiTone.warn : _KpiTone.normal,
        mode: AmSummaryDetailMode.nosup,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final int crossCount = maxW >= 960
            ? 5
            : maxW >= 620
                ? 3
                : 2;
        const double spacing = 10;
        final double itemWidth =
            (maxW - spacing * (crossCount - 1)) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles.map((t) {
            final isLastOdd =
                crossCount == 2 && t == tiles.last && tiles.length.isOdd;
            return SizedBox(
              width: isLastOdd ? maxW : itemWidth,
              child: _buildKpiTile(t, vm),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiTile(_KpiData data, AmSummaryViewModel vm) {
    final Color bgColor;
    final Color borderColor;
    final Color valColor;

    switch (data.tone) {
      case _KpiTone.alert:
        bgColor = _criticalSoft;
        borderColor = _critical;
        valColor = _critical;
        break;
      case _KpiTone.warn:
        bgColor = _warnSoft;
        borderColor = _warn;
        valColor = _warn;
        break;
      case _KpiTone.normal:
        bgColor = _surface;
        borderColor = _border;
        valColor = _fg;
        break;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          vm.setDetailMode(data.mode);
          _scrollToDetail();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(fontSize: 12, color: _fgMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: valColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.hint,
                style: const TextStyle(fontSize: 11, color: _fgFaint),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobSummaryCard(AmSummaryViewModel vm) {
    final jobs = vm.jobAggregates;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'รายใบงาน',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _fg),
              ),
              Text(
                'แตะแถวเพื่อดูเอกสารของใบงานนั้น',
                style: TextStyle(fontSize: 12, color: _fgMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (vm.isLoadingMonthly && jobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('กำลังโหลด…',
                  style: TextStyle(fontSize: 13, color: _fgMuted)),
            )
          else if (!vm.hasLoadedOnce)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('กด "แสดง" หรือ "คำนวณใหม่" เพื่อโหลดข้อมูล',
                  style: TextStyle(fontSize: 13, color: _fgMuted)),
            )
          else if (jobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('ไม่มีข้อมูลในช่วงที่เลือก',
                  style: TextStyle(fontSize: 13, color: _fgMuted)),
            )
          else
            Scrollbar(
              controller: _jobTableScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _jobTableScrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowHeight: 44,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 68,
                  columnSpacing: 16,
                  horizontalMargin: 8,
                  dividerThickness: 0.7,
                  headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _fgMuted,
                  ),
                  columns: const [
                    DataColumn(label: Text('ใบงาน / เครื่อง')),
                    DataColumn(label: Text('พื้นที่')),
                    DataColumn(label: Text('เอกสาร'), numeric: true),
                    DataColumn(label: Text('จุดตรวจ'), numeric: true),
                    DataColumn(label: Text('ผิดปกติ\nเดินได้'), numeric: true),
                    DataColumn(label: Text('ผิดปกติ\nหยุด'), numeric: true),
                    DataColumn(label: Text('หลุดสเปก'), numeric: true),
                    DataColumn(label: Text('อ่านค่า\nไม่ได้'), numeric: true),
                    DataColumn(label: Text('% ผิดปกติ')),
                    DataColumn(label: Text('ยังไม่\nverify'), numeric: true),
                    DataColumn(label: Text('เคส\nค้าง'), numeric: true),
                    DataColumn(
                        label: Text('หัวหน้า\nยังไม่ตรวจ'), numeric: true),
                    DataColumn(
                        label: Text('หัวหน้าตรวจ\nเฉลี่ย (ชม.)'), numeric: true),
                  ],
                  rows: jobs.map((g) {
                    final isSelected = vm.selectedJobId == g.jobId.toString();
                    return DataRow(
                      selected: isSelected,
                      color: WidgetStateProperty.resolveWith((states) {
                        if (isSelected) return _accentSoft;
                        return null;
                      }),
                      onSelectChanged: (_) async {
                        final selected = await vm.toggleJobRow(g.jobId);
                        if (selected) _scrollToDetail();
                      },
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  g.machineName.isNotEmpty
                                      ? g.machineName
                                      : g.jobName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _fg,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${g.jobName} · Job ${g.jobId}',
                                  style: const TextStyle(
                                      fontSize: 11, color: _fgMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(g.location,
                            style: const TextStyle(fontSize: 12.5, color: _fg))),
                        DataCell(_numText(g.documentCount)),
                        DataCell(_numText(g.tagCount)),
                        DataCell(
                            _numText(g.abnormalRunningCount, tone: _NumTone.warn)),
                        DataCell(_numText(g.abnormalStoppedCount,
                            tone: _NumTone.critical)),
                        DataCell(
                            _numText(g.outOfSpecCount, tone: _NumTone.warn)),
                        DataCell(_numText(g.unreadableCount)),
                        DataCell(_pctBarCell(g.issuePct)),
                        DataCell(_numText(g.pendingVerifyCount,
                            tone: _NumTone.critical)),
                        DataCell(
                            _numText(g.caseOpenCount, tone: _NumTone.critical)),
                        DataCell(_numText(g.supervisorNotCheckedCount,
                            tone: _NumTone.warn)),
                        DataCell(
                          Text(
                            g.avgSupervisorLagHours != null
                                ? g.avgSupervisorLagHours!.toStringAsFixed(1)
                                : '–',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _fg,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(AmSummaryViewModel vm) {
    final months = vm.monthAggregates;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'รายเดือน',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _fg),
              ),
              Text(
                'รวมทุกใบงานตามตัวกรอง',
                style: TextStyle(fontSize: 12, color: _fgMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!vm.hasLoadedOnce && !vm.isLoadingMonthly)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('ยังไม่ได้โหลดข้อมูล',
                  style: TextStyle(fontSize: 13, color: _fgMuted)),
            )
          else if (months.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('ไม่มีข้อมูล',
                  style: TextStyle(fontSize: 13, color: _fgMuted)),
            )
          else
            Scrollbar(
              controller: _monthTableScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _monthTableScrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 54,
                  columnSpacing: 18,
                  horizontalMargin: 8,
                  dividerThickness: 0.7,
                  headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _fgMuted,
                  ),
                  columns: const [
                    DataColumn(label: Text('เดือน')),
                    DataColumn(label: Text('เอกสาร'), numeric: true),
                    DataColumn(label: Text('จุดตรวจ'), numeric: true),
                    DataColumn(label: Text('ผิดปกติรวม'), numeric: true),
                    DataColumn(label: Text('% ผิดปกติ')),
                    DataColumn(label: Text('ยังไม่ verify'), numeric: true),
                    DataColumn(label: Text('เปิดเคส\nซ่อมเอง'), numeric: true),
                    DataColumn(
                        label: Text('เปิดเคส\nใบแจ้งซ่อม'), numeric: true),
                    DataColumn(label: Text('เคสค้าง'), numeric: true),
                    DataColumn(label: Text('% หัวหน้าตรวจ'), numeric: true),
                  ],
                  rows: months.map((m) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          m.yearMonth,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _fg,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )),
                        DataCell(_numText(m.documentCount)),
                        DataCell(_numText(m.tagCount)),
                        DataCell(_numText(m.issueCount)),
                        DataCell(_pctBarCell(m.issuePct)),
                        DataCell(_numText(m.pendingVerifyCount,
                            tone: _NumTone.critical)),
                        DataCell(_numText(m.caseSelfRepairCount)),
                        DataCell(_numText(m.caseRepairRequestCount)),
                        DataCell(
                            _numText(m.caseOpenCount, tone: _NumTone.critical)),
                        DataCell(
                          Text(
                            _fmtPct(m.supervisorCheckedPct),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _fg,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(AmSummaryViewModel vm) {
    return _buildSectionCard(
      key: _detailSectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียด',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _fg),
          ),
          const SizedBox(height: 10),
          // 5 Pill Tabs
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AmSummaryDetailMode.values.map((mode) {
              final active = vm.detailMode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: active,
                showCheckmark: false,
                selectedColor: _accent,
                backgroundColor: _surface,
                side: BorderSide(color: active ? _accent : _border),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _fgMuted,
                ),
                shape: const StadiumBorder(),
                onSelected: (_) => vm.setDetailMode(mode),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Breadcrumb
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                'ขอบเขต: ${vm.selectedJobId != null ? 'Job ${vm.selectedJobId}' : 'ทุกใบงาน'}',
                style: const TextStyle(fontSize: 12.5, color: _fgMuted),
              ),
              if (vm.selectedJobId != null)
                InkWell(
                  onTap: () => vm.selectJob(null),
                  child: const Text(
                    '(ล้างใบงาน)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (vm.selectedDocumentId != null) ...[
                const Text('›',
                    style: TextStyle(fontSize: 12.5, color: _fgMuted)),
                Text(
                  'เอกสาร ${vm.selectedDocumentId}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _fg,
                  ),
                ),
                InkWell(
                  onTap: vm.clearDocumentFilter,
                  child: const Text(
                    '(ล้าง)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Detail body
          if (!vm.hasLoadedOnce && !vm.isLoadingDetail)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'กด "แสดง" หรือ "คำนวณใหม่" เพื่อโหลดข้อมูลรายละเอียด',
                style: TextStyle(fontSize: 13, color: _fgMuted),
              ),
            )
          else if (vm.isLoadingDetail)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
                    SizedBox(height: 8),
                    Text('กำลังโหลดรายละเอียด…',
                        style: TextStyle(fontSize: 12.5, color: _fgMuted)),
                  ],
                ),
              ),
            )
          else if (vm.detailErrorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'ผิดพลาด: ${vm.detailErrorMessage}',
                style: const TextStyle(fontSize: 13, color: _critical),
              ),
            )
          else if (vm.detailMode.usesDocuments)
            _buildDocumentTable(vm, vm.filteredDocuments)
          else
            _buildAbnormalTable(vm.filteredAbnormals),
        ],
      ),
    );
  }

  Widget _buildDocumentTable(
      AmSummaryViewModel vm, List<AmSummaryDocumentRow> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('ไม่มีรายการ',
            style: TextStyle(fontSize: 13, color: _fgMuted)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_fmtInt(rows.length)} เอกสาร · แตะแถวเพื่อดูจุดผิดปกติ หรือกด "เปิด" เพื่อเข้าหน้าเอกสารออนไลน์',
          style: const TextStyle(fontSize: 11.5, color: _fgMuted),
        ),
        const SizedBox(height: 8),
        Scrollbar(
          controller: _detailTableScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _detailTableScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 40,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 74,
              columnSpacing: 16,
              horizontalMargin: 8,
              dividerThickness: 0.7,
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _fgMuted,
              ),
              columns: const [
                DataColumn(label: Text('วันเวลา')),
                DataColumn(label: Text('เครื่อง')),
                DataColumn(label: Text('Lot')),
                DataColumn(label: Text('ผู้บันทึก')),
                DataColumn(label: Text('ช่วงที่ตรวจ')),
                DataColumn(label: Text('จุดตรวจ'), numeric: true),
                DataColumn(label: Text('ผิดปกติ'), numeric: true),
                DataColumn(label: Text('ยังไม่ verify'), numeric: true),
                DataColumn(label: Text('เคสค้าง'), numeric: true),
                DataColumn(label: Text('หัวหน้าตรวจ')),
                DataColumn(label: Text('ออนไลน์')),
              ],
              rows: rows.map((r) {
                return DataRow(
                  onSelectChanged: (_) =>
                      vm.selectDocumentForDrilldown(r.documentId),
                  cells: [
                    DataCell(Text(
                      _fmtDateTime(r.documentCreateDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _fg,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    )),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              r.machineName,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Job ${r.jobId}',
                              style: const TextStyle(
                                  fontSize: 11, color: _fgMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(r.lot.isEmpty ? '–' : r.lot,
                        style: const TextStyle(fontSize: 12, color: _fg))),
                    DataCell(Text(r.createUser.isEmpty ? '–' : r.createUser,
                        style: const TextStyle(fontSize: 12, color: _fg))),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          r.phaseList.isEmpty ? '–' : r.phaseList,
                          style: const TextStyle(fontSize: 12, color: _fg),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(_numText(r.tagCount)),
                    DataCell(_numText(r.issueCount, tone: _NumTone.warn)),
                    DataCell(
                        _numText(r.pendingVerifyCount, tone: _NumTone.critical)),
                    DataCell(
                        _numText(r.caseOpenCount, tone: _NumTone.critical)),
                    DataCell(_buildSupervisorStatusCell(r)),
                    DataCell(
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: _accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 15),
                        label: const Text('เปิด',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () => _openOnlineDocument(
                          documentId: r.documentId,
                          jobId: r.jobId,
                          machineName: r.machineName,
                          lot: r.lot,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorStatusCell(AmSummaryDocumentRow r) {
    final Widget badge;
    if (r.isSupervisorChecked) {
      badge = _pill('ครบ', _PillTone.good);
    } else if (r.supervisorCheckedPhaseCount > 0) {
      badge = _pill('${r.supervisorCheckedPhaseCount}/${r.phaseCount} ช่วง',
          _PillTone.warn);
    } else {
      badge = _pill('ยังไม่ตรวจ', _PillTone.critical);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        badge,
        if (r.firstSupervisorCheckDate != null &&
            r.firstSupervisorCheckDate!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${_fmtDateTime(r.firstSupervisorCheckDate)}'
              '${r.supervisorLagHours != null ? ' · ${r.supervisorLagHours!.toStringAsFixed(1)} ชม.' : ''}',
              style: const TextStyle(fontSize: 10.5, color: _fgMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildAbnormalTable(List<AmSummaryAbnormalRow> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('ไม่มีรายการค้าง',
            style: TextStyle(fontSize: 13, color: _fgMuted)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_fmtInt(rows.length)} จุด · กด "เปิด" เพื่อเข้าตรวจสอบเอกสารออนไลน์',
          style: const TextStyle(fontSize: 11.5, color: _fgMuted),
        ),
        const SizedBox(height: 8),
        Scrollbar(
          controller: _detailTableScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _detailTableScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 96,
              columnSpacing: 16,
              horizontalMargin: 8,
              dividerThickness: 0.7,
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _fgMuted,
              ),
              columns: const [
                DataColumn(label: Text('วันเวลา')),
                DataColumn(label: Text('เครื่อง / ช่วง')),
                DataColumn(label: Text('หมวด AM')),
                DataColumn(label: Text('จุดตรวจ')),
                DataColumn(label: Text('ผล')),
                DataColumn(label: Text('ค่า / สเปก')),
                DataColumn(label: Text('Verify ล่าสุด')),
                DataColumn(label: Text('เคส')),
                DataColumn(label: Text('ออนไลน์')),
              ],
              rows: rows.map((r) {
                final issueInfo = _issueBadgeInfo(r.issueType);
                final hasSpec =
                    (r.specMin != null && r.specMin!.isNotEmpty) ||
                        (r.specMax != null && r.specMax!.isNotEmpty);

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _fmtDateTime(r.documentCreateDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _fg,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            r.documentId,
                            style: const TextStyle(
                                fontSize: 10.5, color: _fgMuted),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              r.machineName,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              r.phaseName,
                              style: const TextStyle(
                                  fontSize: 11, color: _fgMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          r.tagGroupName,
                          style: const TextStyle(fontSize: 12, color: _fg),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              r.tagName,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _fg),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (r.recordRemark != null &&
                                r.recordRemark!.isNotEmpty)
                              Text(
                                'หมายเหตุ: ${r.recordRemark}',
                                style: const TextStyle(
                                    fontSize: 11, color: _fgMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(_pill(issueInfo.$2, issueInfo.$1)),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.value.isEmpty ? '–' : r.value,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _fg,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (hasSpec)
                            Text(
                              'สเปก ${r.specMin ?? '…'} – ${r.specMax ?? '…'} ${r.unit ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                  fontSize: 10.5, color: _fgMuted),
                            ),
                        ],
                      ),
                    ),
                    DataCell(_buildVerifyCell(r)),
                    DataCell(_buildCaseCell(r)),
                    DataCell(
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: _accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 15),
                        label: const Text('เปิด',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () => _openOnlineDocument(
                          documentId: r.documentId,
                          jobId: r.jobId,
                          machineName: r.machineName,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyCell(AmSummaryAbnormalRow r) {
    if (r.lastVerifyType == null) {
      return _pill('ยังไม่ verify', _PillTone.critical);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pill(
            r.lastVerifyTypeName ?? 'Verify #${r.lastVerifyType}',
            r.lastVerifyType == 1 ? _PillTone.good : _PillTone.warn,
          ),
          const SizedBox(height: 3),
          Text(
            '${r.lastVerifyBy ?? '-'} · ${_fmtDateTime(r.lastVerifyDate)}'
            '${r.verifyCount > 1 ? ' · ${r.verifyCount} ครั้ง' : ''}',
            style: const TextStyle(fontSize: 10.5, color: _fgMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (r.lastVerifyRemark != null && r.lastVerifyRemark!.isNotEmpty)
            Text(
              r.lastVerifyRemark!,
              style: const TextStyle(fontSize: 10.5, color: _fgMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildCaseCell(AmSummaryAbnormalRow r) {
    if (r.problemId == null) {
      return const Text('–', style: TextStyle(color: _fgFaint));
    }
    final isClosed =
        r.problemCloseDate != null && r.problemCloseDate!.trim().isNotEmpty;
    final caseTypeLabel = r.caseType == 'SELF_REPAIR'
        ? 'ซ่อมเอง'
        : r.caseType == 'REPAIR_REQUEST'
            ? 'ใบแจ้งซ่อม'
            : (r.caseType ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill(
          '#${r.problemId} ${isClosed ? 'ปิดแล้ว' : 'ค้าง ${r.caseAgeDays ?? 0} วัน'}',
          isClosed ? _PillTone.good : _PillTone.critical,
        ),
        if (caseTypeLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              caseTypeLabel,
              style: const TextStyle(fontSize: 10.5, color: _fgMuted),
            ),
          ),
      ],
    );
  }

  (_PillTone, String) _issueBadgeInfo(String issueType) {
    switch (issueType) {
      case 'ABNORMAL_STOPPED':
        return (_PillTone.critical, 'ผิดปกติ เครื่องหยุด');
      case 'ABNORMAL_RUNNING':
        return (_PillTone.warn, 'ผิดปกติ เครื่องเดินได้');
      case 'ABNORMAL':
        return (_PillTone.warn, 'ผิดปกติ');
      case 'OUT_OF_SPEC':
        return (_PillTone.warn, 'หลุดสเปก');
      case 'UNREADABLE':
        return (_PillTone.mute, 'อ่านค่าไม่ได้');
      case 'VERIFIED_ONLY':
        return (_PillTone.mute, 'ปกติ (มี verify)');
      default:
        return (_PillTone.mute, issueType.isEmpty ? '-' : issueType);
    }
  }

  Widget _numText(int value, {_NumTone tone = _NumTone.normal}) {
    if (value == 0) {
      return const Text(
        '0',
        style: TextStyle(
          fontSize: 12.5,
          color: _fgFaint,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }
    Color color = _fg;
    FontWeight weight = FontWeight.normal;
    if (tone == _NumTone.critical) {
      color = _critical;
      weight = FontWeight.w700;
    } else if (tone == _NumTone.warn) {
      color = _warn;
      weight = FontWeight.w700;
    }
    return Text(
      _fmtInt(value),
      style: TextStyle(
        fontSize: 12.5,
        color: color,
        fontWeight: weight,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _pctBarCell(double pct) {
    final ratio = math.min(100.0, pct * 5.0) / 100.0;
    return SizedBox(
      width: 82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _fmtPct(pct),
            style: const TextStyle(
              fontSize: 12,
              color: _fg,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              width: double.infinity,
              color: _surface2,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(color: _critical),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, _PillTone tone) {
    final Color bg;
    final Color fg;
    Color? borderColor;

    switch (tone) {
      case _PillTone.good:
        bg = _goodSoft;
        fg = _good;
        break;
      case _PillTone.warn:
        bg = _warnSoft;
        fg = _warn;
        break;
      case _PillTone.critical:
        bg = _criticalSoft;
        fg = _critical;
        break;
      case _PillTone.mute:
        bg = _surface2;
        fg = _fgMuted;
        borderColor = _border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: const Text(
        'ที่มา: CheckSheet_Summary_Level2_JobMonthly, CheckSheet_Summary_Level1_Document, '
        'CheckSheet_Summary_Level1_Abnormal (SCADA).\n'
        'คำนวณใหม่ทั้งหมดด้วย CheckSheet_Summary_Refresh ทุกครั้งที่เปิดหน้า/กด "คำนวณใหม่".\n'
        '"หัวหน้าตรวจแล้ว" = ตรวจครบทุกช่วง (ก่อน/ระหว่าง/หลังผลิต ฯลฯ) ของเอกสาร · '
        '"ยังไม่ verify" = จุดผิดปกติ/หลุดสเปก/อ่านค่าไม่ได้ ที่ยังไม่มีการ verify',
        style: TextStyle(fontSize: 11.5, color: _fgFaint, height: 1.55),
      ),
    );
  }
}

class _MonthPickResult {
  final DateTime? month;
  const _MonthPickResult(this.month);
}

enum _KpiTone { normal, warn, alert }

enum _NumTone { normal, warn, critical }

enum _PillTone { good, warn, critical, mute }

class _KpiData {
  final String label;
  final String value;
  final String hint;
  final _KpiTone tone;
  final AmSummaryDetailMode mode;

  const _KpiData({
    required this.label,
    required this.value,
    required this.hint,
    required this.tone,
    required this.mode,
  });
}
