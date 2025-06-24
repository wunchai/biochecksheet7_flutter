// lib/ui/documentrecord/inputs/record_number_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart'; // For ViewModel

class RecordNumberInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DocumentRecordViewModel viewModel;
  final TextEditingController controller; // Pass the controller

  const RecordNumberInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    required this.controller,
  });

  @override
  State<RecordNumberInputField> createState() => _RecordNumberInputFieldState();
}

class _RecordNumberInputFieldState extends State<RecordNumberInputField> {
  @override
  void initState() {
    super.initState();
    // Initialize controller text from record.value
    if (widget.controller.text != widget.record.value) {
      widget.controller.text = widget.record.value ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant RecordNumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if record.value changes (e.g., after refresh)
    if (widget.controller.text != widget.record.value) {
      widget.controller.text = widget.record.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? specMin = widget.jobTag?.specMin;
    final String? specMax = widget.jobTag?.specMax;
    String hint = 'ป้อนตัวเลข';
    if (specMin != null && specMin.isNotEmpty && specMax != null && specMax.isNotEmpty) {
      hint += ' ($specMin - $specMax)';
    } else if (specMin != null && specMin.isNotEmpty) {
      hint += ' (Min: $specMin)';
    } else if (specMax != null && specMax.isNotEmpty) {
      hint += ' (Max: $specMax)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: '${widget.jobTag?.tagName ?? 'ตัวเลข'} (${widget.jobTag?.unit ?? ''})',
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.viewModel.updateRecordValue(
                  widget.record.uid, widget.controller.text, widget.record.remark);
            },
          ),
        ),
        keyboardType: TextInputType.number,
        onSubmitted: (value) {
          widget.viewModel.updateRecordValue(widget.record.uid, value, widget.record.remark);
        },
      ),
    );
  }
}