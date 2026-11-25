// lib/presentation/screens/mt_request/mt_request_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _valOrDash(Object? v) {
    if (v == null) return '–';
    final s = v.toString().trim();
    return s.isEmpty ? '–' : s;
  }

  void _showResultFeedback(MtRequestActionResult res) {
    if (!mounted) return;
    final msg =
        res.message ?? (res.success ? 'ดำเนินการสำเร็จ' : 'เกิดข้อผิดพลาด');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            res.success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: res.success ? 3 : 5),
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

  // --- Dialog: Update Description ONLY (for status 1: ส่ง MT แล้ว) ---
  Future<void> _showUpdateDescriptionOnlyDialog(
      MtRequestViewModel vm, MtRequestHeader header) async {
    final controller = TextEditingController(text: header.description ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('แก้ไขรายละเอียดปัญหา'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ใบนี้ส่ง MT แล้ว สามารถแก้ไขได้เฉพาะรายละเอียดปัญหาเท่านั้น',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดปัญหา / อาการเสีย',
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

  // --- Reusable Debounced Live Search Dialog (EmployeeSearch / EquipmentSearch / DeviationSearch) ---
  Future<T?> _showMtSearchDialog<T>({
    required BuildContext parentContext,
    required String title,
    required String hintText,
    String? initialQuery,
    required Future<List<T>> Function(String query) onSearch,
    required Widget Function(T item) titleBuilder,
    Widget? Function(T item)? subtitleBuilder,
  }) async {
    final queryCtrl = TextEditingController(text: initialQuery ?? '');
    Timer? debounce;
    List<T> results = const [];
    bool loading = false;
    bool hasSearched = false;
    String? errorMsg;
    int searchSeq = 0;

    final selected = await showDialog<T>(
      context: parentContext,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> runSearch(String raw) async {
              final q = raw.trim();
              if (q.length < 2) {
                setDialogState(() {
                  loading = false;
                  errorMsg = null;
                  results = const [];
                  hasSearched = false;
                });
                return;
              }
              final mySeq = ++searchSeq;
              setDialogState(() {
                loading = true;
                errorMsg = null;
              });
              try {
                final items = await onSearch(q);
                if (!dialogCtx.mounted || mySeq != searchSeq) return;
                setDialogState(() {
                  results = items;
                  loading = false;
                  hasSearched = true;
                });
              } catch (e) {
                if (!dialogCtx.mounted || mySeq != searchSeq) return;
                setDialogState(() {
                  errorMsg = e.toString().replaceFirst('Exception: ', '');
                  results = const [];
                  loading = false;
                  hasSearched = true;
                });
              }
            }

            void onQueryChanged(String val) {
              debounce?.cancel();
              if (val.trim().length < 2) {
                setDialogState(() {
                  loading = false;
                  errorMsg = null;
                  results = const [];
                  hasSearched = false;
                });
                return;
              }
              debounce = Timer(
                const Duration(milliseconds: 350),
                () => runSearch(val),
              );
            }

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 500,
                height: 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: queryCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: hintText,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          tooltip: 'ค้นหา',
                          onPressed: () {
                            debounce?.cancel();
                            runSearch(queryCtrl.text);
                          },
                        ),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: onQueryChanged,
                      onSubmitted: (val) {
                        debounce?.cancel();
                        runSearch(val);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'พิมพ์อย่างน้อย 2 ตัวอักษรเพื่อค้นหาจากระบบ MT',
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMsg != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      errorMsg!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                )
                              : !hasSearched
                                  ? Center(
                                      child: Text(
                                        'กรุณาพิมพ์คำค้นหา (อย่างน้อย 2 ตัวอักษร)',
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                    )
                                  : results.isEmpty
                                      ? Center(
                                          child: Text(
                                            'ไม่พบข้อมูลที่ตรงกับ "${queryCtrl.text.trim()}"',
                                            style: TextStyle(
                                                color: Colors.grey.shade600),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: results.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final item = results[index];
                                            return ListTile(
                                              dense: true,
                                              title: titleBuilder(item),
                                              subtitle: subtitleBuilder != null
                                                  ? subtitleBuilder(item)
                                                  : null,
                                              onTap: () => Navigator.pop(
                                                  dialogCtx, item),
                                            );
                                          },
                                        ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('ปิด'),
                ),
              ],
            );
          },
        );
      },
    );

    debounce?.cancel();
    queryCtrl.dispose();
    return selected;
  }

  // --- Searchable Department Picker Dialog (Lookups.Table5: 81 departments, preserves leading zeros) ---
  Future<MtDepartmentLookup?> _showDepartmentPickerDialog({
    required BuildContext parentContext,
    required String title,
    required List<MtDepartmentLookup> departments,
    String? currentCode,
  }) async {
    final searchCtrl = TextEditingController();
    final selected = await showDialog<MtDepartmentLookup>(
      context: parentContext,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final q = searchCtrl.text.trim().toLowerCase();
            final filtered = departments.where((d) {
              if (q.isEmpty) return true;
              return d.code.toLowerCase().contains(q) ||
                  d.name.toLowerCase().contains(q) ||
                  (d.description ?? '').toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 460,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'ค้นหารหัส, ชื่อย่อ หรือชื่อหน่วยงาน...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'ไม่พบหน่วยงานที่ค้นหา',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final d = filtered[index];
                                final isCur = currentCode != null &&
                                    d.code == currentCode.trim();
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    '${d.code} · ${d.name}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: d.description != null &&
                                          d.description!.isNotEmpty
                                      ? Text(d.description!)
                                      : null,
                                  trailing: isCur
                                      ? Icon(Icons.check_circle,
                                          color: Colors.blue.shade900, size: 20)
                                      : null,
                                  onTap: () => Navigator.pop(dialogCtx, d),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('ปิด'),
                ),
              ],
            );
          },
        );
      },
    );
    searchCtrl.dispose();
    return selected;
  }

  // --- Dialog: Full MT Request Form (Draft status 0: all 16 fields from Section 3.8 + MT Lookups & Search) ---
  Future<void> _showEditMtFormDialog(
      MtRequestViewModel vm, MtRequestHeader header) async {
    await vm.ensureLookupsLoaded();
    if (!mounted) return;

    final lookups = vm.lookups;
    final statusEquiLookups = lookups?.statusEquiTypes.isNotEmpty == true
        ? lookups!.statusEquiTypes
        : const [
            MtRequestStatusLookup(id: 0, name: 'Break Down เครื่องเสีย'),
            MtRequestStatusLookup(id: 1, name: 'Near Fail เครื่องใกล้เสีย'),
          ];
    final planImpactLookups = lookups?.planImpacts.isNotEmpty == true
        ? lookups!.planImpacts
        : const [
            MtRequestStatusLookup(id: 0, name: 'ไม่กระทบแผนผลิต'),
            MtRequestStatusLookup(id: 1, name: 'กระทบแผนผลิต'),
          ];
    final jobTypeLookups =
        lookups?.requestJobTypes ?? const <MtRequestJobTypeLookup>[];
    final departmentLookups =
        lookups?.departments ?? const <MtDepartmentLookup>[];
    final qualityTypeLookups =
        lookups?.qualityIssueTypes ?? const <MtQualityIssueTypeLookup>[];

    final descCtrl = TextEditingController(text: header.description ?? '');
    final reqNameCtrl = TextEditingController(text: header.requesterName ?? '');
    final reqDeptCtrl =
        TextEditingController(text: header.requesterDepartmentCode ?? '');
    final reqTelCtrl = TextEditingController(text: header.requesterTel ?? '');
    final reqEmailCtrl =
        TextEditingController(text: header.requesterEmail ?? '');
    final jobTypeCtrl =
        TextEditingController(text: header.requestJobType?.toString() ?? '');
    final eqDeptCtrl =
        TextEditingController(text: header.equipmentDepartmentCode ?? '');
    final eqIdCtrl = TextEditingController(text: header.equipmentId ?? '');
    final eqLocCtrl =
        TextEditingController(text: header.equipmentLocation ?? '');
    final qiTypeCtrl =
        TextEditingController(text: header.qualityIssueType?.toString() ?? '');
    final qiNoCtrl = TextEditingController(text: header.qualityIssueNo ?? '');
    final onsiteNameCtrl = TextEditingController(text: header.onsiteName ?? '');
    final onsiteTelCtrl = TextEditingController(text: header.onsiteTel ?? '');

    int? statusEquiType = header.statusEquiType;
    int? planImpact = header.planImpact;
    int? requestJobType = header.requestJobType;
    int? qualityIssueType = header.qualityIssueType;
    String? reqDeptCode = header.requesterDepartmentCode;
    String? reqDeptDisplay = header.requesterDepartmentName;
    String? eqDeptCode = header.equipmentDepartmentCode;
    String? eqDeptDisplay = header.equipmentDepartmentName;
    String? selectedEquipmentName = header.equipmentName;
    DateTime? problemDate = header.problemDate != null
        ? DateTime.tryParse(header.problemDate!)
        : null;

    String deptLabelFor(String? code, String? fallbackName) {
      if (code == null || code.trim().isEmpty) return '';
      final trimmed = code.trim();
      for (final d in departmentLookups) {
        if (d.code == trimmed) return d.displayLabel;
      }
      if (fallbackName != null && fallbackName.isNotEmpty) {
        return '$trimmed · $fallbackName';
      }
      return trimmed;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickProblemDateTime() async {
              final initial = problemDate ?? DateTime.now();
              final pickedDate = await showDatePicker(
                context: dialogCtx,
                initialDate: initial,
                firstDate: DateTime(2024),
                lastDate: DateTime(2100),
              );
              if (pickedDate == null || !dialogCtx.mounted) return;
              final pickedTime = await showTimePicker(
                context: dialogCtx,
                initialTime: TimeOfDay.fromDateTime(initial),
              );
              if (!dialogCtx.mounted) return;
              final time = pickedTime ?? TimeOfDay.fromDateTime(initial);
              setDialogState(() {
                problemDate = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            Future<void> searchRequester() async {
              final emp = await _showMtSearchDialog<MtEmployeeSearchItem>(
                parentContext: dialogCtx,
                title: 'ค้นหาพนักงาน (ผู้แจ้ง)',
                hintText: 'รหัสพนักงาน, ชื่อ หรือ AD user...',
                onSearch: (q) => vm.searchEmployees(q),
                titleBuilder: (e) => Text(
                  '${e.employeeName} (${e.employeeId})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitleBuilder: (e) => Text(
                  [
                    if (e.departmentCode != null || e.departmentName != null)
                      '${e.departmentCode ?? ''} ${e.departmentName ?? ''}'
                          .trim(),
                    if (e.positionName != null && e.positionName!.isNotEmpty)
                      e.positionName!,
                    if (e.email != null && e.email!.isNotEmpty) e.email!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
              if (emp == null || !dialogCtx.mounted) return;
              setDialogState(() {
                reqNameCtrl.text = emp.employeeName;
                if (emp.departmentCode != null &&
                    emp.departmentCode!.isNotEmpty) {
                  reqDeptCode = emp.departmentCode!;
                  reqDeptCtrl.text = emp.departmentCode!;
                  reqDeptDisplay = emp.departmentName;
                }
                if (emp.email != null && emp.email!.isNotEmpty) {
                  reqEmailCtrl.text = emp.email!;
                }
              });
            }

            Future<void> searchOnsite() async {
              final emp = await _showMtSearchDialog<MtEmployeeSearchItem>(
                parentContext: dialogCtx,
                title: 'ค้นหาผู้ติดต่อหน้างาน',
                hintText: 'รหัสพนักงาน, ชื่อ หรือ AD user...',
                onSearch: (q) => vm.searchEmployees(q),
                titleBuilder: (e) => Text(
                  '${e.employeeName} (${e.employeeId})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitleBuilder: (e) => Text(
                  [
                    if (e.departmentCode != null || e.departmentName != null)
                      '${e.departmentCode ?? ''} ${e.departmentName ?? ''}'
                          .trim(),
                    if (e.positionName != null && e.positionName!.isNotEmpty)
                      e.positionName!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
              if (emp == null || !dialogCtx.mounted) return;
              setDialogState(() {
                onsiteNameCtrl.text = emp.employeeName;
              });
            }

            Future<void> searchEquipment() async {
              final eq = await _showMtSearchDialog<MtEquipmentSearchItem>(
                parentContext: dialogCtx,
                title: 'ค้นหาเครื่องจักร / อุปกรณ์ (MT)',
                hintText: 'รหัสเครื่อง, ชื่อเครื่อง หรือเลขทรัพย์สิน...',
                onSearch: (q) => vm.searchEquipment(q),
                titleBuilder: (e) => Text(
                  '${e.equipmentId} · ${e.equipmentName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitleBuilder: (e) {
                  final parts = <String>[
                    if (e.equipmentName2 != null &&
                        e.equipmentName2!.isNotEmpty)
                      e.equipmentName2!,
                    if (e.model != null && e.model!.isNotEmpty)
                      'Model: ${e.model}',
                    if (e.assetNo != null && e.assetNo!.isNotEmpty)
                      'Asset: ${e.assetNo}',
                    if (e.serialNo != null && e.serialNo!.isNotEmpty)
                      'S/N: ${e.serialNo}',
                  ];
                  return parts.isEmpty
                      ? null
                      : Text(
                          parts.join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                },
              );
              if (eq == null || !dialogCtx.mounted) return;
              setDialogState(() {
                eqIdCtrl.text = eq.equipmentId;
                selectedEquipmentName = eq.equipmentName;
              });
            }

            Future<void> searchDeviation() async {
              final dev = await _showMtSearchDialog<MtDeviationSearchItem>(
                parentContext: dialogCtx,
                title: 'ค้นหาเลข DV / NC / CAPA',
                hintText: 'เลขเอกสาร หรือหัวข้อ (เช่น DV2611)...',
                onSearch: (q) => vm.searchDeviations(
                  q,
                  systemId: qualityIssueType,
                ),
                titleBuilder: (d) => Text(
                  '${d.deviationNo}${d.systemName != null ? ' (${d.systemName})' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitleBuilder: (d) => Text(
                  [
                    if (d.heading != null && d.heading!.isNotEmpty) d.heading!,
                    if (d.ownerDepartment != null &&
                        d.ownerDepartment!.isNotEmpty)
                      d.ownerDepartment!,
                    if (d.statusName != null && d.statusName!.isNotEmpty)
                      d.statusName!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
              if (dev == null || !dialogCtx.mounted) return;
              setDialogState(() {
                qiNoCtrl.text = dev.deviationNo;
                if (qualityIssueType == null && dev.systemId != null) {
                  qualityIssueType = dev.systemId;
                  qiTypeCtrl.text = dev.systemId.toString();
                }
              });
            }

            // Build Dropdown items safely (keep unknown existing value if not in lookup list)
            final jobTypeDropdownItems = <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('– เลือกประเภทงานซ่อม –'),
              ),
              ...jobTypeLookups.map(
                (e) => DropdownMenuItem<int?>(
                  value: e.id,
                  child: Text(e.displayLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (requestJobType != null &&
                  !jobTypeLookups.any((e) => e.id == requestJobType))
                DropdownMenuItem<int?>(
                  value: requestJobType,
                  child: Text(
                    header.requestJobTypeName != null
                        ? '${header.requestJobTypeName} (#$requestJobType)'
                        : 'รหัส $requestJobType',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ];

            final qualityTypeDropdownItems = <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('– ไม่มี –'),
              ),
              ...qualityTypeLookups.map(
                (e) => DropdownMenuItem<int?>(
                  value: e.id,
                  child: Text(e.displayLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (qualityIssueType != null &&
                  !qualityTypeLookups.any((e) => e.id == qualityIssueType))
                DropdownMenuItem<int?>(
                  value: qualityIssueType,
                  child: Text(
                    header.qualityIssueTypeName != null
                        ? '${header.qualityIssueTypeName} (#$qualityIssueType)'
                        : 'รหัส $qualityIssueType',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ];

            final reqDeptLabel = deptLabelFor(reqDeptCode, reqDeptDisplay);
            final eqDeptLabel = deptLabelFor(eqDeptCode, eqDeptDisplay);
            final effectiveQualityType = qualityTypeLookups.isNotEmpty
                ? qualityIssueType
                : int.tryParse(qiTypeCtrl.text.trim());

            return AlertDialog(
              title: const Text('กรอกข้อมูลใบแจ้งซ่อม MT'),
              content: SizedBox(
                width: 580,
                height: 540,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ช่องที่มีเครื่องหมาย * จำเป็นต้องกรอกให้ครบก่อนกด "ส่ง MT" (สามารถบันทึกร่างบางส่วนก่อนได้)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 12),

                      // Section 1: อาการเสียและผลกระทบ
                      _formSectionTitle('1. อาการเสียและผลกระทบ'),
                      TextField(
                        controller: descCtrl,
                        maxLength: 1000,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'รายละเอียดปัญหา / อาการเสีย *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        initialValue: statusEquiType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'สถานะเครื่องจักร *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('– เลือกสถานะเครื่องจักร –'),
                          ),
                          ...statusEquiLookups.map(
                            (e) => DropdownMenuItem<int?>(
                              value: e.id,
                              child:
                                  Text(e.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => statusEquiType = v),
                      ),
                      const SizedBox(height: 10),
                      // Problem DateTime (Thai local time, NO Z)
                      InkWell(
                        onTap: pickProblemDateTime,
                        borderRadius: BorderRadius.circular(6),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'วันเวลาที่เครื่องจักรเกิดปัญหา *',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: problemDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setDialogState(
                                        () => problemDate = null),
                                  )
                                : const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            problemDate != null
                                ? formatMtLocalDateTime(problemDate!)
                                    .replaceFirst('T', ' ')
                                : 'แตะเพื่อเลือกวันและเวลา',
                            style: TextStyle(
                              fontSize: 14,
                              color: problemDate != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        initialValue: planImpact,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'กระทบแผนผลิตหรือไม่ *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('– เลือกผลกระทบแผนผลิต –'),
                          ),
                          ...planImpactLookups.map(
                            (e) => DropdownMenuItem<int?>(
                              value: e.id,
                              child:
                                  Text(e.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setDialogState(() => planImpact = v),
                      ),

                      const SizedBox(height: 16),
                      // Section 2: ข้อมูลผู้แจ้ง (with EmployeeSearch auto-fill)
                      Row(
                        children: [
                          Expanded(
                              child: _formSectionTitle('2. ข้อมูลผู้แจ้ง')),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: searchRequester,
                            icon: const Icon(Icons.person_search, size: 17),
                            label: const Text('ค้นหาพนักงาน',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      TextField(
                        controller: reqNameCtrl,
                        maxLength: 150,
                        decoration: InputDecoration(
                          labelText: 'ชื่อผู้แจ้ง *',
                          hintText: 'ค้นหาจากระบบ MT หรือพิมพ์ชื่อ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, size: 20),
                            tooltip: 'ค้นหาพนักงาน (เติมชื่อ/หน่วยงาน/อีเมล)',
                            onPressed: searchRequester,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (departmentLookups.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            final picked = await _showDepartmentPickerDialog(
                              parentContext: dialogCtx,
                              title: 'เลือกหน่วยงานของผู้แจ้ง',
                              departments: departmentLookups,
                              currentCode: reqDeptCode,
                            );
                            if (picked == null || !dialogCtx.mounted) return;
                            setDialogState(() {
                              reqDeptCode = picked.code;
                              reqDeptCtrl.text = picked.code;
                              reqDeptDisplay = picked.name;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'หน่วยงานผู้แจ้ง *',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: reqDeptCode != null &&
                                      reqDeptCode!.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setDialogState(() {
                                        reqDeptCode = null;
                                        reqDeptCtrl.clear();
                                        reqDeptDisplay = null;
                                      }),
                                    )
                                  : const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              reqDeptLabel.isNotEmpty
                                  ? reqDeptLabel
                                  : 'แตะเพื่อเลือกหน่วยงาน',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: reqDeptLabel.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      else
                        TextField(
                          controller: reqDeptCtrl,
                          maxLength: 50,
                          decoration: const InputDecoration(
                            labelText: 'รหัสหน่วยงานผู้แจ้ง *',
                            hintText: 'เช่น 052',
                            border: OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: reqTelCtrl,
                              maxLength: 50,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'เบอร์โต๊ะผู้แจ้ง *',
                                border: OutlineInputBorder(),
                                isDense: true,
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: reqEmailCtrl,
                              maxLength: 150,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'อีเมลผู้แจ้ง *',
                                hintText: 'name@biolab.co.th',
                                border: OutlineInputBorder(),
                                isDense: true,
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Section 3: ข้อมูลเครื่องจักรและประเภทงาน MT
                      Row(
                        children: [
                          Expanded(
                            child: _formSectionTitle(
                                '3. เครื่องจักรและประเภทงาน MT'),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: searchEquipment,
                            icon: const Icon(Icons.precision_manufacturing,
                                size: 17),
                            label: const Text('ค้นหาเครื่องจักร',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      if (jobTypeLookups.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          initialValue: requestJobType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทงานซ่อม *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: jobTypeDropdownItems,
                          onChanged: (v) => setDialogState(() {
                            requestJobType = v;
                            jobTypeCtrl.text = v?.toString() ?? '';
                          }),
                        )
                      else
                        TextField(
                          controller: jobTypeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            labelText: 'ประเภทงานซ่อม (รหัสตัวเลข) *',
                            hintText: 'เช่น 2',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (departmentLookups.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            final picked = await _showDepartmentPickerDialog(
                              parentContext: dialogCtx,
                              title: 'เลือกหน่วยงานที่ตั้งเครื่องจักร',
                              departments: departmentLookups,
                              currentCode: eqDeptCode,
                            );
                            if (picked == null || !dialogCtx.mounted) return;
                            setDialogState(() {
                              eqDeptCode = picked.code;
                              eqDeptCtrl.text = picked.code;
                              eqDeptDisplay = picked.name;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'หน่วยงานที่ตั้งเครื่องจักร *',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: eqDeptCode != null &&
                                      eqDeptCode!.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setDialogState(() {
                                        eqDeptCode = null;
                                        eqDeptCtrl.clear();
                                        eqDeptDisplay = null;
                                      }),
                                    )
                                  : const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              eqDeptLabel.isNotEmpty
                                  ? eqDeptLabel
                                  : 'แตะเพื่อเลือกหน่วยงานที่ตั้งเครื่อง',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: eqDeptLabel.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      else
                        TextField(
                          controller: eqDeptCtrl,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'หน่วยงานที่ตั้งเครื่อง *',
                            hintText: '≤ 10 ตัวอักษร เช่น 052',
                            border: OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: eqIdCtrl,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: 'รหัสเครื่องจักร/อุปกรณ์ในระบบ MT *',
                          hintText: 'แตะไอคอนแว่นขยายเพื่อค้นหาจากระบบ MT',
                          helperText: selectedEquipmentName != null &&
                                  selectedEquipmentName!.isNotEmpty
                              ? 'ชื่อเครื่อง: $selectedEquipmentName'
                              : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, size: 20),
                            tooltip: 'ค้นหาเครื่องจักรในระบบ MT',
                            onPressed: searchEquipment,
                          ),
                        ),
                        onChanged: (_) {
                          if (selectedEquipmentName != null) {
                            setDialogState(() => selectedEquipmentName = null);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: eqLocCtrl,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'สถานที่ตั้งเครื่องจักร/อุปกรณ์ *',
                          hintText: 'เช่น อาคาร 1 ชั้น 2',
                          border: OutlineInputBorder(),
                          isDense: true,
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Section 4: ผู้ติดต่อหน้างาน (with EmployeeSearch)
                      Row(
                        children: [
                          Expanded(
                              child: _formSectionTitle('4. ผู้ติดต่อหน้างาน')),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: searchOnsite,
                            icon: const Icon(Icons.person_search, size: 17),
                            label: const Text('ค้นหาพนักงาน',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: onsiteNameCtrl,
                              maxLength: 150,
                              decoration: InputDecoration(
                                labelText: 'ชื่อผู้ติดต่อหน้างาน *',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search, size: 20),
                                  tooltip: 'ค้นหาพนักงาน',
                                  onPressed: searchOnsite,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: onsiteTelCtrl,
                              maxLength: 50,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'เบอร์โต๊ะหน้างาน *',
                                border: OutlineInputBorder(),
                                isDense: true,
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Section 5: ประเด็นคุณภาพ (Lookups.Table6 + DeviationSearch)
                      _formSectionTitle('5. ประเด็นคุณภาพ (ไม่บังคับ)'),
                      if (qualityTypeLookups.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          key: ValueKey('qi_type_$qualityIssueType'),
                          initialValue: qualityIssueType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'ประเภท DV / NC / CAPA',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: qualityTypeDropdownItems,
                          onChanged: (v) => setDialogState(() {
                            qualityIssueType = v;
                            qiTypeCtrl.text = v?.toString() ?? '';
                          }),
                        )
                      else
                        TextField(
                          controller: qiTypeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            labelText: 'ประเภท DV/NC/INC/CAPA',
                            hintText: 'รหัสตัวเลข (ถ้ามี)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qiNoCtrl,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: effectiveQualityType != null
                              ? 'เลข DV / NC / CAPA * (บังคับเมื่อเลือกประเภท)'
                              : 'เลข DV / NC / CAPA',
                          hintText: 'ค้นหาจากระบบ MT หรือพิมพ์เลขเอกสาร',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, size: 20),
                            tooltip: 'ค้นหาเลข DV / NC / CAPA',
                            onPressed: searchDeviation,
                          ),
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
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('บันทึกร่าง'),
                ),
              ],
            );
          },
        );
      },
    );

    final finalReqDept = departmentLookups.isNotEmpty
        ? (reqDeptCode?.trim().isEmpty ?? true ? null : reqDeptCode!.trim())
        : (reqDeptCtrl.text.trim().isEmpty ? null : reqDeptCtrl.text.trim());
    final finalEqDept = departmentLookups.isNotEmpty
        ? (eqDeptCode?.trim().isEmpty ?? true ? null : eqDeptCode!.trim())
        : (eqDeptCtrl.text.trim().isEmpty ? null : eqDeptCtrl.text.trim());
    final finalJobType = jobTypeLookups.isNotEmpty
        ? requestJobType
        : (jobTypeCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(jobTypeCtrl.text.trim()));
    final finalQualityType = qualityTypeLookups.isNotEmpty
        ? qualityIssueType
        : (qiTypeCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(qiTypeCtrl.text.trim()));

    final fields = <String, dynamic>{
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      'requesterName':
          reqNameCtrl.text.trim().isEmpty ? null : reqNameCtrl.text.trim(),
      'requesterDepartmentCode': finalReqDept,
      'requesterTel':
          reqTelCtrl.text.trim().isEmpty ? null : reqTelCtrl.text.trim(),
      'requesterEmail':
          reqEmailCtrl.text.trim().isEmpty ? null : reqEmailCtrl.text.trim(),
      'requestJobType': finalJobType,
      'equipmentDepartmentCode': finalEqDept,
      'equipmentId': eqIdCtrl.text.trim().isEmpty ? null : eqIdCtrl.text.trim(),
      'equipmentLocation':
          eqLocCtrl.text.trim().isEmpty ? null : eqLocCtrl.text.trim(),
      'statusEquiType': statusEquiType,
      'problemDate':
          problemDate == null ? null : formatMtLocalDateTime(problemDate!),
      'planImpact': planImpact,
      'qualityIssueType': finalQualityType,
      'qualityIssueNo':
          qiNoCtrl.text.trim().isEmpty ? null : qiNoCtrl.text.trim(),
      'onsiteName': onsiteNameCtrl.text.trim().isEmpty
          ? null
          : onsiteNameCtrl.text.trim(),
      'onsiteTel':
          onsiteTelCtrl.text.trim().isEmpty ? null : onsiteTelCtrl.text.trim(),
    };

    descCtrl.dispose();
    reqNameCtrl.dispose();
    reqDeptCtrl.dispose();
    reqTelCtrl.dispose();
    reqEmailCtrl.dispose();
    jobTypeCtrl.dispose();
    eqDeptCtrl.dispose();
    eqIdCtrl.dispose();
    eqLocCtrl.dispose();
    qiTypeCtrl.dispose();
    qiNoCtrl.dispose();
    onsiteNameCtrl.dispose();
    onsiteTelCtrl.dispose();

    if (confirmed != true || !mounted) return;

    final res = await vm.updateCurrentFields(fields);
    _showResultFeedback(res);
  }

  Widget _formSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  // --- Dialog: Send to MT (Draft -> Sent to MT) ---
  Future<void> _confirmSendToMt(
      MtRequestViewModel vm, MtRequestDetail detail) async {
    final h = detail.header;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันส่งใบแจ้งซ่อมเข้าระบบ MT'),
        content: Text(
          'ต้องการส่งใบร่าง #${h.id} (${detail.cases.length} เคส) เข้าระบบ MT ใช่หรือไม่?\n\n'
          'หลังส่งแล้วระบบจะออกเลข RequestNo ให้อัตโนมัติ และจะไม่สามารถเพิ่ม/ลบเคส หรือแก้ข้อมูลเครื่องจักรได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(Icons.send, size: 17),
            label: const Text('ส่งเข้า MT'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final res = await vm.sendCurrentRequest();
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

    final resultLookups =
        vm.lookups?.results ?? const <MtRequestResultLookup>[];
    if (resultLookups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('ไม่สามารถโหลดรายการผลปิดงาน (Lookups) ได้ กรุณาลองใหม่'),
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
        final h = detail.header;
        final hasMtRepairRef = (h.mtCorrectiveAction != null &&
                h.mtCorrectiveAction!.isNotEmpty) ||
            (h.mtCloseJobDescription != null &&
                h.mtCloseJobDescription!.isNotEmpty) ||
            (h.mtJobStatusName != null && h.mtJobStatusName!.isNotEmpty);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'ปิดงานใบแจ้งซ่อม ${detail.header.requestNo ?? '#${detail.header.id}'}',
              ),
              content: SizedBox(
                width: 520,
                height: 500,
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
                    if (hasMtRepairRef) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.engineering,
                                    size: 15, color: Colors.indigo.shade800),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'บันทึกจากช่าง MT (อ้างอิง)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                ),
                                if ((h.mtCorrectiveAction != null &&
                                        h.mtCorrectiveAction!.isNotEmpty) ||
                                    (h.mtCloseJobDescription != null &&
                                        h.mtCloseJobDescription!.isNotEmpty))
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      final parts = <String>[
                                        if (h.mtCorrectiveAction != null &&
                                            h.mtCorrectiveAction!.isNotEmpty)
                                          h.mtCorrectiveAction!,
                                        if (h.mtCloseJobDescription != null &&
                                            h.mtCloseJobDescription!.isNotEmpty)
                                          h.mtCloseJobDescription!,
                                      ];
                                      closeNoteController.text =
                                          parts.join(' / ');
                                    },
                                    child: const Text(
                                      'ใส่หมายเหตุปิดใบ',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                  ),
                              ],
                            ),
                            if (h.mtEngineerName != null &&
                                h.mtEngineerName!.isNotEmpty)
                              Text(
                                'ช่าง: ${h.mtEngineerName}'
                                '${h.mtJobStatusName != null && h.mtJobStatusName!.isNotEmpty ? ' · ${h.mtJobStatusName}' : ''}',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.indigo.shade900),
                              ),
                            if (h.mtCorrectiveAction != null &&
                                h.mtCorrectiveAction!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'การแก้ไข: ${h.mtCorrectiveAction}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (h.mtCloseJobDescription != null &&
                                h.mtCloseJobDescription!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'หมายเหตุปิดใบงาน: ${h.mtCloseJobDescription}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                        if (detail.header.isDraft) ...[
                          _buildReadinessBanner(vm, detail.header),
                          const SizedBox(height: 12),
                        ] else if (detail.header.isWaitingFieldClose) ...[
                          _buildMtEndedBanner(vm, detail),
                          const SizedBox(height: 12),
                        ],
                        _buildActionCard(vm, detail),
                        const SizedBox(height: 12),
                        if (!detail.header.isDraft ||
                            detail.header.hasMtTracking) ...[
                          _buildMtSystemStatusCard(detail.header),
                          const SizedBox(height: 12),
                        ],
                        _buildMtDetailsCard(vm, detail.header),
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
                                    : () =>
                                        _showAddCasesDialog(vm, detail.header),
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

  Widget _buildReadinessBanner(MtRequestViewModel vm, MtRequestHeader h) {
    if (h.readyToSend) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ข้อมูลใบแจ้งซ่อมครบถ้วนแล้ว พร้อมกด "ส่ง MT"',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.amber.shade900, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ข้อมูลยังไม่ครบก่อนส่ง MT',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed:
                    vm.isSubmitting ? null : () => _showEditMtFormDialog(vm, h),
                child: const Text('กรอกข้อมูล'),
              ),
            ],
          ),
          if (h.missingFields != null && h.missingFields!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'ยังขาด: ${h.missingFields}',
              style: TextStyle(
                  fontSize: 12.5, color: Colors.amber.shade900, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(MtRequestViewModel vm, MtRequestDetail detail) {
    final h = detail.header;
    final statusName =
        vm.lookups?.statusNameFor(h.status, fallback: h.statusName) ??
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
                        : 'ใบร่าง #${h.id} (รอส่งเข้าระบบ MT)',
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
              '${h.formName} · Job ${h.jobId}'
              '${h.mtRecId != null ? ' · MT Rec #${h.mtRecId}' : ''}',
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
                        'รายละเอียดปัญหา / อาการเสีย',
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
                if (h.isSentToMt)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'แก้ไขรายละเอียดปัญหา',
                    color: Colors.blue.shade800,
                    onPressed: vm.isSubmitting
                        ? null
                        : () => _showUpdateDescriptionOnlyDialog(vm, h),
                  ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _metaChip('สร้างใบ',
                    '${h.createUser ?? '-'} · ${_fmtDateTime(h.createDate)}'),
                if (h.sentDate != null)
                  _metaChip('ส่ง MT',
                      '${h.sentUser ?? '-'} · ${_fmtDateTime(h.sentDate)}'),
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
                  color:
                      h.isCancelled ? Colors.red.shade50 : Colors.green.shade50,
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
            if (h.isDraft) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    vm.isSubmitting ? null : () => _showEditMtFormDialog(vm, h),
                icon: const Icon(Icons.edit_note, size: 19),
                label: const Text('กรอก/แก้ข้อมูล MT'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
                onPressed: (!vm.isSubmitting && h.readyToSend)
                    ? () => _confirmSendToMt(vm, detail)
                    : null,
                icon: const Icon(Icons.send, size: 17),
                label: const Text('ส่ง MT'),
              ),
              OutlinedButton.icon(
                onPressed:
                    vm.isSubmitting ? null : () => _showAddCasesDialog(vm, h),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มเคส'),
              ),
            ] else if (h.isSentToMt) ...[
              OutlinedButton.icon(
                onPressed: vm.isSubmitting
                    ? null
                    : () => _showUpdateDescriptionOnlyDialog(vm, h),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('แก้รายละเอียดปัญหา'),
              ),
            ],
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

  Widget _buildMtEndedBanner(MtRequestViewModel vm, MtRequestDetail detail) {
    final h = detail.header;
    final isCancelled = h.isMtCancelled;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red.shade50 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCancelled ? Colors.red.shade300 : Colors.teal.shade400,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: isCancelled ? Colors.red.shade800 : Colors.teal.shade800,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCancelled
                      ? 'ระบบ MT ยกเลิกใบแจ้งซ่อมนี้แล้ว'
                      : 'ระบบ MT ดำเนินการจบงานแล้ว (รอหน้างานปิดงาน)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isCancelled
                        ? Colors.red.shade900
                        : Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCancelled
                      ? 'สถานะของ MT ไม่ปิด/ยกเลิกใบฝั่ง Check Sheet อัตโนมัติ กรุณาตรวจสอบและกด "ยกเลิกใบ" เพื่อให้เคสเปิดออกใบใหม่ได้'
                      : 'สถานะของ MT ไม่ปิดใบหรือเคสอัตโนมัติ กรุณาตรวจสอบผลการซ่อมด้านล่างแล้วกด "ปิดงาน" เพื่อระบุผลรายเคส',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCancelled
                        ? Colors.red.shade900
                        : Colors.teal.shade900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor:
                  isCancelled ? Colors.red.shade900 : Colors.teal.shade900,
            ),
            onPressed: vm.isSubmitting
                ? null
                : () => isCancelled
                    ? _showCancelRequestDialog(vm, h)
                    : _showCloseRequestDialog(vm, detail),
            child: Text(
              isCancelled ? 'ยกเลิกใบ' : 'ปิดงาน',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMtSystemStatusCard(MtRequestHeader h) {
    if (!h.hasMtTracking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 18, color: Colors.blueGrey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ยังไม่มีข้อมูลสถานะสดจากระบบ MT (อาจยังไม่มีข้อมูลในระบบ MT หรือยังเชื่อมต่อฐานข้อมูล MT ไม่ได้)',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800),
              ),
            ),
          ],
        ),
      );
    }

    final Color mtBg;
    final Color mtFg;
    if (h.mtStatus == 9) {
      mtBg = Colors.red.shade100;
      mtFg = Colors.red.shade900;
    } else if (h.mtStatus == 5 || h.mtStatus == 6) {
      mtBg = Colors.teal.shade100;
      mtFg = Colors.teal.shade900;
    } else if (h.mtStatus == 3) {
      mtBg = Colors.orange.shade100;
      mtFg = Colors.orange.shade900;
    } else {
      mtBg = Colors.indigo.shade100;
      mtFg = Colors.indigo.shade900;
    }

    final lastActionText = [
      if (h.mtLastAction != null && h.mtLastAction!.isNotEmpty) h.mtLastAction!,
      if (h.mtLastActionDate != null && h.mtLastActionDate!.isNotEmpty)
        _fmtDateTime(h.mtLastActionDate),
    ].join(' · ');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_alt, size: 19, color: Colors.indigo.shade800),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'สถานะจากระบบ MT (อ่านอย่างเดียว)',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
                if (h.mtStatusName != null && h.mtStatusName!.isNotEmpty)
                  _smallPill(h.mtStatusName!, mtBg, mtFg),
              ],
            ),
            const Divider(height: 16),
            if (h.mtStatusName != null && h.mtStatusName!.isNotEmpty)
              _infoPair('ขั้นตอนใบใน MT', h.mtStatusName!),
            if (lastActionText.isNotEmpty)
              _infoPair('การทำงานล่าสุด', lastActionText),
            if (h.mtCancelDate != null && h.mtCancelDate!.isNotEmpty)
              _infoPair('วันที่ MT ยกเลิก', _fmtDateTime(h.mtCancelDate)),
            if ((h.mtJobNo != null && h.mtJobNo!.isNotEmpty) ||
                (h.mtJobStatusName != null && h.mtJobStatusName!.isNotEmpty) ||
                (h.mtEngineerName != null && h.mtEngineerName!.isNotEmpty)) ...[
              const Divider(height: 16),
              _infoPair('เลขใบงานช่าง MT', _valOrDash(h.mtJobNo)),
              _infoPair('สถานะใบงานช่าง', _valOrDash(h.mtJobStatusName)),
              _infoPair('ช่างผู้รับผิดชอบ', _valOrDash(h.mtEngineerName)),
            ],
            if ((h.mtRepairDate != null && h.mtRepairDate!.isNotEmpty) ||
                (h.mtCloseJobDate != null && h.mtCloseJobDate!.isNotEmpty) ||
                (h.mtFinishDate != null && h.mtFinishDate!.isNotEmpty)) ...[
              const Divider(height: 16),
              if (h.mtRepairDate != null && h.mtRepairDate!.isNotEmpty)
                _infoPair('วันที่ซ่อม', _fmtDateTime(h.mtRepairDate)),
              if (h.mtCloseJobDate != null && h.mtCloseJobDate!.isNotEmpty)
                _infoPair('วันที่ปิดใบงาน', _fmtDateTime(h.mtCloseJobDate)),
              if (h.mtFinishDate != null && h.mtFinishDate!.isNotEmpty)
                _infoPair('วันที่จบงาน', _fmtDateTime(h.mtFinishDate)),
            ],
            if ((h.mtCorrectiveAction != null &&
                    h.mtCorrectiveAction!.isNotEmpty) ||
                (h.mtCloseJobDescription != null &&
                    h.mtCloseJobDescription!.isNotEmpty)) ...[
              const Divider(height: 16),
              if (h.mtCorrectiveAction != null &&
                  h.mtCorrectiveAction!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การแก้ไขที่ช่างบันทึก',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        h.mtCorrectiveAction!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (h.mtCloseJobDescription != null &&
                  h.mtCloseJobDescription!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'หมายเหตุปิดใบงานช่าง',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        h.mtCloseJobDescription!,
                        style: const TextStyle(fontSize: 13),
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

  Widget _buildMtDetailsCard(MtRequestViewModel vm, MtRequestHeader h) {
    final equiStatusName =
        (h.statusEquiTypeName != null && h.statusEquiTypeName!.isNotEmpty)
            ? h.statusEquiTypeName!
            : (vm.lookups?.statusEquiTypeNameFor(h.statusEquiType) ??
                _valOrDash(h.statusEquiType));
    final planImpactName =
        (h.planImpactName != null && h.planImpactName!.isNotEmpty)
            ? h.planImpactName!
            : (vm.lookups?.planImpactNameFor(h.planImpact) ??
                _valOrDash(h.planImpact));
    final jobTypeDisplay =
        (h.requestJobTypeName != null && h.requestJobTypeName!.isNotEmpty)
            ? h.requestJobTypeName!
            : (vm.lookups?.requestJobTypeNameFor(h.requestJobType) ??
                _valOrDash(h.requestJobType));
    final reqDeptDisplay = (h.requesterDepartmentCode != null &&
            h.requesterDepartmentCode!.isNotEmpty)
        ? (h.requesterDepartmentName != null &&
                h.requesterDepartmentName!.isNotEmpty
            ? '${h.requesterDepartmentCode} · ${h.requesterDepartmentName}'
            : (vm.lookups?.departmentDisplayFor(h.requesterDepartmentCode) ??
                h.requesterDepartmentCode!))
        : '–';
    final eqDeptDisplay = (h.equipmentDepartmentCode != null &&
            h.equipmentDepartmentCode!.isNotEmpty)
        ? (h.equipmentDepartmentName != null &&
                h.equipmentDepartmentName!.isNotEmpty
            ? '${h.equipmentDepartmentCode} · ${h.equipmentDepartmentName}'
            : (vm.lookups?.departmentDisplayFor(h.equipmentDepartmentCode) ??
                h.equipmentDepartmentCode!))
        : '–';
    final eqDisplay = (h.equipmentId != null && h.equipmentId!.isNotEmpty)
        ? (h.equipmentName != null && h.equipmentName!.isNotEmpty
            ? '${h.equipmentId} · ${h.equipmentName}'
            : h.equipmentId!)
        : '–';
    final qualityTypeDisplay =
        (h.qualityIssueTypeName != null && h.qualityIssueTypeName!.isNotEmpty)
            ? h.qualityIssueTypeName!
            : (vm.lookups?.qualityIssueTypeNameFor(h.qualityIssueType) ??
                _valOrDash(h.qualityIssueType));

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.engineering_outlined,
                    size: 19, color: Colors.blue.shade900),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'ข้อมูลใบแจ้งซ่อมสำหรับระบบ MT',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
                if (h.isDraft)
                  TextButton.icon(
                    onPressed: vm.isSubmitting
                        ? null
                        : () => _showEditMtFormDialog(vm, h),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('แก้ไข'),
                  ),
              ],
            ),
            const Divider(height: 16),
            _infoPair('สถานะเครื่องจักร', equiStatusName),
            _infoPair('วันเวลาเกิดปัญหา', _fmtDateTime(h.problemDate)),
            _infoPair('ผลกระทบแผนผลิต', planImpactName),
            const Divider(height: 16),
            _infoPair('ผู้แจ้ง', _valOrDash(h.requesterName)),
            _infoPair('หน่วยงานผู้แจ้ง', reqDeptDisplay),
            _infoPair('เบอร์โต๊ะผู้แจ้ง', _valOrDash(h.requesterTel)),
            _infoPair('อีเมลผู้แจ้ง', _valOrDash(h.requesterEmail)),
            const Divider(height: 16),
            _infoPair('ประเภทงานซ่อม', jobTypeDisplay),
            _infoPair('หน่วยงานที่ตั้งเครื่อง', eqDeptDisplay),
            _infoPair('เครื่องจักร (MT)', eqDisplay),
            _infoPair('สถานที่ตั้งเครื่อง', _valOrDash(h.equipmentLocation)),
            const Divider(height: 16),
            _infoPair('ผู้ติดต่อหน้างาน', _valOrDash(h.onsiteName)),
            _infoPair('เบอร์โต๊ะหน้างาน', _valOrDash(h.onsiteTel)),
            if (h.qualityIssueType != null ||
                (h.qualityIssueNo != null && h.qualityIssueNo!.isNotEmpty)) ...[
              const Divider(height: 16),
              _infoPair('ประเภท DV/NC/CAPA', qualityTypeDisplay),
              _infoPair('เลข DV/NC/CAPA', _valOrDash(h.qualityIssueNo)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    final isMissing = value == '–';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isMissing ? FontWeight.normal : FontWeight.w500,
                color: isMissing ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ),
        ],
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
                    color:
                        canRemove ? Colors.red.shade600 : Colors.grey.shade400,
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
