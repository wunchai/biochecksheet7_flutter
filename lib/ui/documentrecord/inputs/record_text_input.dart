// lib/ui/documentrecord/inputs/record_text_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart'; // For ViewModel

class RecordTextInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DocumentRecordViewModel viewModel;
  final bool isMultiline;
  final TextEditingController controller; // Pass the controller
  final String? errorText; // NEW: Parameter to receive error text from ViewModel

  const RecordTextInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    required this.controller,
    this.isMultiline = false,
     this.errorText, // NEW: Make it optional
  });

  @override
  State<RecordTextInputField> createState() => _RecordTextInputFieldState();
}

class _RecordTextInputFieldState extends State<RecordTextInputField> {
  @override
  void initState() {
    super.initState();
    // Initialize controller text from record.value
    if (widget.controller.text != widget.record.value) {
      widget.controller.text = widget.record.value ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant RecordTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if record.value changes (e.g., after refresh)
    if (widget.controller.text != widget.record.value) {
      widget.controller.text = widget.record.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'ป้อนค่า',
          hintText: 'ป้อนข้อความ',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.viewModel.updateRecordValue(
                  widget.record.uid, widget.controller.text, widget.record.remark);
            },
          ),
        ),
        keyboardType: widget.isMultiline ? TextInputType.multiline : TextInputType.text,
        maxLines: widget.isMultiline ? null : 1, // null for unlimited lines
        onSubmitted: (value) {
          widget.viewModel.updateRecordValue(widget.record.uid, value, widget.record.remark);
        },
      ),
    );
  }
}