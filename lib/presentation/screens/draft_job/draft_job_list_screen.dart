// lib/presentation/screens/draft_job/draft_job_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/draft_job/draft_job_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DraftJobListScreen extends StatefulWidget {
  const DraftJobListScreen({super.key});

  @override
  State<DraftJobListScreen> createState() => _DraftJobListScreenState();
}

class _DraftJobListScreenState extends State<DraftJobListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DraftJobViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Jobs (Draft)'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Drafts from Server',
            onPressed: () => _downloadDrafts(context, viewModel),
          ),
        ],
      ),
      body: StreamBuilder<List<DbDraftJob>>(
        stream: viewModel.allDraftJobs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allJobs = snapshot.data ?? [];
          final jobs = allJobs.where((job) {
            final query = _searchQuery.toLowerCase();
            return (job.jobName?.toLowerCase().contains(query) ?? false) ||
                   (job.location?.toLowerCase().contains(query) ?? false) ||
                   (job.machineName?.toLowerCase().contains(query) ?? false);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              if (jobs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No custom jobs found.\nTap + to create one.', textAlign: TextAlign.center),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _buildJobCard(context, job, viewModel);
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
        onPressed: () {
          _showCreateJobDialog(context, viewModel);
        },
      ),
    );
  }

  void _downloadDrafts(BuildContext context, DraftJobViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await viewModel.syncFromApi();
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildJobCard(BuildContext context, DbDraftJob job, DraftJobViewModel viewModel) {
    // กรณี userId เป็น null ให้บันทึก userId ปัจจุบันเข้าไป (Fire and forget)
    if (job.userId == null) {
      viewModel.fixUserIdIfNull(job.uid);
    }

    String dateStr = job.createDate ?? '';
    if (dateStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(dateStr);
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
      } catch (_) {}
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.description, color: Colors.indigo),
        ),
        title: Text(job.jobName ?? 'Untitled Job', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('ผู้สร้าง: ${job.userId ?? "กำลังอัปเดต..."}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
            Text('Location: ${job.location}'),
            if (job.machineName != null && job.machineName!.isNotEmpty)
              Text('Machine: ${job.machineName}', style: const TextStyle(color: Colors.brown)),
            if (job.documentId != null && job.documentId!.isNotEmpty)
              Text('Doc ID: ${job.documentId}', style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 4),
            Text('Created: $dateStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Version: ${job.recordVersion}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              tooltip: 'Edit Job',
              onPressed: () => _showEditJobDialog(context, job, viewModel),
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload, color: Colors.blue),
              tooltip: 'Sync Job to API',
              onPressed: () => _syncJob(context, job, viewModel),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Job',
              onPressed: () => _confirmDeleteJob(context, job, viewModel),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, '/draft_machine_list', arguments: {
            'jobId': job.uid,
            'jobName': job.jobName ?? 'Untitled',
          });
        },
      ),
    );
  }

  void _showCreateJobDialog(BuildContext context, DraftJobViewModel viewModel) {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final machineCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Job Name *')),
              const SizedBox(height: 16),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location *')),
              const SizedBox(height: 16),
              TextField(controller: machineCtrl, decoration: const InputDecoration(labelText: 'Machine Name (Optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && locCtrl.text.isNotEmpty) {
                await viewModel.createNewJob(
                  jobName: nameCtrl.text, 
                  location: locCtrl.text,
                  machineName: machineCtrl.text.isEmpty ? null : machineCtrl.text,
                  documentId: const Uuid().v4(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields (*)')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteJob(BuildContext context, DbDraftJob job, DraftJobViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job?'),
        content: const Text('Are you sure you want to delete this job? It will also be deleted from the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAndSyncJob(context, job, viewModel);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteAndSyncJob(BuildContext context, DbDraftJob job, DraftJobViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        viewModel.deleteJobAndSync(job.uid).then((_) {
          if (ctx.mounted) {
            Navigator.pop(ctx); // Close dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job deleted successfully!'), backgroundColor: Colors.green)
            );
          }
        }).catchError((e) {
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red)
            );
          }
        });

        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Text('Deleting from server...'),
            ],
          ),
        );
      },
    );
  }

  void _showEditJobDialog(BuildContext context, DbDraftJob job, DraftJobViewModel viewModel) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: job.jobName);
    final locCtrl = TextEditingController(text: job.location);
    final machineCtrl = TextEditingController(text: job.machineName);
    final docIdCtrl = TextEditingController(text: job.documentId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Custom Job'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Job Name *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locCtrl,
                    decoration: const InputDecoration(labelText: 'Location *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: machineCtrl,
                    decoration: const InputDecoration(labelText: 'Machine Name (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await viewModel.updateJobDetails(
                    draftJobId: job.uid,
                    jobName: nameCtrl.text.trim(),
                    location: locCtrl.text.trim(),
                    machineName: machineCtrl.text.trim(),
                    documentId: job.documentId, // Keep original document ID
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _syncJob(BuildContext context, DbDraftJob job, DraftJobViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        viewModel.syncJobToApi(job.uid).then((_) {
          if (ctx.mounted) {
            Navigator.pop(ctx); // Close dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sync to API successful!'), backgroundColor: Colors.green)
            );
          }
        }).catchError((e) {
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red)
            );
          }
        });

        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Text('Syncing to API...'),
            ],
          ),
        );
      },
    );
  }
}
