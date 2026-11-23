// lib/ui/problem/problem_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/problem_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/widgets/problem_list_item.dart'; // Import ProblemListItem
import 'package:biochecksheet7_flutter/presentation/screens/problem/widgets/problem_detail_dialog.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/widgets/record_line_chart.dart';
//import 'package:biochecksheet7_flutter/ui/imagerecord/image_record_screen.dart';
import 'package:biochecksheet7_flutter/presentation/widgets/error_dialog.dart'; // Import ErrorDialog
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // Import SyncStatus

class ProblemScreen extends StatefulWidget {
  final String title;
  final String? jobId;
  final bool showAppBar;

  const ProblemScreen({
    super.key,
    required this.title,
    this.jobId,
    this.showAppBar = true,
  });

  @override
  State<ProblemScreen> createState() => _ProblemScreenState();
}

class _ProblemScreenState extends State<ProblemScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemViewModel>(context, listen: false)
          .loadProblems(jobId: widget.jobId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showJobPickerSheet(
    BuildContext context,
    List<DbJob> jobs,
    ProblemViewModel viewModel,
  ) {
    final searchController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredJobs = jobs.where((job) {
              if (query.isEmpty) return true;
              final id = (job.jobId ?? '').toLowerCase();
              final name = (job.jobName ?? '').toLowerCase();
              final machine = (job.machineName ?? '').toLowerCase();
              return id.contains(query) ||
                  name.contains(query) ||
                  machine.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Row(
                        children: [
                          Icon(Icons.work_outline, color: Colors.blue.shade900),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'เลือกงาน (Job) เพื่อกรอง Case',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่องาน, รหัส Job หรือเครื่องจักร...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: filteredJobs.length + 1,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = viewModel.currentJobId == null;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Colors.blue.shade900
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.all_inclusive,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                              title: const Text(
                                'ทุกงาน (ทั้งหมด)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle:
                                  Text('แสดง Case จากทุกใบงาน (${jobs.length} งาน)'),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle,
                                      color: Colors.blue.shade900)
                                  : null,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                viewModel.selectJob(null);
                              },
                            );
                          }

                          final job = filteredJobs[index - 1];
                          final jobIdStr = job.jobId ?? '';
                          final isSelected =
                              viewModel.currentJobId == jobIdStr;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.blue.shade50,
                              child: Text(
                                jobIdStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.blue.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            title: Text(
                              job.jobName ?? 'Job $jobIdStr',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: (job.machineName != null &&
                                    job.machineName!.isNotEmpty)
                                ? Text(
                                    'Job $jobIdStr · ${job.machineName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text('Job $jobIdStr'),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: Colors.blue.shade900)
                                : null,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              viewModel.selectJob(jobIdStr);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  Widget _buildJobFilterBar(BuildContext context, ProblemViewModel viewModel) {
    return StreamBuilder<List<DbJob>>(
      stream: viewModel.jobsStream,
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <DbJob>[];
        DbJob? selectedJob;
        if (viewModel.currentJobId != null) {
          for (final j in jobs) {
            if (j.jobId == viewModel.currentJobId) {
              selectedJob = j;
              break;
            }
          }
        }

        final String displayTitle;
        final String? displaySubtitle;
        if (viewModel.currentJobId == null) {
          displayTitle = 'ทุกงาน (ทั้งหมด)';
          displaySubtitle = 'แตะเพื่อเลือกกรองเฉพาะใบงาน (${jobs.length} งาน)';
        } else if (selectedJob != null) {
          displayTitle =
              '${selectedJob.jobId} · ${selectedJob.jobName ?? 'Job ${selectedJob.jobId}'}';
          displaySubtitle = selectedJob.machineName;
        } else {
          displayTitle = 'Job ${viewModel.currentJobId}';
          displaySubtitle = null;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: viewModel.currentJobId != null
                  ? Colors.blue.shade700
                  : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showJobPickerSheet(context, jobs, viewModel),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: Colors.blue.shade900,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ใบงาน (Job)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (displaySubtitle != null &&
                            displaySubtitle.isNotEmpty)
                          Text(
                            displaySubtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (viewModel.currentJobId != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'แสดงทุกงาน',
                      color: Colors.grey.shade600,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => viewModel.selectJob(null),
                    ),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'ซิงค์รายการ Case จากเซิร์ฟเวอร์',
                  onPressed: () async {
                    final viewModel =
                        Provider.of<ProblemViewModel>(context, listen: false);
                    final SyncStatus syncResult =
                        await viewModel.refreshProblems();
                    if (!mounted) return;
                    _showSyncResultFeedback(
                        context, syncResult, 'การซิงค์ปัญหา');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'บันทึกการเปลี่ยนแปลงทั้งหมด',
                  onPressed: () async {
                    final viewModel =
                        Provider.of<ProblemViewModel>(context, listen: false);
                    final bool saveSuccess =
                        await viewModel.saveAllProblemChanges();
                    if (!mounted) return;
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
                            message:
                                'โปรดตรวจสอบข้อผิดพลาดในแต่ละรายการปัญหา.',
                          );
                        },
                      );
                    }
                  },
                ),
                Consumer<ProblemViewModel>(builder: (context, viewModel, child) {
                  return IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    tooltip: 'อัปโหลด Case ทั้งหมด',
                    onPressed: () async {
                      final bool saveSuccess =
                          await viewModel.uploadAllProblemsToServer();
                      if (!mounted) return;
                      if (saveSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('การอัปโหลดสำเร็จ!')),
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
                    },
                  );
                }),
              ],
            )
          : null,
      body: Consumer<ProblemViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Column(
                children: [
                  _buildJobFilterBar(context, viewModel),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    child: Text(
                      viewModel.statusMessage,
                      style: TextStyle(
                          fontSize: 12.0, color: Colors.grey.shade700),
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
                              // REMOVED unused isProblemReadOnly variable

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
                                                problem.tagName ?? 'N/A',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.description,
                                                      color: Colors.blue),
                                                  tooltip: 'เปิดเอกสาร',
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/document_online',
                                                      arguments: {
                                                        'title': problem
                                                                .problemName ??
                                                            'Document Online',
                                                        'jobId': problem.jobId
                                                            ?.toString(),
                                                        'userId': '000000',
                                                        'documentId': problem
                                                            .documentId
                                                            ?.toString(),
                                                        'machineId': problem
                                                            .machineId
                                                            ?.toString(),
                                                      },
                                                    );
                                                  },
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
                                                        'documentId': problem
                                                                .documentId ??
                                                            '',
                                                        'machineId':
                                                            problem.machineId ??
                                                                '',
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
                                            'Machine / Process: ${problem.machineName ?? 'N/A'}',
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
