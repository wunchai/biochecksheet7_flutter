// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_viewmodel.dart';
//import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/presentation/screens/document/document_screen.dart'; // <<< Import DocumentScreen
import 'package:biochecksheet7_flutter/presentation/screens/home/widgets/home_app_bar.dart'; // <<< NEW: Import HomeAppBar
//import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_screen.dart'; // <<< NEW: Import DeviceInfoScreen
import 'package:biochecksheet7_flutter/presentation/widgets/error_dialog.dart'; // <<< NEW: Import ErrorDialog
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // Import SyncStatus
import 'package:biochecksheet7_flutter/presentation/widgets/sync_progress_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String title;
  // Constructor for HomeScreen, takes a 'title' string.
  const HomeScreen({super.key, this.title = 'Home'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // No explicit call to refreshJobs() here anymore.
    // The ViewModel initializes its job stream when it's created,
    // so the initial list will load automatically.
  }

  @override
  void dispose() {
    // The ViewModel manages its own controllers' disposal.
    super.dispose();
  }

  // --- <<< ฟังก์ชันใหม่สำหรับจัดการการกดปุ่ม >>> ---
  void _onSyncMasterImagesPressed(
      BuildContext context, HomeViewModel viewModel) async {
    // 1. แสดงหน้าต่าง Progress ทันที
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SyncProgressDialog(
        progressNotifier: viewModel.syncProgressNotifier,
        statusNotifier: viewModel.syncStatusNotifier,
      ),
    );

    // 2. เริ่มกระบวนการ Sync (ซึ่งจะใช้เวลา)
    final String resultMessage = await viewModel.syncMasterImages();

    // 3. เมื่อ Sync เสร็จสิ้น ให้ปิดหน้าต่าง Progress
    if (context.mounted) Navigator.of(context).pop();

    // 4. แสดงผลลัพธ์สุดท้ายด้วย SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultMessage)),
      );
    }
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
              title: 'ข้อผิดพลาดในการซิงค์/อัปโหลด',
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
        // NEW: Use HomeAppBar
        appBar: HomeAppBar(
          title: widget.title,
          searchController:
              TextEditingController(), // Pass a new controller for HomeAppBar
          onRefreshPressed: () async {
            final viewModel =
                Provider.of<HomeViewModel>(context, listen: false);
            final syncResult =
                await viewModel.refreshJobs(); // Await the refresh operation
            if (mounted) {
              _showSyncResultFeedback(context, syncResult, 'การซิงค์ปัญหา');
            }
          },
          onImagePressed: () async {
            _onSyncMasterImagesPressed(
                context, Provider.of<HomeViewModel>(context, listen: false));
          },

          onUploadPressed: () async {
            final viewModel =
                Provider.of<HomeViewModel>(context, listen: false);
            final uploadResult = await viewModel
                .uploadAllDocumentRecords(); // Await the upload operation
            if (mounted) {
              _showSyncResultFeedback(context, uploadResult, 'การซิงค์ปัญหา');
            }
          },
          onLogoutPressed: () {
            Provider.of<HomeViewModel>(context, listen: false).logout(context);
          },
        ),
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            // Consumer rebuilds its child when HomeViewModel changes.
            builder: (context, viewModel, child) {
              // CRUCIAL FIX: Handle sync messages after the dialog/snackbar is closed.
              // This ensures viewModel.syncMessage is not null when accessed by the builder.
              /*   if (viewModel.syncMessage != null) {
            final String currentSyncMessage =
                viewModel.syncMessage!; // Capture message
            final bool isError =
                currentSyncMessage.toLowerCase().contains('ล้มเหลว') ||
                    currentSyncMessage.toLowerCase().contains('ข้อผิดพลาด') ||
                    currentSyncMessage.toLowerCase().contains('failed') ||
                    currentSyncMessage.toLowerCase().contains('error') ||
                    currentSyncMessage.toLowerCase().contains('exception') ||
                    currentSyncMessage.toLowerCase().contains('timed out');
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // Make callback async
              if (mounted) {
                if (isError) {
                  await showDialog(
                    // Await the dialog to close
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return ErrorDialog(
                        title: 'ข้อผิดพลาดในการซิงค์/อัปโหลด',
                        message: currentSyncMessage, // Use captured message
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(currentSyncMessage)), // Use captured message
                  );
                  // For SnackBar, it's generally safe to clear after showing,
                  // but awaiting showSnackBar is not common.
                  // The key is that the message is captured *before* the async dialog/snackbar call.
                }
                // CRUCIAL FIX: Clear the message AFTER the dialog/snackbar has been shown and potentially closed.
                viewModel.syncMessage = null;
              }
            });
          } */
              return Stack(
                // Stack allows placing widgets on top of each other, used for the loading overlay.
                children: [
                  Column(
                    // Main column to arrange UI elements vertically.
                    children: [
                      // --- First Search/Filter Row (Equivalent to linearLayout3 in fragment_home.xml) ---
                      Padding(
                        padding: const EdgeInsets.all(
                            8.0), // <<< Changed padding to 8.0
                        child: Text(
                          viewModel.statusMessage,
                          style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.black), // <<< Changed text style
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // --- Job List (Equivalent to homelist RecyclerView in XML) ---

                      Expanded(
                        // Takes up the remaining vertical space.
                        child: StreamBuilder<List<DbJob>>(
                          // Listens to the stream of job data from the ViewModel.
                          stream: viewModel.jobsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !viewModel.isLoading) {
                              // Show a circular progress indicator only for the initial load,
                              // subsequent filter changes will use the overlay ProgressBar.
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              // Displays an error message if the stream encounters an error.
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              // Displays a message if no job data is available.
                              return const Center(
                                  child: Text('No jobs found.'));
                            } else {
                              // If data is available, build the list of jobs.
                              final jobs = snapshot.data!;
                              return ListView.builder(
                                itemCount: jobs.length,
                                // Adjust padding to match layout_marginLeft/Right from XML.
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0, vertical: 8.0),
                                itemBuilder: (context, index) {
                                  final job = jobs[index];
                                  return Card(
                                    // Adjusted card margins for better visual spacing.
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0, vertical: 6.0),
                                    elevation: 4.0, // Adds a shadow effect.
                                    child: InkWell(
                                      // Provides a visual ripple effect on tap.
                                      onTap: () {
                                        // Navigate to DocumentScreen when Job item is tapped
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DocumentScreen(
                                              title:
                                                  'Documents for Job: ${job.jobId ?? ''}', // Dynamic title
                                              jobId: job
                                                  .jobId, // Pass jobId to DocumentScreen
                                            ),
                                          ),
                                        );
                                        print(
                                            'Job Tapped: ${job.jobName}, Navigating to Documents for Job ID: ${job.jobId}');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Aligns text to the start (left).
                                          children: [
                                            Text(
                                              job.jobName ??
                                                  'N/A', // Displays job name, 'N/A' if null.
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      fontWeight: FontWeight
                                                          .bold), // Bold job name.
                                            ),
                                            const SizedBox(
                                                height:
                                                    6.0), // Space between job name and details.
                                            Text(
                                                'Job ID: ${job.jobId ?? 'N/A'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall), // Smaller text for details.
                                            Text(
                                                'Machine: ${job.machineName ?? 'N/A'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                            Text(
                                                'Location: ${job.location ?? 'N/A'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                            Text(
                                                'Status: ${job.jobStatus ?? 'N/A'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
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
                  // --- ProgressBar Overlay (Equivalent to ProgressBar in RelativeLayout in XML) ---
                  if (viewModel
                      .isLoading) // Only displayed when the ViewModel's isLoading is true.
                    Container(
                      color: Colors.black
                          .withOpacity(0.5), // Semi-transparent black overlay.
                      alignment: Alignment
                          .center, // Centers the CircularProgressIndicator.
                      child:
                          const CircularProgressIndicator(), // The actual loading spinner.
                    ),
                ],
              );
            },
          ),
        ));
  }
}
