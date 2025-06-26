// lib/ui/documentrecord/widgets/remark_input_dialog.dart
import 'package:flutter/material.dart';

/// A StatefulWidget that provides a TextField for remark input
/// and manages its own TextEditingController lifecycle.
/// This is designed to be used as the content of an AlertDialog.
class RemarkInputDialog extends StatefulWidget {
  // CRUCIAL CHANGE: Accept TextEditingController from outside
  final TextEditingController controller; 

  const RemarkInputDialog({super.key, required this.controller});

  @override
  State<RemarkInputDialog> createState() => _RemarkInputDialogState();
}

class _RemarkInputDialogState extends State<RemarkInputDialog> {
  // The controller is now passed from outside, so no need to manage here.
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
  // No need for getCurrentRemark() here as parent directly accesses controller
}