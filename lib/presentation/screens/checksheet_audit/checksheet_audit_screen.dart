// lib/presentation/screens/checksheet_audit/checksheet_audit_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/models/checksheet_audit_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/checksheet_audit/checksheet_audit_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart';

class ChecksheetAuditScreen extends StatefulWidget {
  final String title;

  const ChecksheetAuditScreen({
    super.key,
    this.title = 'บันทึก Check Sheet',
  });

  @override
  State<ChecksheetAuditScreen> createState() => _ChecksheetAuditScreenState();
}

class _ChecksheetAuditScreenState extends State<ChecksheetAuditScreen>
    with AutomaticKeepAliveClientMixin {
  // Editorial palette matched to CHECKSHEET_AUDIT demo
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

  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _listTableScrollController = ScrollController();
  final ScrollController _supTableScrollController = ScrollController();
  final ScrollController _itemsTableScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mainScrollController.dispose();
    _listTableScrollController.dispose();
    _supTableScrollController.dispose();
    _itemsTableScrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  String _fmtDateShort(String? s) {
    if (s == null || s.trim().isEmpty) return '–';
    final clean = s.replaceAll('T', ' ').trim();
    return clean.length >= 16 ? clean.substring(0, 16) : clean;
  }

  String _txt(String? s) => (s == null || s.trim().isEmpty) ? '–' : s.trim();

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _handleExportCsv(ChecksheetAuditViewModel vm) async {
    try {
      if (kIsWeb) {
        final csv = vm.buildCsvContent();
        await Clipboard.setData(ClipboardData(text: csv));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คัดลอกข้อมูล CSV ไปยังคลิปบอร์ดแล้ว'),
            backgroundColor: _accent,
          ),
        );
        return;
      }

      final path = await vm.exportCsvFile();
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกไฟล์ CSV แล้ว: $path'),
            backgroundColor: _good,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งออก CSV ไม่สำเร็จ: $e'),
          backgroundColor: _critical,
        ),
      );
    }
  }

  void _openOnlineDocument(AuditDocumentRow doc) {
    final userId =
        context.read<LoginViewModel>().loggedInUser?.userId ?? '600201';
    Navigator.pushNamed(
      context,
      '/document_machine_online',
      arguments: {
        'title':
            doc.machineName.isNotEmpty ? doc.machineName : doc.documentId,
        'documentId': doc.documentId,
        'jobId': doc.jobId.toString(),
        'userId': userId,
        'lot': doc.lot.isNotEmpty ? doc.lot : null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ChecksheetAuditViewModel>(
      builder: (context, vm, _) {
        final canExportCsv =
            !vm.isInDetailView && vm.filteredDocs.isNotEmpty && !vm.isLoadingList;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            leading: vm.isInDetailView
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'กลับไปรายการ',
                    onPressed: vm.backToList,
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.isInDetailView
                      ? 'รายละเอียดเอกสาร Audit'
                      : widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'SCADA · CheckSheet Audit (Read-only)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            actions: [
              if (!vm.isInDetailView)
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'ดาวน์โหลด Excel (CSV)',
                  onPressed: canExportCsv ? () => _handleExportCsv(vm) : null,
                ),
              IconButton(
                icon: vm.isLoadingList || vm.isLoadingDetail
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'โหลดข้อมูลใหม่',
                onPressed: (vm.isLoadingList || vm.isLoadingDetail)
                    ? null
                    : () {
                        if (vm.isInDetailView && vm.currentDocument != null) {
                          vm.openDocument(vm.currentDocument!);
                        } else {
                          vm.loadDocuments();
                        }
                      },
              ),
            ],
          ),
          body: RefreshIndicator(
            color: _accent,
            onRefresh: () async {
              if (vm.isInDetailView && vm.currentDocument != null) {
                await vm.openDocument(vm.currentDocument!);
              } else {
                await vm.loadDocuments();
              }
            },
            child: SingleChildScrollView(
              controller: _mainScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIntroBanner(),
                      const SizedBox(height: 14),
                      _buildFilterCard(vm, canExportCsv),
                      const SizedBox(height: 14),
                      if (vm.isInDetailView)
                        _buildDetailView(vm)
                      else
                        _buildListView(vm),
                      const SizedBox(height: 16),
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroBanner() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCADA · CHECKSHEET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _accent,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'แสดงทุกเอกสาร Check Sheet ที่บันทึกในช่วงวันที่ที่เลือก ทุกใบงาน ดึงจากข้อมูลบันทึกจริงในขณะเปิดดู แตะแถวเพื่อดูรายละเอียดทุกรายการตรวจ',
          style: TextStyle(fontSize: 13, color: _fgMuted, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _buildFilterCard(ChecksheetAuditViewModel vm, bool canExportCsv) {
    final formOpts = vm.formOptions;
    final phaseOpts = vm.phaseOptions;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // From date
              _buildDateField(
                label: 'ตั้งแต่วันที่',
                valueText: vm.fromDateIso,
                onTap: () => _pickDate(
                  initial: vm.fromDate,
                  onPicked: vm.setFromDate,
                ),
              ),
              // To date
              _buildDateField(
                label: 'ถึงวันที่',
                valueText: vm.toDateIso,
                onTap: () => _pickDate(
                  initial: vm.toDate,
                  onPicked: vm.setToDate,
                ),
              ),
              // Show button
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: vm.isLoadingList ? null : vm.loadDocuments,
                  icon: vm.isLoadingList
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search, size: 17),
                  label: const Text(
                    'แสดงข้อมูล',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              // Form cross-filter dropdown
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
                        border: Border.all(
                          color: vm.selectedForm != null ? _accent : _border,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: vm.selectedForm,
                          dropdownColor: _surface,
                          style: const TextStyle(fontSize: 13, color: _fg),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('ทั้งหมด',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            ...formOpts.map(
                              (opt) => DropdownMenuItem<String?>(
                                value: opt.value,
                                child: Text(
                                  '${opt.value} (${opt.count})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => vm.setSelectedForm(val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Phase cross-filter dropdown
              SizedBox(
                width: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ช่วงการตรวจ',
                        style: TextStyle(fontSize: 11.5, color: _fgMuted)),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: vm.selectedPhase != null ? _accent : _border,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: vm.selectedPhase,
                          dropdownColor: _surface,
                          style: const TextStyle(fontSize: 13, color: _fg),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('ทั้งหมด',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            ...phaseOpts.map(
                              (opt) => DropdownMenuItem<String?>(
                                value: opt.value,
                                child: Text(
                                  '${opt.value} (${opt.count})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => vm.setSelectedPhase(val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // CSV Export button
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    backgroundColor: _surface,
                    side: BorderSide(
                        color: canExportCsv ? _accent : _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: canExportCsv ? () => _handleExportCsv(vm) : null,
                  icon: const Icon(Icons.table_view_outlined, size: 17),
                  label: const Text(
                    'ดาวน์โหลด Excel (CSV)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
          if (vm.isLoadingList || vm.listError != null) ...[
            const SizedBox(height: 10),
            Text(
              vm.listError != null ? vm.listError! : 'กำลังโหลด…',
              style: TextStyle(
                fontSize: 12.5,
                color: vm.listError != null ? _critical : _fgMuted,
                fontWeight:
                    vm.listError != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String valueText,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 145,
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
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _fg,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 15, color: _fgMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LIST VIEW ----------------
  Widget _buildListView(ChecksheetAuditViewModel vm) {
    final rows = vm.filteredDocs;
    final scopeParts = <String>[
      if (vm.selectedForm != null) 'ใบงาน ${vm.selectedForm}',
      if (vm.selectedPhase != null) 'ช่วงการตรวจ ${vm.selectedPhase}',
    ];
    final scopeSuffix =
        scopeParts.isEmpty ? '' : ' · ${scopeParts.join(' · ')}';

    final String titleText;
    if (!vm.hasLoadedOnce) {
      titleText = 'เลือกช่วงวันที่ แล้วกด "แสดงข้อมูล"';
    } else if (rows.isEmpty) {
      titleText =
          'ไม่พบเอกสารในช่วง ${vm.loadedFromDate} ถึง ${vm.loadedToDate}$scopeSuffix';
    } else {
      titleText =
          'พบ ${_intFmt.format(rows.length)} เอกสาร จาก ${vm.distinctJobCount} ใบงาน · '
          '${vm.loadedFromDate} ถึง ${vm.loadedToDate}$scopeSuffix';
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _fg,
            ),
          ),
          if (vm.isLoadingList && rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: _accent),
              ),
            )
          else if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            Scrollbar(
              controller: _listTableScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _listTableScrollController,
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _fgMuted,
                  ),
                  columns: const [
                    DataColumn(label: Text('#'), numeric: true),
                    DataColumn(label: Text('วันเวลาที่บันทึก')),
                    DataColumn(label: Text('ใบงาน')),
                    DataColumn(label: Text('เครื่องจักร')),
                    DataColumn(label: Text('ช่วงการตรวจ')),
                    DataColumn(label: Text('Lot')),
                    DataColumn(label: Text('ผู้บันทึก')),
                    DataColumn(label: Text('รายการ\nตรวจ'), numeric: true),
                    DataColumn(label: Text('ปกติ'), numeric: true),
                    DataColumn(label: Text('ผิดปกติ /\nนอกสเปก'), numeric: true),
                    DataColumn(label: Text('อ่านค่า\nไม่ได้'), numeric: true),
                    DataColumn(label: Text('Verify\nแล้ว'), numeric: true),
                    DataColumn(label: Text('เคส\n(ยังเปิด)'), numeric: true),
                    DataColumn(label: Text('หัวหน้าตรวจ')),
                    DataColumn(label: Text('สถานะ')),
                  ],
                  rows: List.generate(rows.length, (index) {
                    final d = rows[index];
                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return _accentSoft;
                        }
                        return null;
                      }),
                      onSelectChanged: (_) {
                        vm.openDocument(d);
                        _scrollToTop();
                      },
                      cells: [
                        DataCell(Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _fgMuted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )),
                        DataCell(Text(
                          _fmtDateShort(d.createDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _fg,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 230),
                            child: Text(
                              _txt(d.formName),
                              style: const TextStyle(
                                  fontSize: 12.5, color: _fg),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 190),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _txt(d.machineName),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _fg,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _txt(d.location),
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
                            constraints: const BoxConstraints(maxWidth: 170),
                            child: Text(
                              _txt(d.phases),
                              style: const TextStyle(
                                  fontSize: 12, color: _fg),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(
                          _txt(d.lot),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _fg,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )),
                        DataCell(Text(
                          _txt(d.createUser),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _fg,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )),
                        DataCell(_countText(d.itemCount)),
                        DataCell(_countText(d.normalCount)),
                        DataCell(_countText(d.issueCount, hot: true)),
                        DataCell(_countText(d.unreadableCount, hot: true)),
                        DataCell(_countText(d.verifiedCount)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _countText(d.caseCount),
                              if (d.openCaseCount > 0)
                                Text(
                                  ' (${d.openCaseCount})',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _critical,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          d.supervisorUser != null &&
                                  d.supervisorUser!.trim().isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      d.supervisorUser!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _fg,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _fmtDateShort(d.supervisorCheck),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _fgMuted,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const Text('–',
                                  style: TextStyle(color: _fgFaint)),
                        ),
                        DataCell(_docStatusPill(d)),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- DETAIL VIEW ----------------
  Widget _buildDetailView(ChecksheetAuditViewModel vm) {
    final doc = vm.currentDocument!;
    final detail = vm.currentDetail;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back & Open Online Document action bar
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  backgroundColor: _surface,
                  side: const BorderSide(color: _accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: vm.backToList,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('กลับไปรายการ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade900,
                  backgroundColor: _surface,
                  side: BorderSide(color: Colors.blue.shade900),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openOnlineDocument(doc),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('เปิดหน้าเอกสารออนไลน์',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (vm.isLoadingDetail)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accent),
                    ),
                    SizedBox(width: 8),
                    Text('กำลังโหลด…',
                        style: TextStyle(fontSize: 12.5, color: _fgMuted)),
                  ],
                ),
              if (vm.detailError != null)
                Text(
                  vm.detailError!,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: _critical,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Document title + metadata
          Text(
            _txt(doc.formName),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _fg),
          ),
          const SizedBox(height: 12),
          _buildMetadataGrid(doc),
          if (detail != null) ...[
            const SizedBox(height: 22),
            _buildSupervisorSection(detail.supervisorChecks),
            const SizedBox(height: 22),
            _buildItemsSection(detail),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataGrid(AuditDocumentRow d) {
    final entries = <Widget>[
      _metaItem(
        'เครื่องจักร',
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13.5, color: _fg),
            children: [
              TextSpan(text: _txt(d.machineName)),
              TextSpan(
                text: ' (${_txt(d.location)})',
                style: const TextStyle(color: _fgMuted),
              ),
            ],
          ),
        ),
      ),
      _metaItem('ช่วงการตรวจ',
          Text(_txt(d.phases), style: const TextStyle(fontSize: 13.5, color: _fg))),
      _metaItem(
          'Lot',
          Text(_txt(d.lot),
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _fg,
                  fontFeatures: [FontFeature.tabularFigures()]))),
      _metaItem(
          'ผู้บันทึก',
          Text(_txt(d.createUser),
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _fg,
                  fontFeatures: [FontFeature.tabularFigures()]))),
      _metaItem(
          'วันเวลาที่บันทึก',
          Text(_fmtDateShort(d.createDate),
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _fg,
                  fontFeatures: [FontFeature.tabularFigures()]))),
      _metaItem(
          'Sync ล่าสุด',
          Text(_fmtDateShort(d.lastSync),
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _fg,
                  fontFeatures: [FontFeature.tabularFigures()]))),
      _metaItem(
          'เลขเอกสาร',
          Text(_txt(d.documentId),
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _fg,
                  fontFeatures: [FontFeature.tabularFigures()]))),
      _metaItem('สถานะ', _docStatusPill(d)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cols = maxW >= 900
            ? 4
            : maxW >= 540
                ? 2
                : 1;
        const spacing = 16.0;
        final itemW = (maxW - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: entries.map((e) => SizedBox(width: itemW, child: e)).toList(),
        );
      },
    );
  }

  Widget _metaItem(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: _fgMuted)),
        const SizedBox(height: 2),
        value,
      ],
    );
  }

  Widget _buildSupervisorSection(List<AuditSupervisorCheck> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การตรวจของหัวหน้า',
          style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w700, color: _fg),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'ยังไม่มีหัวหน้าตรวจเอกสารนี้',
              style: TextStyle(fontSize: 12.5, color: _fgMuted),
            ),
          )
        else
          Scrollbar(
            controller: _supTableScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _supTableScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 68,
                columnSpacing: 20,
                horizontalMargin: 8,
                dividerThickness: 0.7,
                headingTextStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _fgMuted,
                ),
                columns: const [
                  DataColumn(label: Text('ช่วงการตรวจ')),
                  DataColumn(label: Text('ผู้ตรวจ')),
                  DataColumn(label: Text('วันเวลา')),
                  DataColumn(label: Text('ความเห็น')),
                ],
                rows: rows
                    .map(
                      (s) => DataRow(
                        cells: [
                          DataCell(Text(_txt(s.phaseName),
                              style: const TextStyle(fontSize: 12.5, color: _fg))),
                          DataCell(Text(_txt(s.userId),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _fg,
                                  fontFeatures: [FontFeature.tabularFigures()]))),
                          DataCell(Text(_fmtDateShort(s.checkDateTime),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _fg,
                                  fontFeatures: [FontFeature.tabularFigures()]))),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(_txt(s.comment),
                                  style: const TextStyle(
                                      fontSize: 12.5, color: _fg)),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemsSection(AuditDocumentDetail detail) {
    final items = detail.items;
    final verifiesMap = detail.verifiesByRecordTagId;
    final casesMap = detail.casesByRecordTagId;

    // Group sequential items by phaseId (preserving exact server order!)
    final phaseGroups = <_PhaseGroup>[];
    int seqNo = 0;
    for (final it in items) {
      seqNo++;
      if (phaseGroups.isEmpty || phaseGroups.last.phaseId != it.phaseId) {
        phaseGroups.add(_PhaseGroup(
          phaseId: it.phaseId,
          phaseName: it.phaseName,
          entries: [],
        ));
      }
      phaseGroups.last.entries.add(_NumberedItem(seqNo, it));
    }

    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(42), // #
      1: FixedColumnWidth(160), // หมวด
      2: FixedColumnWidth(185), // รายการ
      3: FixedColumnWidth(230), // เกณฑ์ / สเปก
      4: FixedColumnWidth(105), // ค่าที่บันทึก
      5: FixedColumnWidth(115), // ผล
      6: FixedColumnWidth(155), // หมายเหตุ
      7: FixedColumnWidth(235), // Verify / เคส
    };
    const totalTableWidth = 42.0 + 160 + 185 + 230 + 105 + 115 + 155 + 235;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รายการตรวจ (${_intFmt.format(items.length)} รายการ)',
          style: const TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w700, color: _fg),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('ไม่พบรายการ',
                style: TextStyle(fontSize: 12.5, color: _fgMuted)),
          )
        else
          Scrollbar(
            controller: _itemsTableScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _itemsTableScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalTableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row
                    Table(
                      columnWidths: colWidths,
                      border: const TableBorder(
                        bottom: BorderSide(color: _border, width: 1.2),
                      ),
                      children: [
                        TableRow(
                          children: [
                            _headerCell('#', alignRight: true),
                            _headerCell('หมวด'),
                            _headerCell('รายการ'),
                            _headerCell('เกณฑ์ / สเปก'),
                            _headerCell('ค่าที่บันทึก'),
                            _headerCell('ผล'),
                            _headerCell('หมายเหตุ'),
                            _headerCell('Verify / เคส'),
                          ],
                        ),
                      ],
                    ),
                    // Phase groups + item rows
                    ...phaseGroups.expand((group) {
                      return [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 9),
                          decoration: const BoxDecoration(
                            color: _surface2,
                            border: Border(
                              bottom: BorderSide(color: _border),
                            ),
                          ),
                          child: Text(
                            'ช่วงการตรวจ: ${_txt(group.phaseName)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _fg,
                            ),
                          ),
                        ),
                        Table(
                          columnWidths: colWidths,
                          border: const TableBorder(
                            horizontalInside:
                                BorderSide(color: _border, width: 0.7),
                            bottom: BorderSide(color: _border, width: 0.7),
                          ),
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.top,
                          children: group.entries.map((entry) {
                            final it = entry.item;
                            final verifies =
                                verifiesMap[it.recordTagId] ?? const [];
                            final cases = casesMap[it.recordTagId] ?? const [];

                            return TableRow(
                              children: [
                                _bodyCell(
                                  Text(
                                    '${entry.no}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _fgMuted,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                                _bodyCell(Text(
                                  _txt(it.groupName),
                                  style: const TextStyle(
                                      fontSize: 12.5, color: _fg),
                                )),
                                _bodyCell(Text(
                                  _txt(it.tagName),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _fg,
                                  ),
                                )),
                                _bodyCell(_buildCriteriaCell(it)),
                                _bodyCell(_buildValueCell(it)),
                                _bodyCell(_resultPill(it.result)),
                                _bodyCell(Text(
                                  _txt(it.remark),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (it.remark == null ||
                                            it.remark!.trim().isEmpty)
                                        ? _fgFaint
                                        : _fg,
                                  ),
                                )),
                                _bodyCell(_buildTrailCell(verifies, cases)),
                              ],
                            );
                          }).toList(),
                        ),
                      ];
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _headerCell(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: _fgMuted,
        ),
      ),
    );
  }

  Widget _bodyCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: child,
    );
  }

  Widget _buildCriteriaCell(AuditCheckItem it) {
    final parts = <String>[
      if (it.description != null && it.description!.trim().isNotEmpty)
        it.description!.trim(),
      if (it.specification != null && it.specification!.trim().isNotEmpty)
        it.specification!.trim(),
    ];
    final sp = it.formattedSpec;

    if (parts.isEmpty && sp.isEmpty) {
      return const Text('–', style: TextStyle(fontSize: 12, color: _fgFaint));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          Text(
            parts.join('\n'),
            style: const TextStyle(fontSize: 11.5, color: _fgMuted, height: 1.4),
          ),
        if (sp.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: parts.isNotEmpty ? 3 : 0),
            child: Text(
              'สเปก $sp',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _fg,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildValueCell(AuditCheckItem it) {
    if (it.value == null || it.value!.trim().isEmpty) {
      return const Text('–', style: TextStyle(fontSize: 12.5, color: _fgFaint));
    }
    final showUnit =
        it.unit != null && it.unit!.trim().isNotEmpty && it.tagType == 'Number';
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, color: _fg),
        children: [
          TextSpan(
            text: it.value!.trim(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (showUnit)
            TextSpan(
              text: ' ${it.unit!.trim()}',
              style: const TextStyle(color: _fgMuted, fontSize: 11.5),
            ),
        ],
      ),
    );
  }

  Widget _buildTrailCell(
    List<AuditVerifyEntry> verifies,
    List<AuditCaseEntry> cases,
  ) {
    if (verifies.isEmpty && cases.isEmpty) {
      return const Text('–', style: TextStyle(fontSize: 12.5, color: _fgFaint));
    }

    final blocks = <Widget>[
      ...verifies.map((v) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11.5, color: _fg, height: 1.45),
                children: [
                  const TextSpan(
                    text: 'Verify ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: v.verifyTypeName),
                ],
              ),
            ),
            Text(
              '${v.verifyBy} · ${_fmtDateShort(v.verifyDate)}',
              style: const TextStyle(
                fontSize: 11,
                color: _fgMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (v.remark != null && v.remark!.trim().isNotEmpty)
              Text(
                v.remark!.trim(),
                style: const TextStyle(fontSize: 11.5, color: _fg),
              ),
          ],
        );
      }),
      ...cases.map((c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  'เคส #${c.problemId}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _fg,
                  ),
                ),
                _pill(
                  c.isOpen ? 'ยังเปิด' : 'ปิดแล้ว',
                  c.isOpen ? _AuditPillTone.critical : _AuditPillTone.good,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'เปิด ${c.createUser} · ${_fmtDateShort(c.createDate)}',
              style: const TextStyle(
                fontSize: 11,
                color: _fgMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (!c.isOpen)
              Text(
                'ปิด ${_txt(c.closeUser)} · ${_fmtDateShort(c.closeDate)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _fgMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            if (c.solvingDescription != null &&
                c.solvingDescription!.trim().isNotEmpty)
              Text(
                c.solvingDescription!.trim(),
                style: const TextStyle(fontSize: 11.5, color: _fg),
              ),
          ],
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(blocks.length, (i) {
        if (i == 0) return blocks[i];
        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border, width: 0.7)),
          ),
          child: blocks[i],
        );
      }),
    );
  }

  Widget _countText(int v, {bool hot = false}) {
    if (v == 0) {
      return const Text(
        '0',
        style: TextStyle(
          fontSize: 12.5,
          color: _fgFaint,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }
    return Text(
      _intFmt.format(v),
      style: TextStyle(
        fontSize: 12.5,
        color: hot ? _critical : _fg,
        fontWeight: hot ? FontWeight.w700 : FontWeight.normal,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _docStatusPill(AuditDocumentRow d) {
    return d.isFinished
        ? _pill('บันทึกเสร็จ', _AuditPillTone.good)
        : _pill('บันทึกยังไม่เสร็จ', _AuditPillTone.warn);
  }

  Widget _resultPill(String result) {
    switch (result) {
      case 'NORMAL':
        return _pill('ปกติ', _AuditPillTone.good);
      case 'IN_SPEC':
        return _pill('ในสเปก', _AuditPillTone.good);
      case 'ABNORMAL':
        return _pill('ผิดปกติ', _AuditPillTone.critical);
      case 'OUT_OF_SPEC':
        return _pill('นอกสเปก', _AuditPillTone.critical);
      case 'UNREADABLE':
        return _pill('อ่านค่าไม่ได้', _AuditPillTone.warn);
      case 'BLANK':
        return _pill('ไม่ได้บันทึก', _AuditPillTone.warn);
      case 'NOT_NUMBER':
        return _pill('ไม่ใช่ตัวเลข', _AuditPillTone.warn);
      case 'NO_SPEC':
        return _pill('ไม่มีสเปก', _AuditPillTone.mute);
      case 'RECORDED':
        return _pill('บันทึก', _AuditPillTone.mute);
      default:
        return _pill(result.isEmpty ? '–' : result, _AuditPillTone.mute);
    }
  }

  Widget _pill(String label, _AuditPillTone tone) {
    final Color bg;
    final Color fg;
    Color? borderColor;

    switch (tone) {
      case _AuditPillTone.good:
        bg = _goodSoft;
        fg = _good;
        break;
      case _AuditPillTone.warn:
        bg = _warnSoft;
        fg = _warn;
        break;
      case _AuditPillTone.critical:
        bg = _criticalSoft;
        fg = _critical;
        break;
      case _AuditPillTone.mute:
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
        'ผู้บันทึก / ผู้ verify / หัวหน้า แสดงเป็นรหัสพนักงาน · วันเวลาที่บันทึก = เวลาที่สร้างเอกสารบนอุปกรณ์ · '
        'เวลา sync = เวลาที่ข้อมูลเข้าเซิร์ฟเวอร์ · "ผิดปกติ / นอกสเปก" = ผลที่เลือกเป็น "ผิดปกติ…" หรือค่าตัวเลขอยู่นอกช่วงสเปก · '
        'หน้านี้อ่านอย่างเดียว ไม่สามารถแก้ไขข้อมูลได้',
        style: TextStyle(fontSize: 11.5, color: _fgFaint, height: 1.6),
      ),
    );
  }
}

enum _AuditPillTone { good, warn, critical, mute }

class _PhaseGroup {
  final String phaseId;
  final String phaseName;
  final List<_NumberedItem> entries;

  const _PhaseGroup({
    required this.phaseId,
    required this.phaseName,
    required this.entries,
  });
}

class _NumberedItem {
  final int no;
  final AuditCheckItem item;

  const _NumberedItem(this.no, this.item);
}
