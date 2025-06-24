// lib/ui/documentrecord/inputs/record_problem_input.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_viewmodel.dart'; // For ViewModel

class RecordProblemInputField extends StatefulWidget {
  final DbDocumentRecord record;
  final DbJobTag? jobTag;
  final DbProblem? problem; // The problem object associated with the record
  final DocumentRecordViewModel viewModel;
  final TextEditingController controller; // Pass the controller

  const RecordProblemInputField({
    super.key,
    required this.record,
    required this.jobTag,
    required this.problem,
    required this.viewModel,
    required this.controller,
  });

  @override
  State<RecordProblemInputField> createState() => _RecordProblemInputFieldState();
}

class _RecordProblemInputFieldState extends State<RecordProblemInputField> {
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
  void didUpdateWidget(covariant RecordProblemInputField oldWidget) {
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
        readOnly: true, // Typically, problem selection is via a picker, so it's read-only.
        decoration: InputDecoration(
          labelText: widget.jobTag?.tagName ?? 'เลือกปัญหา',
          hintText: widget.problem?.problemName ?? 'แตะเพื่อเลือกปัญหา', // Show problem name or hint
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.edit), // Icon to open problem picker
            onPressed: () {
              // TODO: Implement logic to open a dialog or navigate to a screen to select a problem
              print('Open problem picker for record UID: ${widget.record.uid}');
              // After selection, you would update the ViewModel with the selected Problem ID (e.g., viewModel.updateRecordValue(record.uid, selectedProblemId, record.remark))
            },
          ),
        ),
        onSubmitted: (value) {
          // This might not be used if readOnly is true, but good to have
          widget.viewModel.updateRecordValue(widget.record.uid, value, widget.record.remark);
        },
      ),
    );
  }
}