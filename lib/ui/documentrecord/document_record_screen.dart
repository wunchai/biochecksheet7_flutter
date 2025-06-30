// lib/ui/documentrecord/document_record_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart'; // For DocumentRecordWithTagAndProblem
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag (to get tagType etc.)
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem (if problem tag type exists)
// NEW: Import the new input field widgets
import 'package:biochecksheet7_flutter/ui/documentrecord/inputs/record_text_input.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/inputs/record_number_input.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/inputs/record_combobox_input.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/inputs/record_problem_input.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/record_detail_dialog.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/remark_input_dialog.dart'; // <<< Changed from remark_input_dialog.dart to widgets/remark_input_dialog.dart
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/record_line_chart.dart'; // For chart widget
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/document_record_app_bar.dart'; // For custom AppBar

/// หน้าจอนี้แสดงรายการบันทึกสำหรับเอกสารและเครื่องจักรที่ระบุ
/// เทียบเท่ากับ DocumentRecordActivity.kt ในโปรเจกต์ Kotlin เดิม
class DocumentRecordScreen extends StatefulWidget {
  final String title; // ชื่อหน้าจอที่จะแสดงใน AppBar
  final String documentId; // รหัสเอกสารที่จะแสดงบันทึก
  final String machineId; // รหัสเครื่องจักรที่เกี่ยวข้องกับบันทึก
  final String jobId; // รหัส Job ที่จำเป็น

  const DocumentRecordScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
    required this.jobId,
  });

  @override
  State<DocumentRecordScreen> createState() => _DocumentRecordScreenState();
}

class _DocumentRecordScreenState extends State<DocumentRecordScreen> {
  // Map เพื่อเก็บ TextEditingController สำหรับแต่ละ Record (ใช้ uid เป็น key)
  final Map<int, TextEditingController> _controllers = {};
  // Map เพื่อเก็บค่าที่เลือกสำหรับ ComboBox (และ CheckBox)
  final Map<int, String?> _selectedComboBoxValues = {};
  final TextEditingController _searchController =
      TextEditingController(); // Controller สำหรับ Search Bar

  @override
  void initState() {
    super.initState();
    // เรียกโหลดบันทึกเมื่อหน้าจอเริ่มต้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentRecordViewModel>(context, listen: false)
          .loadRecords(widget.documentId, widget.machineId, widget.jobId);
    });

    // ฟังการเปลี่ยนแปลงของ Search Controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controllers.forEach(
        (key, controller) => controller.dispose()); // Dispose all controllers
    _searchController.dispose(); // Dispose search controller
    super.dispose();
  }

  // Helper method to get/create and update the TextEditingController for text-based inputs.
  // This method ensures that controllers are managed centrally and updated correctly.
  TextEditingController _getOrCreateAndSyncController(int uid, String? value) {
    final controller =
        _controllers.putIfAbsent(uid, () => TextEditingController());
    // Only update text if it's different to prevent endless rebuilds/cursor jump
    // and ensure cursor stays at the end when updated programmatically.
    if (controller.text != (value ?? '')) {
      controller.text = value ?? '';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }
    return controller;
  }

  void _onSearchChanged() {
    //Provider.of<DocumentRecordViewModel>(context, listen: false).setSearchQuery(_searchController.text);
  }

  // แสดง Dialog สำหรับรายละเอียดบันทึก
  void _showRecordDetailsDialog(
      BuildContext context, DocumentRecordWithTagAndProblem recordWithTag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RecordDetailDialog(recordWithTag: recordWithTag);
      },
    );
  }

  // แสดง Dialog สำหรับป้อนหมายเหตุ
  // CORRECTED: Show dialog for Remark input
  Future<void> _showRemarkInputDialog(BuildContext context,
      DbDocumentRecord record, DocumentRecordViewModel viewModel) async {
    // Create the controller here, managed by this State.
    final TextEditingController remarkController =
        _getOrCreateAndSyncController(record.uid, record.remark);

    final String? resultRemark = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เพิ่ม/แก้ไขหมายเหตุ'),
          // Pass the controller to the RemarkInputDialogContent
          content: RemarkInputDialogContent(
            // <<< Use RemarkInputDialogContent
            controller: remarkController, // <<< Pass controller directly
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null if cancelled
              },
            ),
            TextButton(
              child: const Text('บันทึก'),
              onPressed: () {
                final String newRemarkValue = remarkController.text;
                Navigator.of(context)
                    .pop(newRemarkValue); // Return the new remark value
              },
            ),
          ],
        );
      },
    );
