// lib/ui/documentrecord/inputs/record_combobox_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
//import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/document_record_viewmodel.dart'; // For ViewModel
import 'dart:convert'; // For jsonDecode

class RecordComboBoxInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DocumentRecordViewModel viewModel;
  final String? initialSelectedValue;
  final String? errorText;
  final ValueChanged<String?>
      onChangedCallback; // Callback to notify parent about value change
  final bool isReadOnly; // <<< NEW parameter

  const RecordComboBoxInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    this.initialSelectedValue,
    this.errorText,
    required this.onChangedCallback,
    required this.isReadOnly, // <<< NEW
  });

  @override
  State<RecordComboBoxInputField> createState() =>
      _RecordComboBoxInputFieldState();
}

class _RecordComboBoxInputFieldState extends State<RecordComboBoxInputField> {
  // _currentSelectedValue จะยังคงใช้เป็น internal state ของ Dropdown
  // แต่การอัปเดตจริงจะผ่าน ViewModel ไปยัง DB และ Stream
  String? _currentSelectedValue;

  @override
  void initState() {
    super.initState();
    _currentSelectedValue = widget.initialSelectedValue;
  }

  @override
  void didUpdateWidget(covariant RecordComboBoxInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state if the initialSelectedValue from parent changes (e.g., from DB update)
    if (widget.initialSelectedValue != oldWidget.initialSelectedValue) {
      setState(() {
        // Call setState here to rebuild Dropdown with new value
        _currentSelectedValue = widget.initialSelectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = [];
    String? displayInitialValue = widget.record.value;

    if (widget.jobTag?.tagSelectionValue != null &&
        widget.jobTag!.tagSelectionValue!.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(widget.jobTag!.tagSelectionValue!);
        if (decoded is List) {
          options =
              decoded.map((item) => item['value']?.toString() ?? '').toList();
        } else {
          options = widget.jobTag!.tagSelectionValue!
              .split(',')
              .map((s) => s.trim())
              .toList();
        }
      } catch (e) {
        options = widget.jobTag!.tagSelectionValue!
            .split(',')
            .map((s) => s.trim())
            .toList();
      }
    }

    // Ensure that _currentSelectedValue is still a valid option
    if (_currentSelectedValue != null &&
        !options.contains(_currentSelectedValue)) {
      _currentSelectedValue = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: _currentSelectedValue, // Use internal state for display
        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'เลือกตัวเลือก',
          border: const OutlineInputBorder(),
          errorText: widget.errorText, // Display error text
          // Hint text when read-only
          hintText: widget.isReadOnly ? 'ไม่สามารถแก้ไขได้' : null,
        ),
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: widget.isReadOnly
            ? null
            : (String? newValue) {
                // <<< Disable when read-only
                setState(() {
                  // Update internal state for immediate visual feedback
                  _currentSelectedValue = newValue;
                });
                widget.onChangedCallback(
                    newValue); // Call callback to update parent's map
                widget.viewModel.updateRecordValue(
                    widget.record.uid, newValue, widget.record.remark,
                    newStatus: 0);
              },
        // Remove the dropdown icon when read-only for clearer visual feedback
        icon: widget.isReadOnly
            ? const SizedBox.shrink()
            : const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}
