// lib/presentation/screens/document_online/document_online_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_online_viewmodel.dart';
// Note: If you have a specific screen for opening online documents (like an online equivalent of DocumentMachineScreen),
// you would import it here. Currently binding mostly to UI display purposes.

class DocumentOnlineScreen extends StatefulWidget {
  final String title;
  final String? jobId;
  final String? userId; // Need user ID for the API call

  const DocumentOnlineScreen({super.key, required this.title, this.jobId, this.userId});

  @override
  State<DocumentOnlineScreen> createState() => _DocumentOnlineScreenState();
}

class _DocumentOnlineScreenState extends State<DocumentOnlineScreen> {
  @override
  void initState() {
    super.initState();
    // Use post frame callback to not trigger state changes during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear old data when entering screen
      Provider.of<DocumentOnlineViewModel>(context, listen: false).clearOnlineData();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final viewModel = Provider.of<DocumentOnlineViewModel>(context, listen: false);
    final initialDate = isStart ? viewModel.startDate : viewModel.endDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      if (isStart) {
        viewModel.setStartDate(picked);
      } else {
        viewModel.setEndDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<DocumentOnlineViewModel>(
        builder: (context, viewModel, child) {
          // Notifications
          if (viewModel.syncMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.syncMessage!)));
              viewModel.syncMessage = null; // show once
            });
          }
          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: Colors.red));
              viewModel.errorMessage = null; // show once
            });
          }

          return Column(
            children: [
              // Filters Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd MMM yyyy').format(viewModel.startDate)),
                                      const Icon(Icons.calendar_today, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd MMM yyyy').format(viewModel.endDate)),
                                      const Icon(Icons.calendar_today, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: viewModel.isLoading
                                ? null
                                : () {
                                    final uId = widget.userId ?? '600201'; // Fallback if null
                                    final jId = widget.jobId ?? '0';
                                    viewModel.syncOnlineData(uId, jId);
                                  },
                            icon: viewModel.isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.cloud_sync),
                            label: const Text('ดึงข้อมูลออนไลน์'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // List Section
              Expanded(
                child: StreamBuilder<List<DbDocumentOnline>>(
                  stream: viewModel.documentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่มีข้อมูลออนไลน์ในช่วงเวลาที่เลือก',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'กดปุ่ม "ดึงข้อมูลออนไลน์" เพื่อค้นหา',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    } else {
                      final documents = snapshot.data!;
                      return ListView.builder(
                        itemCount: documents.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemBuilder: (context, index) {
                          return _buildDocumentCard(context, documents[index]);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DbDocumentOnline document) {
    bool isClosed = document.status >= 2;
    Color statusColor = isClosed ? Colors.grey : Colors.green;
    String statusText = isClosed ? "Closed" : "Active";

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: statusColor, width: 6.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      document.documentName ?? 'Untitled Document',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Divider(color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 8.0),
              _buildInfoRow(Icons.event, "Created: ${_formatDate(document.createDate)}", Colors.grey[700]),
              const SizedBox(height: 4.0),
              _buildInfoRow(Icons.work_outline, "Job ID: ${document.jobId ?? '-'}", Colors.grey[700]),
              const SizedBox(height: 4.0),
              if (document.userId != null)
                _buildInfoRow(Icons.person_outline, "User: ${document.userId}", Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color? color) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: color ?? Colors.grey),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown Date";
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return isoDate;
    }
  }
}
