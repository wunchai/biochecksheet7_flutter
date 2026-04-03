// lib/presentation/screens/draft_job/draft_machine_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/draft_job/draft_job_viewmodel.dart';

class DraftMachineListScreen extends StatelessWidget {
  final int jobId;
  final String jobName;

  const DraftMachineListScreen({super.key, required this.jobId, required this.jobName});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DraftJobViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Machines: $jobName'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<List<DbDraftMachine>>(
        stream: viewModel.watchMachines(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final machines = snapshot.data ?? [];
          if (machines.isEmpty) {
            return const Center(
              child: Text('No machines added yet.\nTap + to add one.', textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final machine = machines[index];
              return _buildMachineCard(context, machine, viewModel);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddMachineDialog(context, viewModel, jobId);
        },
      ),
    );
  }

  Widget _buildMachineCard(BuildContext context, DbDraftMachine machine, DraftJobViewModel viewModel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: const Icon(Icons.precision_manufacturing, color: Colors.teal),
        ),
        title: Text('${machine.machineId} : ${machine.machineName ?? 'Unnamed'}', 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Tap to manage Tags'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteMachine(context, machine, viewModel),
        ),
        onTap: () {
          Navigator.pushNamed(context, '/draft_tag_list', arguments: {
            'jobId': jobId,
            'machineId': machine.uid,
            'machineName': machine.machineName ?? 'Unnamed',
          });
        },
      ),
    );
  }

  void _showAddMachineDialog(BuildContext context, DraftJobViewModel viewModel, int jobId) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Machine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Machine Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await viewModel.addMachine(jobId, nameCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMachine(BuildContext context, DbDraftMachine machine, DraftJobViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Machine?'),
        content: const Text('Are you sure you want to delete this machine and all its tags?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              viewModel.deleteMachine(machine.uid);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
