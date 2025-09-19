import 'package:flutter/material.dart';

/// A dialog that shows the progress of a synchronization process.
/// It listens to ValueNotifiers to update its UI reactively.
class SyncProgressDialog extends StatelessWidget {
  final ValueNotifier<double?> progressNotifier;
  final ValueNotifier<String> statusNotifier;

  const SyncProgressDialog({
    super.key,
    required this.progressNotifier,
    required this.statusNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('กำลังซิงค์ Master Images...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // This builder listens to progress changes
          ValueListenableBuilder<double?>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value:
                        progress, // Shows determinate or indeterminate progress
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress != null
                        ? '${(progress * 100).toStringAsFixed(0)}%'
                        : 'โปรดรอสักครู่...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // This builder listens to status message changes
          ValueListenableBuilder<String>(
            valueListenable: statusNotifier,
            builder: (context, status, child) {
              return Text(status, textAlign: TextAlign.center);
            },
          ),
        ],
      ),
    );
  }
}
