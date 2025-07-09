// lib/ui/widgets/error_dialog.dart
import 'package:flutter/material.dart';

/// A reusable dialog widget for displaying error messages.
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details; // Optional: For more technical details or stack trace

  const ErrorDialog({
    super.key,
    this.title = 'เกิดข้อผิดพลาด', // Default title
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(message),
            if (details != null && details!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  'รายละเอียด: $details',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('ตกลง'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}