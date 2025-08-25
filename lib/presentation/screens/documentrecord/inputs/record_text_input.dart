// lib/ui/documentrecord/inputs/record_text_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
//import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/document_record_viewmodel.dart'; // For ViewModel

class RecordTextInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DocumentRecordViewModel viewModel;
  final bool isMultiline;
  final TextEditingController controller; // Pass the controller
  final String?
      errorText; // NEW: Parameter to receive error text from ViewModel
  final bool isReadOnly; // <<< NEW parameter

  const RecordTextInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    required this.controller,
    this.isMultiline = false,
    this.errorText, // NEW: Make it optional
    required this.isReadOnly, // <<< NEW
  });

  @override
  State<RecordTextInputField> createState() => _RecordTextInputFieldState();
}

class _RecordTextInputFieldState extends State<RecordTextInputField> {
  @override
  void initState() {
    super.initState();
    // Controller is initialized by parent and passed correctly.
    // No need to set text here.
  }

  @override
  void didUpdateWidget(covariant RecordTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Controller text is now managed by parent _buildInputField.
    // No need for this line.
    // if (widget.controller.text != widget.record.value) {
    //   widget.controller.text = widget.record.value ?? '';
    // }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'RecordTextInputField UID: ${widget.record.uid}, TagName: ${widget.jobTag?.tagName}, Enabled: ${!widget.isReadOnly}, ReadOnly: ${widget.isReadOnly}, Controller text: "${widget.controller.text}"'); // <<< Debugging
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: widget.controller,
        enabled: !widget.isReadOnly, // <<< Disable when read-only
        readOnly: widget.isReadOnly, // <<< Make read-only when read-only
        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'ป้อนค่า',
          hintText: widget.isReadOnly
              ? 'ไม่สามารถแก้ไขได้'
              : 'ป้อนข้อความ', // Hint when read-only
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: widget.isReadOnly
                ? null
                : () {
                    // Disable button when read-only
                    widget.viewModel.updateRecordValue(widget.record.uid,
                        widget.controller.text, widget.record.remark,
                        newStatus: 0);
                  },
          ),
          errorText: widget.errorText,
        ),
        keyboardType:
            widget.isMultiline ? TextInputType.multiline : TextInputType.text,
        maxLines: widget.isMultiline ? null : 1, // null for unlimited lines
        onSubmitted: (value) {
          if (!widget.isReadOnly) {
            // Only submit if not read-only
            widget.viewModel.updateRecordValue(
                widget.record.uid, value, widget.record.remark,
                newStatus: 0);
          }
        },
      ),
    );
  }
}
