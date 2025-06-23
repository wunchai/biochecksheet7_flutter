// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/ui/document/document_screen.dart'; // <<< Import DocumentScreen

class HomeScreen extends StatefulWidget {
  // Constructor for HomeScreen, takes a 'title' string.
  const HomeScreen({super.key, required String title});

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
      appBar: AppBar(
        title: const Text('Home'), // Title for the Home Screen
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               // เชื่อมโยงปุ่ม Refresh กับ performFullSync()
              Provider.of<HomeViewModel>(context, listen: false).performFullSync(); // <<< แก้ไขตรงนี้
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Call logout from LoginRepository and navigate back to the login screen.
              Provider.of<LoginRepository>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Vertically center widgets in the row.
                      children: [
                        SizedBox(
                          width: 55, // Fixed width for the TextView label as per XML.
                          child: const Text(
                            "Job ID", // Placeholder for @string/textViewStr.
                            style: TextStyle(color: Colors.black, fontSize: 16.0),
                          ),
                        ),
                        const SizedBox(width: 8.0), // Space between label and TextField.
                        Expanded(
                          // TextField (Equivalent to editText5 in XML).
                          child: TextField(
                            controller: viewModel.editText5Controller, // Linked to ViewModel's controller.
                            decoration: const InputDecoration(
                              hintText: "Enter Job ID", // Placeholder for @string/editText5hit.
                              border: OutlineInputBorder(), // Adds a border around the input field.
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjusts internal padding.
                            ),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next, // Moves to the next input field on keyboard 'done'.
                          ),
                        ),
                        const SizedBox(width: 8.0), // Space before the button.
                        SizedBox(
                          width: 100, // Fixed width for the button as per XML.
                          height: 40, // Adjusted height for better visual appeal.
                          child: ElevatedButton(
                            onPressed: viewModel.onButton3Pressed, // Calls ViewModel's method on press.
                            child: const Text("Button3"), // Placeholder for @string/button3str.
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Second Search/Filter Row (Equivalent to linearLayout4 in fragment_home.xml) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50, // Fixed width for the TextView label as per XML.
                          child: const Text(
                            "Unit", // Placeholder for @string/txUnitStr.
                            style: TextStyle(color: Colors.black, fontSize: 16.0),
                          ),
                        ),
                        // Increased spacing here to make this TextField visually distinct/offset from the first one.
                        const SizedBox(width: 18.0), // More space to create a visual offset.
                        Expanded(
                          // TextField (Equivalent to editText6 in XML).
                          child: TextField(
                            controller: viewModel.editText6Controller, // Linked to ViewModel's controller.
                            decoration: const InputDecoration(
                              hintText: "Enter Unit", // Placeholder for @string/editText6hit.
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            ),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done, // Closes keyboard on 'done'.
                          ),
                        ),
                        const SizedBox(width: 8.0), // Space before the button.
                        SizedBox(
                          width: 100, // Fixed width for the button as per XML.
                          height: 40, // Adjusted height for better visual appeal.
                          child: ElevatedButton(
                            onPressed: viewModel.onButton4Pressed, // Calls ViewModel's method on press.
                            child: const Text("Button4"), // Placeholder for @string/button4str.
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Search Button Row (Equivalent to linearLayout5 in fragment_home.xml) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      height: 48, // Fixed height for the container as per XML.
                      color: Colors.deepPurple, // Background color (assuming purple_200 is deepPurple).
                      alignment: Alignment.center, // Centers the child (button) within this container.
                      child: SizedBox(
                        width: 320, // Fixed width for the button as per XML.
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading // Disable button if ViewModel is in loading state.
                              ? null
                              : viewModel.applyFilters, // Calls ViewModel's method to apply filters.
                          child: const Text("Search"), // Placeholder for @string/button2str.
                        ),
                      ),
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
    );
  }
}
