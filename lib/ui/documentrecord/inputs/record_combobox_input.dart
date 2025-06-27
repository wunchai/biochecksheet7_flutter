// lib/ui/documentrecord/inputs/record_combobox_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart'; // For ViewModel
import 'dart:convert'; // For jsonDecode

class RecordComboBoxInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DocumentRecordViewModel viewModel;
  final String? initialSelectedValue;
  final String? errorText; // NEW: Parameter to receive error text from ViewModel
  const RecordComboBoxInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    this.initialSelectedValue,
     this.errorText, // NEW: Make it optional
  });

  @override
  State<RecordComboBoxInputField> createState() => _RecordComboBoxInputFieldState();
}

class _RecordComboBoxInputFieldState extends State<RecordComboBoxInputField> {
  String? _currentSelectedValue;

  @override
  void initState() {
    super.initState();
    _currentSelectedValue = widget.initialSelectedValue;
  }

  @override
  void didUpdateWidget(covariant RecordComboBoxInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CRUCIAL: Update internal state ONLY if the new initialSelectedValue is different
    // This handles cases where the parent rebuilds but the value hasn't changed.
    if (widget.initialSelectedValue != oldWidget.initialSelectedValue) {
      _currentSelectedValue = widget.initialSelectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = [];
    String? displayInitialValue = widget.record.value; // Get value from record directly

    if (widget.jobTag?.tagSelectionValue != null && widget.jobTag!.tagSelectionValue!.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(widget.jobTag!.tagSelectionValue!);
        if (decoded is List) {
          options = decoded.map((item) => item['value']?.toString() ?? '').toList();
        } else {
          options = widget.jobTag!.tagSelectionValue!.split(',').map((s) => s.trim()).toList();
        }
      } catch (e) {
        options = widget.jobTag!.tagSelectionValue!.split(',').map((s) => s.trim()).toList();
      }
    }
    
    // Ensure the displayInitialValue is in the options list, otherwise set to null
    if (displayInitialValue != null && !options.contains(displayInitialValue)) {
        displayInitialValue = null;
    }
    // Update _currentSelectedValue if it somehow got out of sync or if the record.value updated
    if (_currentSelectedValue != displayInitialValue) {
      _currentSelectedValue = displayInitialValue;
    }


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: _currentSelectedValue, // Use internal state
        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'เลือกตัวเลือก',
          border: const OutlineInputBorder(),
           errorText: widget.errorText, // <<< เพิ่มบรรทัดนี้
        ),
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _currentSelectedValue = newValue;
          });
          widget.viewModel.updateRecordValue(widget.record.uid, newValue, widget.record.remark);
        },
      ),
    );
  }
}