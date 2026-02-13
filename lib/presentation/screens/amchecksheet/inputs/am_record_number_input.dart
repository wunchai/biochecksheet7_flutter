// lib/ui/documentrecord/inputs/record_number_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
//import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart'; // For ViewModel

class AmRecordNumberInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final AMChecksheetViewModel viewModel;
  final TextEditingController controller;
  final String? errorText;
  final bool isReadOnly; // <<< NEW parameter

  const AmRecordNumberInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.viewModel,
    required this.controller,
    this.errorText,
    required this.isReadOnly, // <<< NEW
  });

  @override
  State<AmRecordNumberInputField> createState() =>
      _AmRecordNumberInputFieldState();
}

class _AmRecordNumberInputFieldState extends State<AmRecordNumberInputField> {
  // Internal state for the Checkbox, reflects record.unReadable
  late bool _isUnReadableChecked;

  @override
  void initState() {
    super.initState();
    _isUnReadableChecked = widget.record.unReadable == 'true';
    // Controller is initialized by parent and passed correctly.
    // No need to set text here.
  }

  @override
  void didUpdateWidget(covariant AmRecordNumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal checkbox state if record.unReadable changes from outside
    if (widget.record.unReadable != oldWidget.record.unReadable) {
      _isUnReadableChecked = widget.record.unReadable == 'true';
    }
    // Controller text is now managed by parent _buildInputField.
    // No need for these lines.
    // if (!_isUnReadableChecked && widget.controller.text != widget.record.value) {
    //   widget.controller.text = widget.record.value ?? '';
    // }
    // if (_isUnReadableChecked && widget.controller.text.isNotEmpty) {
    //   widget.controller.clear();
    // }
  }

  @override
  Widget build(BuildContext context) {
    final String? specMin = widget.jobTag?.specMin;
    final String? specMax = widget.jobTag?.specMax;
    String hint = 'ป้อนตัวเลข';
    if (specMin != null &&
        specMin.isNotEmpty &&
        specMax != null &&
        specMax.isNotEmpty) {
      hint += ' ($specMin - $specMax)';
    } else if (specMin != null && specMin.isNotEmpty) {
      hint += ' (Min: $specMin)';
    } else if (specMax != null && specMax.isNotEmpty) {
      hint += ' (Max: $specMax)';
    }

    // Determine if calculation button should be shown
    final bool showCalculateButton = (widget.jobTag?.valueType == 'Calculate' ||
        widget.jobTag?.valueType == 'Formula');
    final bool isEnabled = !widget.isReadOnly && !_isUnReadableChecked;
    final bool isReallyReadOnly = widget.isReadOnly || _isUnReadableChecked;

    // print('RecordNumberInputField UID: ${widget.record.uid}...');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        // Use Column to stack TextField and Checkbox
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            enabled: isEnabled,
            readOnly: isReallyReadOnly,
            decoration: InputDecoration(
              labelText:
                  '${widget.jobTag?.tagName ?? 'ตัวเลข'} (${widget.jobTag?.unit ?? ''})',
              hintText: widget.isReadOnly
                  ? 'ไม่สามารถแก้ไขได้'
                  : (_isUnReadableChecked
                      ? 'ไม่อ่านค่าได้'
                      : hint), // Hint when read-only
              border: const OutlineInputBorder(),
              // Add a Row for suffix icons if multiple buttons are needed
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min, // Use min size for the row
                children: [
                  // Calculate Button
                  if (showCalculateButton) // Show only if valueType is Calculate or Formula
                    IconButton(
                      icon: const Icon(Icons.calculate), // Icon for calculation
                      onPressed: isEnabled
                          ? () {
                              // <<< Only enabled if field is enabled
                              widget.viewModel
                                  .calculateRecordValue(widget.record.uid);
                            }
                          : null,
                    ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: isEnabled
                        ? () {
                            // Disable check button too
                            widget.viewModel.updateRecordValue(
                                widget.record.uid,
                                widget.controller.text,
                                widget.record.remark,
                                newStatus: 0);
                          }
                        : null,
                  ),
                ],
              ),
              errorText: widget
                  .errorText, // Display error text directly from ViewModel
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              if (isEnabled) {
                // Only submit if not unReadable
                widget.viewModel.updateRecordValue(
                    widget.record.uid, value, widget.record.remark,
                    newStatus: 0);
              }
            },
          ),
          // NEW: Checkbox for unReadable
          Row(
            children: [
              Checkbox(
                value: _isUnReadableChecked,
                onChanged: widget.isReadOnly
                    ? null
                    : (bool? newValue) async {
                        // <<< Disable checkbox when read-only
                        if (newValue != null) {
                          setState(() {
                            _isUnReadableChecked =
                                newValue; // Update internal state
                            if (_isUnReadableChecked) {
                              widget.controller
                                  .clear(); // Clear value when checked
                            } else {
                              // Restore original value if unReadable is unchecked, or keep empty
                              widget.controller.text =
                                  widget.record.value ?? '';
                            }
                          });
                          // Update ViewModel and database
                          await widget.viewModel.updateUnReadableStatus(
                              widget.record.uid, newValue);
                          // No need to call updateRecordValue explicitly here as updateUnReadableStatus handles it
                        }
                      },
              ),
              const Text('ไม่อ่านค่าได้'), // Label for the checkbox
            ],
          ),
        ],
      ),
    );
  }
}
