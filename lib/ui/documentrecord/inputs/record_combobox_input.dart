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
  final String? errorText;
  final bool isReadOnly; // <<< NEW parameter

  const RecordComboBoxInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    this.initialSelectedValue,
    this.errorText,
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
    if (widget.initialSelectedValue != oldWidget.initialSelectedValue) {
      // Update internal state if the initialSelectedValue from parent changes (e.g. from DB update)
      setState(() {
        // << CRUCIAL: Call setState here to rebuild Dropdown with new value
        _currentSelectedValue = widget.initialSelectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = [];
    // The value displayed by the dropdown will come from _currentSelectedValue,
    // which is initially set from widget.initialSelectedValue.
    // When onChanged is called, _currentSelectedValue is updated internally.

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
                // CRUCIAL CHANGE: Directly call ViewModel to update the record value.
                // This ensures the value is saved to DB (and then refreshes the Stream).
                // The ViewModel will then notifyListeners, which will cause parent to rebuild
                // and pass the correct initialSelectedValue next time.
                widget.viewModel.updateRecordValue(
                    widget.record.uid, newValue, widget.record.remark);
              },
      ),
    );
  }
}
