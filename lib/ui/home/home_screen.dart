// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/ui/document/document_screen.dart'; // <<< Import DocumentScreen
import 'package:biochecksheet7_flutter/ui/home/widgets/home_app_bar.dart'; // <<< NEW: Import HomeAppBar
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_screen.dart'; // <<< NEW: Import DeviceInfoScreen

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          // NEW: Use HomeAppBar
      appBar: HomeAppBar(
        title: widget.title,
        searchController: TextEditingController(), // Pass a new controller for HomeAppBar
        onRefreshPressed: () {
          Provider.of<HomeViewModel>(context, listen: false).refreshJobs();
        },
        onUploadPressed: () {
          Provider.of<HomeViewModel>(context, listen: false).uploadAllDocumentRecords();
        },
        onLogoutPressed: () {
          Provider.of<HomeViewModel>(context, listen: false).logout(context);
        },
      ),
      body: Consumer<HomeViewModel>(
        // Consumer rebuilds its child when HomeViewModel changes.
        builder: (context, viewModel, child) {
           // Show SnackBar for sync messages from HomeViewModel
          if (viewModel.syncMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.syncMessage!)),
              );
              // Clear the message after showing to prevent repeat
              viewModel.syncMessage = null; // ต้องมี setter ใน ViewModel หรือเปลี่ยนเป็น method
              // หรือ: ใช้ Provider.of<HomeViewModel>(context, listen: false).clearSyncMessage();
            });
          }
          return Stack(
            // Stack allows placing widgets on top of each other, used for the loading overlay.
            children: [
              Column(
                // Main column to arrange UI elements vertically.
                children: [
                  // --- First Search/Filter Row (Equivalent to linearLayout3 in fragment_home.xml) ---
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.statusMessage,
                      style: Theme.of(context).textTheme.headlineSmall,
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
                        if (snapshot.connectionState == ConnectionState.waiting && !viewModel.isLoading) {
                          // Show a circular progress indicator only for the initial load,
                          // subsequent filter changes will use the overlay ProgressBar.
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // Displays an error message if the stream encounters an error.
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          // Displays a message if no job data is available.
                          return const Center(child: Text('No jobs found.'));
                        } else {
                          // If data is available, build the list of jobs.
                          final jobs = snapshot.data!;
                          return ListView.builder(
                            itemCount: jobs.length,
                            // Adjust padding to match layout_marginLeft/Right from XML.
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                            itemBuilder: (context, index) {
                              final job = jobs[index];
                              return Card(
                                // Adjusted card margins for better visual spacing.
                                margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                                elevation: 4.0, // Adds a shadow effect.
                                child: InkWell(
                                  // Provides a visual ripple effect on tap.
                                   onTap: () {
                                    // Navigate to DocumentScreen when Job item is tapped
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DocumentScreen(
                                          title: 'Documents for Job: ${job.jobId ?? ''}', // Dynamic title
                                          jobId: job.jobId, // Pass jobId to DocumentScreen
                                        ),
                                      ),
                                    );
                                    print('Job Tapped: ${job.jobName}, Navigating to Documents for Job ID: ${job.jobId}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the start (left).
                                      children: [
                                        Text(
                                          job.jobName ?? 'N/A', // Displays job name, 'N/A' if null.
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Bold job name.
                                        ),
                                        const SizedBox(height: 6.0), // Space between job name and details.
                                        Text('Job ID: ${job.jobId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // Smaller text for details.
                                        Text('Machine: ${job.machineName ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Location: ${job.location ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                                        Text('Status: ${job.jobStatus ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
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
              if (viewModel.isLoading) // Only displayed when the ViewModel's isLoading is true.
                Container(
                  color: Colors.black.withOpacity(0.5), // Semi-transparent black overlay.
                  alignment: Alignment.center, // Centers the CircularProgressIndicator.
                  child: const CircularProgressIndicator(), // The actual loading spinner.
                ),
            ],
          );
        },
      ),
       // NEW: Floating Action Button for Device Info
      // NEW: Floating Action Button for Manual Metadata Sync
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position it to the right
      floatingActionButton: Column( // Use Column to stack multiple FABs
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "deviceInfoFab", // Unique tag for multiple FABs
            onPressed: () {
              Navigator.pushNamed(context, '/device_info');
            },
            child: const Icon(Icons.info_outline),
          ),
       
        ],
      ),
    );
    
  }
}