print('Result Remark: $resultRemark');

    // ถ้า resultRemark ไม่เป็น null แสดงว่าได้ป้อนหมายเหตุใหม่
    if (resultRemark != null && resultRemark.isNotEmpty) {
      // รอให้ dialog ปิดเสร็จแน่ ๆ ก่อน แล้วรัน async action
      Future.microtask(() async {
        await Future.delayed(
            const Duration(milliseconds: 300)); // เพิ่ม buffer เล็กน้อย
        await viewModel.updateRecordValue(
          record.uid,
          record.value,
          resultRemark,
          newStatus: 0, // สถานะใหม่เป็น 0 (ถ้าต้องการ)
        );
      });
    }

  }

  // แสดง Dialog สำหรับกราฟ Local
  void _showChartDialog(BuildContext context, String tagId, DbJobTag? jobTag,
      DocumentRecordViewModel viewModel) {
    viewModel.loadChartData(tagId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text('กราฟ: ${jobTag?.tagName ?? 'N/A'} (${jobTag?.unit ?? ''})'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.4,
            child: RecordLineChart(
              chartDataStream: viewModel.chartDataStream!,
              jobTag: jobTag,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // แสดง Dialog สำหรับกราฟ Online
  void _showOnlineChartDialog(BuildContext context, String tagId,
      DbJobTag? jobTag, DocumentRecordViewModel viewModel) {
    viewModel.loadOnlineChartData(tagId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'กราฟประวัติ: ${jobTag?.tagName ?? 'N/A'} (${jobTag?.unit ?? ''})'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.4,
            child: RecordLineChart(
              chartDataStream: viewModel.onlineChartDataStream!,
              jobTag: jobTag,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ DocumentRecordAppBar ที่สร้างขึ้นมา
      appBar: DocumentRecordAppBar(
        title: widget.title,
        searchController: _searchController,
        onRefreshPressed: () {
          Provider.of<DocumentRecordViewModel>(context, listen: false)
              .refreshRecords();
        },
        onSavePressed: () {
          final viewModel =
              Provider.of<DocumentRecordViewModel>(context, listen: false);
          viewModel.saveAllChanges(
            allControllers: _controllers,
            allComboBoxValues: _selectedComboBoxValues,
          );
        },
      ),
      body: Consumer<DocumentRecordViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.syncMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.syncMessage!)),
              );
              viewModel.syncMessage = null;
            });
          }

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      viewModel.statusMessage,
                      style: const TextStyle(fontSize: 12.0, color: Colors.black), // ตัวอย่าง: ขนาด 16.0 สีดำ
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<DocumentRecordWithTagAndProblem>>(
                      stream: viewModel.recordsStream,
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text(
                                  'ไม่พบบันทึกสำหรับเอกสารและเครื่องจักรนี้.'));
                        } else {
                          final records = snapshot.data!;
                          return ListView.builder(
                            itemCount: records.length,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            itemBuilder: (context, index) {
                              final recordWithTag = records[index];
                              final DbDocumentRecord record =
                                  recordWithTag.documentRecord;
                              final DbJobTag? jobTag = recordWithTag.jobTag;
                              final DbProblem? problem = null;
                              // Determine if input fields should be read-only (if status is 2)
                              final bool isRecordReadOnly = record.status == 2;

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 4.0,
                                child: InkWell(
                                  onTap: () {
                                    _showRecordDetailsDialog(
                                        context, recordWithTag);
                                  },
                                  onLongPress: () {
                                    _showRecordDetailsDialog(
                                        context, recordWithTag);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                jobTag?.tagName ?? 'N/A',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ),
                                            // Local Chart Button (only for Number type tags)
                                            if (jobTag?.tagType == 'Number')
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.show_chart),
                                                onPressed: () {
                                                  _showChartDialog(
                                                      context,
                                                      record.tagId ?? '',
                                                      jobTag,
                                                      viewModel);
                                                },
                                              ),
                                            // Online Chart Button (only for Number type tags)
                                            if (jobTag?.tagType == 'Number')
                                              IconButton(
                                                icon: const Icon(Icons
                                                    .history), // Example icon for history
                                                onPressed: () {
                                                  _showOnlineChartDialog(
                                                      context,
                                                      record.tagId ?? '',
                                                      jobTag,
                                                      viewModel);
                                                },
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8.0),

                                        _buildInputField(context, record,
                                            jobTag, problem, viewModel,
                                            isRecordReadOnly: isRecordReadOnly),

                                        if (record.value != null &&
                                            record.value!.isNotEmpty)
                                          Text('ค่าปัจจุบัน: ${record.value}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),

                                        // Button for Remark (only if not read-only)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: isRecordReadOnly
                                                ? null
                                                : () => _showRemarkInputDialog(
                                                    context, record, viewModel),
                                            child: Text(
                                              record.remark != null &&
                                                      record.remark!.isNotEmpty
                                                  ? 'แก้ไขหมายเหตุ'
                                                  : 'เพิ่มหมายเหตุ',
                                            ),
                                          ),
                                        ),
                                        // Optional: Display current remark if it exists (for quick glance)
                                        if (record.remark != null &&
                                            record.remark!.isNotEmpty)
                                          Text('หมายเหตุ: ${record.remark}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        // Display record status
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text('สถานะ: ${record.status}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Helper method to build dynamic input fields based on tagType ---
  Widget _buildInputField(BuildContext context, DbDocumentRecord record,
      DbJobTag? jobTag, DbProblem? problem, DocumentRecordViewModel viewModel,
      {String? errorText, required bool isRecordReadOnly}) {
    final String tagType = jobTag?.tagType ?? '';

    // Get/create the controller for this record
    final TextEditingController controller =
        _getOrCreateAndSyncController(record.uid, record.value);
    // Ensure controller text is always updated to reflect the latest record.value from DB Stream
    if (controller.text != record.value) {
      controller.text = record.value ?? '';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }

    switch (tagType) {
      case 'Number':
        return RecordNumberInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
      case 'ComboBox':
        return RecordComboBoxInputField(
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
        return RecordTextInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isMultiline: false,
          isReadOnly: isRecordReadOnly,
        );
      case 'Message':
        return RecordTextInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          isMultiline: true,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
      case 'Problem':
        return RecordProblemInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          problem: problem,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
      case 'CheckBox':
        return RecordComboBoxInputField(
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
      default:
        return RecordTextInputField(
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
