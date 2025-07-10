// lib/ui/problem/widgets/problem_list_item.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/ui/problem/problem_viewmodel.dart'; // For ProblemViewModel

/// Widget สำหรับแสดงแต่ละรายการปัญหาใน ProblemScreen.
/// แสดงข้อมูลสรุปและช่องสำหรับกรอก Solving Description.
class ProblemListItem extends StatefulWidget {
  final DbProblem problem;
  final ProblemViewModel viewModel;
  // final TextEditingController solvingDescController; // REMOVED: Controller will be managed internally
  final VoidCallback onTap; // Callback when the item is tapped (to show details)
  final VoidCallback onShowOnlineChart; // Callback to show online chart for this problem's tag

  const ProblemListItem({
    super.key,
    required this.problem,
    required this.viewModel,
    // required this.solvingDescController, // REMOVED
    required this.onTap,
    required this.onShowOnlineChart,
  });

  @override
  State<ProblemListItem> createState() => _ProblemListItemState();
}

class _ProblemListItemState extends State<ProblemListItem> {
  late TextEditingController _internalSolvingDescController; // <<< NEW: Internal controller

  @override
  void initState() {
    super.initState();
    // Initialize controller with the problem's solving description
    _internalSolvingDescController = TextEditingController(text: widget.problem.problemSolvingDescription ?? '');
  }

  @override
  void didUpdateWidget(covariant ProblemListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if problem.problemSolvingDescription changes from outside
    if (_internalSolvingDescController.text != (widget.problem.problemSolvingDescription ?? '')) {
      _internalSolvingDescController.text = widget.problem.problemSolvingDescription ?? '';
      // Keep cursor at the end
      _internalSolvingDescController.selection = TextSelection.fromPosition(TextPosition(offset: _internalSolvingDescController.text.length));
    }
  }

  @override
  void dispose() {
    _internalSolvingDescController.dispose(); // Dispose the internal controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if problemSolvingDescription is read-only (if problemStatus is 1 or 2)
    final bool isProblemReadOnly = widget.problem.problemStatus == 1 || widget.problem.problemStatus == 2;
    // Get ViewModel's loading status
    final bool viewModelIsLoading = widget.viewModel.isLoading; // Access isLoading from injected ViewModel

    // Determine if the TextField should be enabled
    final bool isEnabled = !isProblemReadOnly && !viewModelIsLoading;
    // Determine if the TextField should be read-only
    final bool isReadOnly = isProblemReadOnly || viewModelIsLoading;


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      child: InkWell(
        onTap: widget.onTap, // Call onTap callback to show details
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /*
              Text(
                widget.problem.problemName ?? 'N/A',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text('Problem ID: ${widget.problem.problemId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
              Text('Description: ${widget.problem.problemDescription ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
              Text('Machine: ${widget.problem.machineName ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
              Text('Tag: ${widget.problem.tagName ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
              Text('Status: ${widget.problem.problemStatus}', style: Theme.of(context).textTheme.bodySmall),
             */
              const SizedBox(height: 8.0),
              // Input field for problemSolvingDescription
              TextField(
                controller: _internalSolvingDescController, // <<< Use internal controller
                enabled: isEnabled, // Use calculated enabled state
                readOnly: isReadOnly, // Use calculated readOnly state
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'คำอธิบายการแก้ไข',
                  hintText: isReadOnly ? 'ไม่สามารถแก้ไขได้' : 'ป้อนคำอธิบายการแก้ไข',
                  border: const OutlineInputBorder(),
                  errorText: widget.viewModel.problemErrors[widget.problem.uid], // Display validation error
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: isEnabled ? () { // Only enable button if TextField is enabled
                      widget.viewModel.updateProblemSolvingDescription(widget.problem.uid, _internalSolvingDescController.text);
                    } : null,
                  ),
                ),
              ),
              // Action buttons (Post, Online Chart)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Post button
                  TextButton(
                    onPressed: (viewModelIsLoading || isProblemReadOnly || widget.problem.problemStatus != 0) ? null : () {
                      widget.viewModel.postProblem(widget.problem.uid, _internalSolvingDescController.text);
                    },
                    child: const Text('ส่งข้อมูล'),
                  ),
                  // Online Chart button (if tagType is Number)
                  if (widget.problem.tagType == 'Number')
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () {
                        widget.onShowOnlineChart(); // Call callback to show chart
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}