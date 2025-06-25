// lib/ui/documentrecord/documimport 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJobent_record_screen.dart
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
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/record_detail_dialog.dart'; // <<< เพิ่ม import นี้

/// หน้าจอนี้แสดงรายการบันทึกสำหรับเอกสารและเครื่องจักรที่ระบุ
/// เทียบเท่ากับ DocumentRecordActivity.kt ในโปรเจกต์ Kotlin เดิม
class DocumentRecordScreen extends StatefulWidget {
  final String title; // ชื่อหน้าจอที่จะแสดงใน AppBar
  final String documentId; // รหัสเอกสารที่จะแสดงบันทึก
  final String machineId; // รหัสเครื่องจักรที่เกี่ยวข้องกับบันทึก
   final String jobId; // NEW: Required jobId to initialize records

  const DocumentRecordScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
    required this.jobId, // <<< เพิ่ม parameter นี้
  });

  @override
  State<DocumentRecordScreen> createState() => _DocumentRecordScreenState();
}

class _DocumentRecordScreenState extends State<DocumentRecordScreen> {
  // Map เพื่อเก็บ TextEditingController สำหรับแต่ละ Record (ใช้ uid เป็น key)
  final Map<int, TextEditingController> _controllers = {};
  // Map เพื่อเก็บค่าที่เลือกสำหรับ ComboBox
  final Map<int, String?> _selectedComboBoxValues = {};


