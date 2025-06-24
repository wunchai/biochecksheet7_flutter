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
  final String? initialSelectedValue; // Pass initial value for dropdown

  const RecordComboBoxInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    this.initialSelectedValue, // This will come from _selectedComboBoxValues map
  });

  @override
  State<RecordComboBoxInputField> createState() => _RecordComboBoxInputFieldState();
}

class _RecordComboBoxInputFieldState extends State<RecordComboBoxInputField> {
  String? _currentSelectedValue; // Internal state for the dropdown

  @override
  void initState() {
    super.initState();
    _currentSelectedValue = widget.initialSelectedValue;
  }

  @override
  void didUpdateWidget(covariant RecordComboBoxInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state if the initialSelectedValue from parent changes
    if (widget.initialSelectedValue != oldWidget.initialSelectedValue) {
      _currentSelectedValue = widget.initialSelectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = [];

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
    
    // Ensure the current selected value is still in options
    if (_currentSelectedValue != null && !options.contains(_currentSelectedValue)) {
      _currentSelectedValue = null;
    }


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: _currentSelectedValue,
        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'เลือกตัวเลือก',
          border: const OutlineInputBorder(),
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