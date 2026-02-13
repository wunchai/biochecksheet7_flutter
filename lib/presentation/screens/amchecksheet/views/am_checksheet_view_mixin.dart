import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';

import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_text_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_number_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_combobox_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_checkbox_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/inputs/am_record_problem_input.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/widgets/am_record_detail_dialog.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/widgets/am_remark_input_dialog.dart';

mixin AmChecksheetViewMixin<T extends StatefulWidget> on State<T> {
  // Dependencies required by the mixin
  AMChecksheetViewModel get viewModel;
  Map<int, TextEditingController> get controllers;
  Map<int, String?> get selectedComboBoxValues;

  // Helper to manage controllers
  TextEditingController getOrCreateAndSyncController(int uid, String? value) {
    final controller =
        controllers.putIfAbsent(uid, () => TextEditingController());
    if (controller.text != (value ?? '')) {
      controller.text = value ?? '';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }
    return controller;
  }

  Future<void> openImageEditor(
    BuildContext context,
    DbCheckSheetMasterImage imageRecord,
  ) async {
    Uint8List? initialImageBytes;
    if (kIsWeb) {
      initialImageBytes = base64Decode(imageRecord.path!);
    } else {
      final file = File(imageRecord.path!);
      if (await file.exists()) {
        initialImageBytes = await file.readAsBytes();
      }
    }

    if (initialImageBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถโหลดไฟล์รูปภาพเพื่อแก้ไขได้')),
        );
      }
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) {
          debugPrint('Building ImageEditor...');
          return ImageEditor(
            image: initialImageBytes!,
          );
        },
      ),
    );

    debugPrint('MaterialPageRoute ImageEditor rturn ');
    if (result != null && mounted) {
      debugPrint('Received image bytes: length=${result.length}');
      final success = await viewModel.updateMasterImage(imageRecord, result);

      if (success) {
        setState(() {}); // Trigger rebuild to show updated image
      }
    }
  }

  void showRecordDetailsDialog(
      BuildContext context, DocumentRecordWithTagAndProblem recordWithTag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AmRecordDetailDialog(recordWithTag: recordWithTag);
      },
    );
  }

  Future<void> showRemarkInputDialog(
      BuildContext context, DbDocumentRecord record) async {
    final TextEditingController remarkController =
        TextEditingController(text: record.remark);

    final String? resultRemark = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เพิ่ม/แก้ไขหมายเหตุ'),
          content: AmRemarkInputDialogContent(controller: remarkController),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              child: const Text('บันทึก'),
              onPressed: () => Navigator.of(context).pop(remarkController.text),
            ),
          ],
        );
      },
    );

    if (resultRemark != null) {
      await viewModel.updateRecordValue(
        record.uid,
        record.value,
        resultRemark,
        newStatus: 0,
      );
    }
  }

  void showImageSourceDialog(BuildContext context, DbJobTag jobTag) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('ถ่ายภาพ'),
                onTap: () {
                  viewModel.selectAndSaveNewMasterImage(
                      jobTag, ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากคลังภาพ'),
                onTap: () {
                  viewModel.selectAndSaveNewMasterImage(
                      jobTag, ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showFullScreenImage(BuildContext context, String? pathOrBase64) {
    if (pathOrBase64 == null || pathOrBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีรูปภาพสำหรับรายการนี้')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
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
                child: kIsWeb
                    ? Image.memory(
                        base64Decode(pathOrBase64),
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 80,
                              ),
                            ),
                          );
                        },
                      )
                    : Image.file(File(pathOrBase64),
                        errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 80,
                            ),
                          ),
                        );
                      }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildInputField(
    BuildContext context,
    DbDocumentRecord record,
    DbJobTag? jobTag,
    DbProblem? problem, {
    String? errorText,
    required bool isRecordReadOnly,
  }) {
    final String tagType = jobTag?.tagType ?? '';
    final TextEditingController controller =
        getOrCreateAndSyncController(record.uid, record.value);

    // Sync logic already in getOrCreate... but double check
    if (controller.text != record.value) {
      controller.text = record.value ?? '';
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    }

    switch (tagType) {
      case 'Number':
        return AmRecordNumberInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          controller: controller,
          errorText: viewModel.recordErrors[record.uid],
          isReadOnly: isRecordReadOnly,
        );
      case 'ComboBox':
        return AmRecordComboBoxInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          initialSelectedValue: selectedComboBoxValues.putIfAbsent(
              record.uid, () => record.value),
          errorText: viewModel.recordErrors[record.uid],
          onChangedCallback: (newValue) {
            setState(() {
              selectedComboBoxValues[record.uid] = newValue;
            });
          },
          isReadOnly: isRecordReadOnly,
        );
      case 'CheckBox':
        return AmRecordCheckBoxInputField(
          key: ValueKey(record.uid),
          record: record,
          jobTag: jobTag,
          viewModel: viewModel,
          initialSelectedValue: selectedComboBoxValues.putIfAbsent(
              record.uid, () => record.value),
          errorText: viewModel.recordErrors[record.uid],
          onChangedCallback: (newValue) {
            setState(() {
              selectedComboBoxValues[record.uid] = newValue;
            });
          },
          isReadOnly: isRecordReadOnly,
        );
      case 'Text':
      case 'Message':
        return AmRecordTextInputField(
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

  String getStatusText(int? status) {
    if (status == 0) return 'รอตรวจสอบ';
    if (status == 1) return 'บันทึกแล้ว';
    if (status == 2) return 'โพสต์แล้ว';
    return 'ไม่ทราบสถานะ';
  }
}
