// lib/ui/documentrecord/inputs/record_problem_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
//import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
//import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart'; // For ViewModel

class AmRecordProblemInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DbProblem? problem; // The problem object associated with the record
  final AMChecksheetViewModel viewModel;
  final TextEditingController controller; // Pass the controller
  final String?
      errorText; // NEW: Parameter to receive error text from ViewModel
  final bool isReadOnly; // <<< NEW parameter

  const AmRecordProblemInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.problem,
    required this.viewModel,
    required this.controller,
    this.errorText, // NEW: Make it optional
    required this.isReadOnly, // <<< NEW
  });

  @override
  State<AmRecordProblemInputField> createState() =>
      _AmRecordProblemInputFieldState();
}

class _AmRecordProblemInputFieldState extends State<AmRecordProblemInputField> {
  @override
  void initState() {
    super.initState();
    // Initialize controller text from problem.problemName or record.value
    final displayText = widget.problem?.problemName ?? widget.record.value;
    if (widget.controller.text != displayText) {
      widget.controller.text = displayText ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant AmRecordProblemInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if problem or record.value changes
    final displayText = widget.problem?.problemName ?? widget.record.value;
    if (widget.controller.text != displayText) {
      widget.controller.text = displayText ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: widget.controller,
        readOnly:
            true, // Typically, problem selection is via a picker, so it's read-only.
        enabled: !widget.isReadOnly, // <<< Disable the field if it's read-only

        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'เลือกปัญหา',
          hintText: widget.isReadOnly
              ? 'ไม่สามารถแก้ไขได้'
              : (widget.problem?.problemName ?? 'แตะเพื่อเลือกปัญหา'),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.edit), // Icon to open problem picker
            onPressed: widget.isReadOnly
                ? null
                : () {
                    // <<< Disable button when read-only
                    // TODO: Implement logic to open a dialog or navigate to a screen to select a problem
                    print(
                        'Open problem picker for record UID: ${widget.record.uid}');
                    // After selection, you would update the ViewModel with the selected Problem ID (e.g., viewModel.updateRecordValue(record.uid, selectedProblemId, record.remark))
                  },
          ),
        ),
        onSubmitted: (value) {
          // This might not be used if readOnly is true, but good to have
          if (!widget.isReadOnly) {
            // Only submit if not read-only

            widget.viewModel.updateRecordValue(
                widget.record.uid, value, widget.record.remark);
          }
        },
      ),
    );
  }
}
