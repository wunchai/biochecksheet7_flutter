// lib/presentation/screens/draft_job/draft_job_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/draft_job/draft_job_viewmodel.dart';
import 'package:intl/intl.dart';

class DraftJobListScreen extends StatelessWidget {
  const DraftJobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DraftJobViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Jobs (Draft)'),
        backgroundColor: Colors.indigo,
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

          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return const Center(
              child: Text('No custom jobs yet.\nTap + to create one.', textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(context, job, viewModel);
            },
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

  Widget _buildJobCard(BuildContext context, DbDraftJob job, DraftJobViewModel viewModel) {
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
            Text('Location: ${job.location}'),
            if (job.machineName != null && job.machineName!.isNotEmpty)
              Text('Machine: ${job.machineName}', style: const TextStyle(color: Colors.brown)),
            if (job.documentId != null && job.documentId!.isNotEmpty)
              Text('Doc ID: ${job.documentId}', style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 4),
            Text('Created: $dateStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    final docCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Job Name *')),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location *')),
              TextField(controller: machineCtrl, decoration: const InputDecoration(labelText: 'Machine Name (Optional)')),
              TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Document ID (Optional)')),
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
                  documentId: docCtrl.text.isEmpty ? null : docCtrl.text,
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
        content: const Text('Are you sure you want to delete this job and all its machines/tags?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              viewModel.deleteJob(job.uid);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
