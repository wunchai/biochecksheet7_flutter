import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'dart:convert';

class AmRecordCheckBoxInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final AMChecksheetViewModel viewModel;
  final String? initialSelectedValue;
  final String? errorText;
  final ValueChanged<String?> onChangedCallback;
  final bool isReadOnly;

  const AmRecordCheckBoxInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    this.initialSelectedValue,
    this.errorText,
    required this.onChangedCallback,
    required this.isReadOnly,
  });

  @override
  State<AmRecordCheckBoxInputField> createState() =>
      _AmRecordCheckBoxInputFieldState();
}

class _AmRecordCheckBoxInputFieldState
    extends State<AmRecordCheckBoxInputField> {
  // We use a simple String to hold the single selected value (Radio button behavior)
  String? _currentSelectedValue;

  @override
  void initState() {
    super.initState();
    _currentSelectedValue = widget.initialSelectedValue;
  }

  @override
  void didUpdateWidget(covariant AmRecordCheckBoxInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedValue != oldWidget.initialSelectedValue) {
      if (mounted) {
        setState(() {
          _currentSelectedValue = widget.initialSelectedValue;
        });
      }
    }
  }

  void _handleSelection(String option, bool? isChecked) {
    if (widget.isReadOnly) return;

    String? newValue;
    if (isChecked == true) {
      // Single Select: Check this one, replace any existing value
      newValue = option;
    } else {
      // Unchecking the currently selected value (optional: allow clearing)
      if (_currentSelectedValue == option) {
        newValue = null; // Or keep it if mandatory
      } else {
        return; // No change if unchecking something not selected (shouldn't happen in single select logic really)
      }
    }

    setState(() {
      _currentSelectedValue = newValue;
    });

    // Notify parent and ViewModel
    widget.onChangedCallback(newValue);
    widget.viewModel.updateRecordValue(
      widget.record.uid,
      newValue,
      widget.record.remark,
      newStatus: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = [];

    if (widget.jobTag?.tagSelectionValue != null &&
        widget.jobTag!.tagSelectionValue!.isNotEmpty) {
      try {
        // Attempt JSON decode first
        final dynamic decoded = jsonDecode(widget.jobTag!.tagSelectionValue!);
        if (decoded is List) {
          options =
              decoded.map((item) => item['value']?.toString() ?? '').toList();
        } else {
          // Fallback splits
          options = widget.jobTag!.tagSelectionValue!
              .split(',')
              .map((s) => s.trim())
              .toList();
        }
      } catch (e) {
        // Fallback splits on error
        options = widget.jobTag!.tagSelectionValue!
            .split(',')
            .map((s) => s.trim())
            .toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.jobTag?.tagName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.jobTag!.tagName!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (options.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No options available',
                style: TextStyle(color: Colors.grey)),
          ),
        ...options.map((option) {
          final isChecked = _currentSelectedValue == option;
          return CheckboxListTile(
            title: Text(option),
            value: isChecked,
            onChanged: widget.isReadOnly
                ? null
                : (bool? value) {
                    _handleSelection(option, value);
                  },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        }),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
