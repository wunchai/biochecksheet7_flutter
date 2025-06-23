// lib/ui/document/document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/document/document_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // For DbDocument
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

/// Equivalent to DocumentActivity.kt in the original Kotlin project.
/// This screen displays a list of documents, managed by DocumentViewModel.
class DocumentScreen extends StatefulWidget {
  final String title; // Title for the app bar.
  final String? jobId; // Optional: Pass jobId to filter documents associated with a specific job.

  const DocumentScreen({super.key, required this.title, this.jobId});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule a callback for after the first frame is rendered.
    // This ensures the ViewModel's data loading is triggered only after the widget is fully initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access the DocumentViewModel and trigger data loading, passing the jobId if available.
      // listen: false because we are only calling a method, not listening for rebuilds here.
      Provider.of<DocumentViewModel>(context, listen: false).loadDocuments(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Display the screen title from widget property.
        actions: [
          // Refresh button in the AppBar.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a data refresh when the refresh button is pressed.
              Provider.of<DocumentViewModel>(context, listen: false).refreshDocuments();
            },
          ),
          // TODO: Add a search icon here if search functionality is implemented for documents.
          /*
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Example: Show a search bar or navigate to a search-specific screen.
              print('Search icon pressed on Document Screen');
            },
          ),
          */
        ],
      ),
      body: Consumer<DocumentViewModel>(
        // Consumer widget listens to changes in DocumentViewModel and rebuilds its builder.
        builder: (context, viewModel, child) {
          return Stack(
            // Stack allows placing widgets on top of each other, used here for the loading overlay.
            children: [
              Column(
                // Main column to arrange UI elements vertically.
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Padding around the status message text.
                    child: Text(
                      viewModel.statusMessage, // Display a status message from the ViewModel.
                      style: Theme.of(context).textTheme.headlineSmall, // Apply a heading style.
                      textAlign: TextAlign.center, // Center-align the text.
                    ),
                  ),
                  Expanded(
                    // Expanded widget ensures the ListView takes up the remaining vertical space.
                    child: StreamBuilder<List<DbDocument>>(
                      // StreamBuilder listens to the documentsStream from the ViewModel.
                      stream: viewModel.documentsStream,
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          // Show a circular progress indicator if data is initially loading.
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // Displays an error message if the stream encounters an error.
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          // Displays a message if no document data is available.
                          return const Center(child: Text('No documents found.'));
                        } else {
                          // If data is available, build the list of documents.
                          final documents = snapshot.data!;
                          return ListView.builder(
                            itemCount: documents.length, // Number of documents in the list.
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Padding for the entire list.
                            itemBuilder: (context, index) {
                              final document = documents[index]; // Get the current document item.
                              // Each document is displayed as a Card, conceptually similar to document_fragment_item.xml.
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0), // Vertical margin between cards.
                                elevation: 4.0, // Adds a shadow effect to the card.
                                child: InkWell(
                                  // InkWell provides a visual ripple effect when the card is tapped.
                                  onTap: () {
                                    // TODO: Implement navigation to DocumentRecordScreen for this document.
                                    // You would typically pass the document's ID or relevant data to the next screen.
                                    print('Document Tapped: ${document.documentName}');
                                    // Example Navigation:
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => DocumentRecordScreen(documentId: document.documentId),
                                    //   ),
                                    // );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0), // Internal padding of the card content.
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left).
                                      children: [
                                        Text(
                                          document.documentName ?? 'N/A', // Display document name.
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Bold title.
                                        ),
                                        const SizedBox(height: 4.0), // Small vertical space.
                                        Text('Document ID: ${document.documentId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // Display document ID.
                                        Text('Job ID: ${document.jobId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // Display associated job ID.
                                        Text('User ID: ${document.userId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // Display user who created/modified.
                                        Text('Create Date: ${document.createDate ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // Display creation date.
                                        Text('Status: ${document.status ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // Display document status.
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
              // Loading overlay that appears on top of the content when isLoading is true.
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5), // Semi-transparent black background.
                  alignment: Alignment.center, // Centers the loading spinner.
                  child: const CircularProgressIndicator(), // The actual loading spinner.
                ),
            ],
          );
        },
      ),
    );
  }
}
