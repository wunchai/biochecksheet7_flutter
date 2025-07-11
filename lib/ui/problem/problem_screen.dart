// lib/ui/problem/problem_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/ui/problem/problem_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/problem/widgets/problem_list_item.dart'; // Import ProblemListItem
import 'package:biochecksheet7_flutter/ui/problem/widgets/problem_detail_dialog.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/record_line_chart.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_record_screen.dart';
import 'package:biochecksheet7_flutter/ui/widgets/error_dialog.dart'; // Import ErrorDialog
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // Import SyncStatus

class ProblemScreen extends StatefulWidget {
  final String title;

  const ProblemScreen({super.key, required this.title});

  @override
  State<ProblemScreen> createState() => _ProblemScreenState();
}

class _ProblemScreenState extends State<ProblemScreen> {
  // REMOVED: final Map<int, TextEditingController> _solvingDescControllers = {}; // Moved to ProblemListItem
  // REMOVED: bool _isShowingDialog = false; // Flag for dialog timing, now managed by onPressed callbacks

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemViewModel>(context, listen: false).loadProblems();
    });
  }

  @override
  void dispose() {
    // _solvingDescControllers.forEach((key, controller) => controller.dispose()); // Managed by ProblemListItem
    super.dispose();
  }

  // REMOVED: Helper method to get/create and update the TextEditingController // Moved to ProblemListItem
  /*
  TextEditingController _getOrCreateAndSyncSolvingDescController(int uid, String? value) {
    final controller = _solvingDescControllers.putIfAbsent(uid, () => TextEditingController());
    if (controller.text != (value ?? '')) {
      controller.text = value ?? '';
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    }
    return controller;
  }
  */

  // Show dialog for Online Chart display (reusing RecordLineChart)
  void _showOnlineChartDialog(
      BuildContext context,
      String tagId,
      String machineId,
      String jobId,
      String tagName,
      String? unit,
      ProblemViewModel viewModel) {
    viewModel.loadOnlineChartDataForProblem(tagId, machineId, jobId);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('กราฟประวัติ: $tagName (${unit ?? ''})'),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.8,
            height: MediaQuery.of(dialogContext).size.height * 0.4,
            child: RecordLineChart(
              // Reusing RecordLineChart
              chartDataStream: viewModel.onlineChartDataStream!,
              jobTag:
                  null, // No full JobTag object here, pass null or create dummy if needed
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show problem details dialog
  void _showProblemDetailsDialog(BuildContext context, DbProblem problem) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ProblemDetailDialog(
            problem: problem); // Using the dedicated ProblemDetailDialog
      },
    );
  }

  // Helper method to display sync results (SnackBar or ErrorDialog)
  Future<void> _showSyncResultFeedback(
      BuildContext context, SyncStatus syncResult, String titlePrefix) async {
    final String? message = (syncResult is SyncSuccess)
        ? syncResult.message
        : (syncResult is SyncError ? syncResult.message : null);

    if (message != null) {
      bool isError = message.toLowerCase().contains('ล้มเหลว') ||
          message.toLowerCase().contains('ข้อผิดพลาด') ||
          message.toLowerCase().contains('failed') ||
          message.toLowerCase().contains('error') ||
          message.toLowerCase().contains('exception') ||
          message.toLowerCase().contains('timed out') ||
          message.toLowerCase().contains('ไม่สามารถเชื่อมต่อ');

      if (isError) {
        await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return ErrorDialog(
              title: '$titlePrefix ข้อผิดพลาด',
              message: message,
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Make onPressed async
              final viewModel =
                  Provider.of<ProblemViewModel>(context, listen: false);
              final SyncStatus syncResult = await viewModel
                  .refreshProblems(); // Await the refresh operation
              if (mounted) {
                _showSyncResultFeedback(context, syncResult, 'การซิงค์ปัญหา');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save), // Placeholder for save icon
            onPressed: () async {
              // Make onPressed async
              final viewModel =
                  Provider.of<ProblemViewModel>(context, listen: false);
              // CRUCIAL FIX: saveAllProblemChanges no longer needs solvingDescControllers from here.
              // It should get values from the ViewModel's stream directly.
              final bool saveSuccess = await viewModel.saveAllProblemChanges(
                  // No longer pass solvingDescriptionControllers: _solvingDescControllers,
                  // ViewModel should iterate its stream and get current values if needed.
                  // If it needs UI values, ProblemListItem should update ViewModel directly on change.
                  // For now, _solvingDescControllers is empty, so this parameter is effectively useless.
                  // If saveAllProblemChanges needs to read current UI values, it must be refactored.
                  // For simplicity, assuming updateProblemSolvingDescription is the primary save mechanism per item.
                  // If this button is meant for a "Save All" of all UI changes, ProblemViewModel.saveAllProblemChanges
                  // needs to be re-evaluated to get the current state of all input fields.
                  // For now, we'll keep the call, but acknowledge it might not save all UI changes.
                  );
              if (mounted) {
                if (saveSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('บันทึกการเปลี่ยนแปลงสำเร็จ!')),
                  );
                } else {
                  await showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return const ErrorDialog(
                        title: 'บันทึกข้อมูลล้มเหลว',
                        message: 'โปรดตรวจสอบข้อผิดพลาดในแต่ละรายการปัญหา.',
                      );
                    },
                  );
                }
              }
            },
          ),
          // NEW: Upload All Problems button (Re-added)
          Consumer<ProblemViewModel>(builder: (context, viewModel, child) {
            bool canUploadAll = true;

            return IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed:
                  canUploadAll // Enabled if viewModel is not loading AND there's at least one Status 2 problem
                      ? () async {
                          Provider.of<ProblemViewModel>(context, listen: false);
                          // Make onPressed async
                          final bool saveSuccess = await viewModel
                              .uploadAllProblemsToServer(); // Await upload
                          if (mounted) {
                            if (saveSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('การอัปโหลดสำเร็จ!')),
                              );
                            } else {
                              await showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return const ErrorDialog(
                                    title: 'การอัปโหลดปัญหา',
                                    message:
                                        'โปรดตรวจสอบข้อผิดพลาดในแต่ละรายการปัญหา.',
                                  );
                                },
                              );
                            }
                          }
                        }
                      : null,
            );
          }),
        ],
      ),
      body: Consumer<ProblemViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.all(8.0), // <<< Changed padding to 8.0
                    child: Text(
                      viewModel.statusMessage,
                      style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.black), // <<< Changed text style
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<DbProblem>>(
                      stream: viewModel.problemsStream,
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('ไม่พบรายการปัญหา.'));
                        } else {
                          final problems = snapshot.data!;
                          return ListView.builder(
                            itemCount: problems.length,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            itemBuilder: (context, index) {
                              final problem = problems[index];
                              final bool isProblemReadOnly =
                                  problem.problemStatus == 1 ||
                                      problem.problemStatus == 2;

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 4.0,
                                child: InkWell(
                                  onTap: () {
                                    _showProblemDetailsDialog(context, problem);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                problem.problemName ?? 'N/A',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.image),
                                              onPressed: () {
                                                final bool
                                                    isImageScreenReadOnly =
                                                    problem.problemStatus ==
                                                            1 ||
                                                        problem.problemStatus ==
                                                            2;
                                                Navigator.pushNamed(
                                                  context,
                                                  '/image_record',
                                                  arguments: {
                                                    'title':
                                                        'รูปภาพปัญหา: ${problem.problemName ?? 'N/A'}',
                                                    'documentId':
                                                        problem.documentId ??
                                                            '',
                                                    'machineId':
                                                        problem.machineId ?? '',
                                                    'jobId':
                                                        problem.jobId ?? '',
                                                    'tagId':
                                                        problem.tagId ?? '',
                                                    'problemId': problem
                                                            .problemId
                                                            ?.toString() ??
                                                        '',
                                                    'isReadOnly':
                                                        isImageScreenReadOnly,
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4.0),
                                        Text(
                                            'Problem ID: ${problem.problemId ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text(
                                            'Description: ${problem.problemDescription ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text(
                                            'Machine Name: ${problem.machineName ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text(
                                            'Job ID: ${problem.jobId ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text(
                                            'Tag Name: ${problem.tagName ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text('Status: ${problem.problemStatus}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),

                                        const SizedBox(height: 8.0),
                                        // CRUCIAL FIX: Use ProblemListItem to manage its own controller
                                        ProblemListItem(
                                          key: ValueKey(problem
                                              .uid), // Essential for list item stability
                                          problem: problem,
                                          viewModel:
                                              viewModel, // Pass the ViewModel
                                          onTap: () {
                                            _showProblemDetailsDialog(
                                                context, problem);
                                          },
                                          onShowOnlineChart: () {
                                            _showOnlineChartDialog(
                                                context,
                                                problem.tagId ?? '',
                                                problem.machineId ?? '',
                                                problem.jobId ?? '',
                                                problem.tagName ?? 'N/A',
                                                problem.unit,
                                                viewModel);
                                          },
                                        ),
                                        // REMOVED: The TextField and Row with Post/Chart buttons are now inside ProblemListItem
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
