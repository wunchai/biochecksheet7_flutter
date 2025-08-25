// lib/ui/amchecksheet/am_checksheet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ViewModel และ Models ที่จำเป็น
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';

// --- แก้ไข Import ให้เรียกใช้ Widgets และ Inputs ชุดใหม่ ---
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/widgets/am_document_record_app_bar.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_text_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_number_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_combobox_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_problem_input.dart';

class AMChecksheetScreen extends StatefulWidget {
  final String title;
  final String documentId;
  final String machineId;
  final String jobId;

  const AMChecksheetScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
    required this.jobId,
  });

  @override
  State<AMChecksheetScreen> createState() => _AMChecksheetScreenState();
}

class _AMChecksheetScreenState extends State<AMChecksheetScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String?> _selectedComboBoxValues = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AMChecksheetViewModel>(context, listen: false)
          .loadRecords(widget.documentId, widget.machineId, widget.jobId);
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _searchController.dispose();
    super.dispose();
  }

  TextEditingController _getOrCreateAndSyncController(int uid, String? value) {
    final controller =
        _controllers.putIfAbsent(uid, () => TextEditingController());
    if (controller.text != (value ?? '')) {
      controller.text = value ?? '';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }
    return controller;
  }

  void _showFullScreenImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีรูปภาพสำหรับรายการนี้')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red, size: 48);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AMChecksheetViewModel>(
      builder: (context, viewModel, child) {
        // แสดง SnackBar เมื่อมีข้อความ syncMessage
        if (viewModel.syncMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.syncMessage!)),
            );
            viewModel.syncMessage = null; // เคลียร์ข้อความหลังแสดงผล
          });
        }

        return Scaffold(
          // --- แก้ไข AppBar ให้เรียกใช้ Widget ใหม่ ---
          appBar: AmDocumentRecordAppBar(
            title: widget.title,
            searchController: _searchController,
            onRefreshPressed: () {
              // ยังไม่มีฟังก์ชัน refresh ใน ViewModel ตัวนี้
            },
            onSavePressed: () {
              viewModel.saveAllChanges(
                allControllers: _controllers,
                allComboBoxValues: _selectedComboBoxValues,
              );
            },
          ),
          body: Stack(
            children: [
              StreamBuilder<List<DocumentRecordWithTagAndProblem>>(
                stream: viewModel.recordsStream,
                builder: (context, snapshot) {
                  if (viewModel.isLoading && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('ไม่พบรายการตรวจเช็ค'));
                  }

                  final records = snapshot.data!;

                  return Column(
                    children: [
                      // Status Message
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(viewModel.statusMessage,
                            textAlign: TextAlign.center),
                      ),
                      // PageView
                      Expanded(
                        child: PageView.builder(
                          controller: viewModel.pageController,
                          itemCount: records.length,
                          onPageChanged: viewModel.onPageChanged,
                          itemBuilder: (context, index) {
                            final recordWithTag = records[index];
                            return _buildChecksheetPage(context, recordWithTag);
                          },
                        ),
                      ),
                      // Navigation Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: viewModel.currentPage > 0
                                  ? viewModel.navigateToPreviousPage
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('ย้อนกลับ'),
                            ),
                            if (records.isNotEmpty)
                              Text(
                                '${viewModel.currentPage + 1} / ${records.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ElevatedButton.icon(
                              onPressed:
                                  viewModel.currentPage < records.length - 1
                                      ? viewModel.navigateToNextPage
                                      : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('ถัดไป'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Loading Overlay
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecksheetPage(
      BuildContext context, DocumentRecordWithTagAndProblem recordWithTag) {
    final viewModel =
        Provider.of<AMChecksheetViewModel>(context, listen: false);
    final DbDocumentRecord record = recordWithTag.documentRecord;
    final DbJobTag? jobTag = recordWithTag.jobTag;
    final bool isRecordReadOnly = record.status == 2;

    // TODO: ดึง URL รูปภาพจริง
    final String? imageUrl =
        "https://placehold.co/600x400/EEE/31343C?text=Inspection\\nPoint";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(Icons.image_not_supported,
                              size: 60, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text('ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(color: Colors.grey[700])),
                        ]));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            jobTag?.tagName ?? 'N/A',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'หน่วย: ${jobTag?.unit ?? '-'} | มาตรฐาน: ${jobTag?.unit ?? '-'}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildInputField(
            context,
            record,
            jobTag,
            null, // problem
            viewModel,
            isRecordReadOnly: isRecordReadOnly,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    DbDocumentRecord record,
    DbJobTag? jobTag,
    DbProblem? problem,
    AMChecksheetViewModel viewModel, {
    String? errorText,
    required bool isRecordReadOnly,
  }) {
    final String tagType = jobTag?.tagType ?? '';
    final TextEditingController controller =
        _getOrCreateAndSyncController(record.uid, record.value);

    if (controller.text != record.value) {
      controller.text = record.value ?? '';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }

    switch (tagType) {
      case 'Number':
        return AmRecordNumberInputField(
          // <<< แก้ไข
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
      case 'ComboBox':
      case 'CheckBox':
        return AmRecordComboBoxInputField(
          // <<< แก้ไข
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          initialSelectedValue: _selectedComboBoxValues.putIfAbsent(
              record.uid, () => record.value),
          errorText: viewModel.recordErrors[record.uid],
          onChangedCallback: (newValue) {
            setState(() {
              _selectedComboBoxValues[record.uid] = newValue;
            });
          },
          isReadOnly: isRecordReadOnly,
        );
      case 'Text':
      case 'Message':
        return AmRecordTextInputField(
          // <<< แก้ไข
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isMultiline: tagType == 'Message',
          isReadOnly: isRecordReadOnly,
        );
      case 'Problem':
        return AmRecordProblemInputField(
          // <<< แก้ไข
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          problem: problem,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
      default:
        return AmRecordTextInputField(
          // <<< แก้ไข
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
    }
  }
}
