// lib/ui/documentrecord/widgets/remark_input_dialog.dart
import 'package:flutter/material.dart';

/// A StatelessWidget (or StatefulWidget that manages its own controller) that provides a TextField for remark input.
/// This is designed to be used as the content of an AlertDialog.
class RemarkInputDialogContent extends StatefulWidget { // Keeping StatefulWidget for potential future internal state
  // CRUCIAL CHANGE: Accept TextEditingController from outside
  final TextEditingController controller; 

  const RemarkInputDialogContent({
    super.key,
    required this.controller, // Require the controller to be passed
  });

  @override
  State<RemarkInputDialogContent> createState() => _RemarkInputDialogContentState();
}

class _RemarkInputDialogContentState extends State<RemarkInputDialogContent> {
  // Controller is now passed from outside, so no need to manage it here.
  // We just use widget.controller directly.

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller, // Use the controller passed from widget
      maxLines: 3, // Allow multi-line input
      decoration: const InputDecoration(
        hintText: 'ป้อนหมายเหตุที่นี่',
        border: OutlineInputBorder(),
      ),
    );
  }
}