  @override
  void initState() {
    super.initState();
    
    // เรียกโหลดบันทึกเมื่อหน้าจอเริ่มต้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentRecordViewModel>(context, listen: false)
          .loadRecords(widget.documentId, widget.machineId, widget.jobId);
    });
  }

  @override
  void dispose() {
    // Dispose controllers ทั้งหมดเมื่อหน้าจอถูกปิด
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

// NEW: Method to show the Record Details Dialog
  void _showRecordDetailsDialog(BuildContext context, DocumentRecordWithTagAndProblem recordWithTag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RecordDetailDialog(recordWithTag: recordWithTag);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // แสดงชื่อหน้าจอ
        actions: [
          // ปุ่ม Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DocumentRecordViewModel>(context, listen: false)
                  .refreshRecords(); // เรียก refresh ใน ViewModel
            },
          ),
          // ปุ่ม Save/Upload สำหรับบันทึกการเปลี่ยนแปลงทั้งหมด (TODO)
          IconButton(
            icon: const Icon(Icons.save), // ไอคอนบันทึก
            onPressed: () {
              // TODO: เรียกใช้ฟังก์ชันบันทึกการเปลี่ยนแปลงทั้งหมดใน ViewModel
              print('Save records button pressed');
              // viewModel.saveAllChanges();
            },
          ),
        ],
      ),
      body: Consumer<DocumentRecordViewModel>(
        // Consumer ฟังการเปลี่ยนแปลงใน DocumentRecordViewModel และ rebuild builder
        builder: (context, viewModel, child) {
          // แสดง SnackBar สำหรับข้อความ Sync
          if (viewModel.syncMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.syncMessage!)),
              );
              viewModel.syncMessage = null; // ล้างข้อความหลังจากแสดง
            });
          }

          return Stack(
            // Stack สำหรับวาง Widgets ซ้อนทับกัน (ใช้สำหรับ Loading Overlay)
            children: [
              Column(
                // Column หลักสำหรับจัดเรียง UI ในแนวตั้ง
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Padding รอบข้อความสถานะ
                    child: Text(
                      viewModel.statusMessage, // แสดงข้อความสถานะจาก ViewModel
                      style: Theme.of(context).textTheme.headlineSmall, // ใช้สไตล์หัวข้อ
                      textAlign: TextAlign.center, // จัดข้อความกึ่งกลาง
                    ),
                  ),
                  Expanded(
                    // Expanded ทำให้ ListView ใช้พื้นที่แนวตั้งที่เหลือทั้งหมด
                    child: StreamBuilder<List<DocumentRecordWithTagAndProblem>>(
                      // StreamBuilder ฟัง stream ของรายการบันทึกจาก ViewModel
                      stream: viewModel.recordsStream,
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          // แสดง CircularProgressIndicator ถ้ากำลังโหลดข้อมูลเริ่มต้น
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // แสดงข้อผิดพลาดถ้า stream มีปัญหา
                          return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          // แสดงข้อความถ้าไม่พบบันทึกสำหรับเอกสารและเครื่องจักรนี้
                          return const Center(child: Text('ไม่พบบันทึกสำหรับเอกสารและเครื่องจักรนี้.'));
                        } else {
                          // ถ้ามีข้อมูล, สร้างรายการบันทึก
                          final records = snapshot.data!;
                          return ListView.builder(
                            itemCount: records.length, // จำนวนบันทึกในรายการ
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Padding สำหรับทั้งรายการ
                            itemBuilder: (context, index) {
                              final recordWithTag = records[index];
                              final DbDocumentRecord record = recordWithTag.documentRecord;
                              final DbJobTag? jobTag = recordWithTag.jobTag; // รายละเอียด Tag
                              final DbProblem? problem = null; // รายละเอียด Problem

                              // แสดงแต่ละบันทึกเป็น Card คล้ายกับ document_record_fragment_item.xml
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0), // ระยะห่างแนวตั้งระหว่าง Card
                                elevation: 4.0, // เพิ่มเงาให้กับ Card
                                 child: InkWell(
                                  onTap: () {
                                    // CRUCIAL CHANGE: Show details dialog on tap
                                    _showRecordDetailsDialog(context, recordWithTag); // <<< แก้ไขตรงนี้
                                    // No longer handling selection state here, single tap directly shows details.
                                  },
                                  onLongPress: () {
                                    // Long press also shows details, or could be used for other context menu actions
                                    _showRecordDetailsDialog(context, recordWithTag); // <<< แก้ไขตรงนี้
                                  },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0), // Padding ภายในเนื้อหา Card
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, // จัดข้อความชิดซ้าย
                                    children: [
                                      // ชื่อ Tag (จาก JobTag)
                                      Text(
                                        jobTag?.tagName ?? 'N/A',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8.0),
                                      
                                      // CRUCIAL CHANGE: Pass errorText to _buildInputField
                                      _buildInputField(context, record, jobTag, problem, viewModel, 
                                          errorText: viewModel.recordErrors[record.uid]), // <<< เพิ่ม errorText ตรงนี้


                                      // แสดงค่าปัจจุบันและหมายเหตุจากบันทึก (ถ้ามี)
                                      if (record.value != null && record.value!.isNotEmpty)
                                        Text('ค่าปัจจุบัน: ${record.value}', style: Theme.of(context).textTheme.bodySmall),
                                      if (record.remark != null && record.remark!.isNotEmpty)
                                        Text('หมายเหตุ: ${record.remark}', style: Theme.of(context).textTheme.bodySmall),
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
              // Loading overlay ที่ปรากฏทับเนื้อหาเมื่อ isLoading เป็น true
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5), // พื้นหลังสีดำโปร่งแสง
                  alignment: Alignment.center, // จัดวาง CircularProgressIndicator ตรงกลาง
                  child: const CircularProgressIndicator(), // Loading spinner
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Helper method เพื่อสร้างช่องป้อนข้อมูลแบบ Dynamic ตาม tagType ---
  Widget _buildInputField(BuildContext context, DbDocumentRecord record, DbJobTag? jobTag, DbProblem? problem, DocumentRecordViewModel viewModel,{String? errorText}) {
    final String tagType = jobTag?.tagType ?? '';
    
    // Switch on tagType to return different input widgets
    switch (tagType) {
      case 'Number':
        return RecordNumberInputField(
          record: record, jobTag: jobTag, viewModel: viewModel,
          controller: _controllers.putIfAbsent(record.uid, () => TextEditingController(text: record.value)),
          errorText: errorText, // <<< Pass errorText
        );
      case 'ComboBox':
        return RecordComboBoxInputField(
          record: record, jobTag: jobTag, viewModel: viewModel,
          initialSelectedValue: _selectedComboBoxValues.putIfAbsent(record.uid, () => record.value),
          errorText: errorText, // <<< Pass errorText
        );
      case 'Text': // Single line text
        return RecordTextInputField(
          record: record, jobTag: jobTag, viewModel: viewModel,
          controller: _controllers.putIfAbsent(record.uid, () => TextEditingController(text: record.value)),
          errorText: errorText, // <<< Pass errorText
        );
      case 'Message': // Multi-line text (like 'ข้อความยาวๆ')
        return RecordTextInputField(
          record: record, jobTag: jobTag, viewModel: viewModel,
          controller: _controllers.putIfAbsent(record.uid, () => TextEditingController(text: record.value)),
          isMultiline: true,
          errorText: errorText, // <<< Pass errorText
        );
       case 'CheckBox': // NEW: Handle CheckBox TagType
        return RecordComboBoxInputField( // Reuse ComboBox for now, as it handles selection from a list
          record: record, jobTag: jobTag, viewModel: viewModel,
          initialSelectedValue: _selectedComboBoxValues.putIfAbsent(record.uid, () => record.value),
          errorText: viewModel.recordErrors[record.uid],
        );
      default:
        // Default to a basic text field for unknown types
        return RecordTextInputField(
          record: record, jobTag: jobTag, viewModel: viewModel,
          controller: _controllers.putIfAbsent(record.uid, () => TextEditingController(text: record.value)),
          errorText: errorText, // <<< Pass errorText
        );
    }
  }
}
