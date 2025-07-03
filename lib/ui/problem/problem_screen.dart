// lib/ui/problem/problem_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/ui/problem/problem_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem
import 'package:biochecksheet7_flutter/ui/problem/widgets/problem_list_item.dart';
import 'package:biochecksheet7_flutter/ui/problem/widgets/problem_detail_dialog.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/widgets/record_line_chart.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_record_screen.dart'; // <<< NEW: Import ImageRecordScreen


/// หน้าจอนี้แสดงรายการปัญหาที่ดึงมาจาก DbProblem.
/// จะมาแทนที่ Dashboard Screen ใน Bottom Navigation Bar.
class ProblemScreen extends StatefulWidget {
  final String title;
  const ProblemScreen({super.key, required this.title});

  @override
  State<ProblemScreen> createState() => _ProblemScreenState();
}

class _ProblemScreenState extends State<ProblemScreen> {
  final Map<int, TextEditingController> _solvingDescControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemViewModel>(context, listen: false).loadProblems();
    });
  }

  @override
  void dispose() {
    _solvingDescControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Helper method to get/create and update the TextEditingController for solvingDescription.
  TextEditingController _getOrCreateAndSyncSolvingDescController(int uid, String? value) {
    final controller = _solvingDescControllers.putIfAbsent(uid, () => TextEditingController());
    if (controller.text != (value ?? '')) {
      controller.text = value ?? '';
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    }
    return controller;
  }

  // Show dialog for Online Chart display (reusing RecordLineChart)
  void _showOnlineChartDialog(BuildContext context, String tagId, String machineId, String jobId, String tagName, String? unit, ProblemViewModel viewModel) {
    viewModel.loadOnlineChartDataForProblem(tagId, machineId, jobId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('กราฟประวัติ: $tagName (${unit ?? ''})'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.4,
            child: RecordLineChart(
              chartDataStream: viewModel.onlineChartDataStream!,
              jobTag: null,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
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
      builder: (BuildContext context) {
        return ProblemDetailDialog(problem: problem);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProblemViewModel>(context, listen: false).refreshProblems();
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final viewModel = Provider.of<ProblemViewModel>(context, listen: false);
              viewModel.saveAllProblemChanges(
                solvingDescriptionControllers: _solvingDescControllers,
              );
            },
          ),
             // NEW: Upload All Problems button
          Consumer<ProblemViewModel>(builder: (context, viewModel, child) {
            bool canUploadAll = true;
            if (viewModel.isLoading) {
              canUploadAll = false;
            }
            // Check records to see if any are status 2 and not loading
            viewModel.problemsStream?.first.then((problems) {
              bool anyStatus2 = problems.any((p) => p.problemStatus == 2);
              if (mounted && canUploadAll != anyStatus2) { // Only update if state changes
                setState(() {
                  canUploadAll = anyStatus2; // Enable only if there's at least one status 2
                });
              }
            });
            return IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: canUploadAll // Enabled if viewModel is not loading AND there's at least one Status 2 problem
                  ? () {
                      viewModel.uploadAllProblemsToServer();
                    }
                  : null,
            );
          }),
        ],
      ),
      body: Consumer<ProblemViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.syncMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.syncMessage!)),
              );
              viewModel.syncMessage = null;
            });
          }

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.statusMessage,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<DbProblem>>(
                      stream: viewModel.problemsStream,
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('ไม่พบรายการปัญหา.'));
                        } else {
                          final problems = snapshot.data!;
                          return ListView.builder(
                            itemCount: problems.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            itemBuilder: (context, index) {
                              final problem = problems[index];
                              final bool isProblemReadOnly = problem.problemStatus == 1 || problem.problemStatus == 2;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 4.0,
                                child: InkWell(
                                  onTap: () {
                                    _showProblemDetailsDialog(context, problem);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row( // Use Row to place Problem Name and Image button side by side
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                problem.problemName ?? 'N/A',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            // NEW: Image Button for Problem
                                            IconButton(
                                              icon: const Icon(Icons.image),
                                              onPressed:() { // Disable if read-only
                                               final bool isImageScreenReadOnly = problem.problemStatus == 1 || problem.problemStatus == 2; // <<< NEW: Calculate isReadOnly for ImageScreen
                                                 print('ProblemScreen: Image button pressed for Problem ID: "${problem.problemId}", Tag ID: "${problem.tagId}"'); // <<< Debugging
                                               
                                                // Navigate to ImageRecordScreen, passing all relevant IDs
                                                Navigator.pushNamed(
                                                  context,
                                                  '/image_record',
                                                  arguments: {
                                                    'title': 'รูปภาพปัญหา: ${problem.problemName ?? 'N/A'}',
                                                    'documentId': problem.documentId ?? '', 
                                                    'machineId': problem.machineId ?? '',
                                                    'jobId': problem.jobId ?? '',
                                                    'tagId': problem.tagId ?? '',
                                                    'problemId': problem.problemId?.toString(), // <<< CRUCIAL FIX: Convert to String
                                                    'isReadOnly': isImageScreenReadOnly, // <<< NEW: Pass isReadOnly
                                                  },
                                                );
                                                print('Image button pressed for Problem ID: ${problem.problemId}');
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text('Problem ID: ${problem.problemId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Description: ${problem.problemDescription ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Machine Name: ${problem.machineName ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Doc ID: ${problem.documentId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Job ID: ${problem.jobId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Tag Name: ${problem.tagName ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Status: ${problem.problemStatus}', style: Theme.of(context).textTheme.bodySmall),

                                        const SizedBox(height: 8.0),
                                        // Input field for problemSolvingDescription
                                        TextField(
                                          controller: _getOrCreateAndSyncSolvingDescController(problem.uid, problem.problemSolvingDescription),
                                          enabled: !isProblemReadOnly,
                                          readOnly: isProblemReadOnly,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            labelText: 'คำอธิบายการแก้ไข',
                                            hintText: isProblemReadOnly ? 'ไม่สามารถแก้ไขได้' : 'ป้อนคำอธิบายการแก้ไข',
                                            border: const OutlineInputBorder(),
                                            errorText: viewModel.problemErrors[problem.uid],
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.check),
                                              onPressed: isProblemReadOnly ? null : () {
                                                viewModel.updateProblemSolvingDescription(problem.uid, _solvingDescControllers[problem.uid]?.text);
                                              },
                                            ),
                                          ),
                                        ),
                                        // Action buttons (Post, Online Chart)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Post button
                                            TextButton(
                                              onPressed: (viewModel.isLoading || isProblemReadOnly || problem.problemStatus != 0) ? null : () {
                                                // CRUCIAL FIX: Pass current text from controller to postProblem
                                                viewModel.postProblem(problem.uid, _solvingDescControllers[problem.uid]?.text); // <<< เปลี่ยนตรงนี้
                                              },
                                              child: const Text('ส่งข้อมูล'),
                                            ),
                                            // Online Chart button (if tagType is Number)
                                            if (problem.tagType == 'Number')
                                              IconButton(
                                                icon: const Icon(Icons.history),
                                                onPressed: () {
                                                  _showOnlineChartDialog(context, problem.tagId ?? '', problem.machineId ?? '', problem.jobId ?? '', problem.tagName ?? 'N/A', problem.unit, viewModel);
                                                },
                                              ),
                                          ],
                                        ),
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
              // Loading overlay
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