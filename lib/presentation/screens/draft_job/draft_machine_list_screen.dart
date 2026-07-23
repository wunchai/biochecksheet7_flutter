// lib/presentation/screens/draft_job/draft_machine_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/draft_job/draft_job_viewmodel.dart';

class DraftMachineListScreen extends StatefulWidget {
  final String jobId;
  final String jobName;

  const DraftMachineListScreen({super.key, required this.jobId, required this.jobName});

  @override
  State<DraftMachineListScreen> createState() => _DraftMachineListScreenState();
}

class _DraftMachineListScreenState extends State<DraftMachineListScreen> {
  bool _showDeleted = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DraftJobViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Machines: ${widget.jobName}'),
        backgroundColor: Colors.indigo,
        actions: [
          Row(
            children: [
              const Text('Show Deleted', style: TextStyle(fontSize: 12)),
              Switch(
                value: _showDeleted,
                onChanged: (val) {
                  setState(() {
                    _showDeleted = val;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<DbDraftMachine>>(
        stream: viewModel.watchMachines(widget.jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var machines = snapshot.data ?? [];
          
          // Filter deleted items
          if (!_showDeleted) {
            machines = machines.where((m) => m.status != 4).toList();
          }

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
              return _buildMachineCard(context, machine, viewModel, widget.jobId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddMachineDialog(context, viewModel, widget.jobId);
        },
      ),
    );
  }

  Widget _buildMachineCard(BuildContext context, DbDraftMachine machine, DraftJobViewModel viewModel, String jobId) {
    final isDeleted = machine.status == 4;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDeleted ? Colors.grey.shade300 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDeleted ? Colors.grey : Colors.teal.shade100,
          child: Icon(Icons.precision_manufacturing, color: isDeleted ? Colors.white : Colors.teal),
        ),
        title: Text('${(machine.machineId != null && machine.machineId!.length > 8) ? machine.machineId!.substring(0, 8) : machine.machineId} : ${machine.machineName ?? 'Unnamed'}${isDeleted ? ' (Deleted)' : ''}', 
            style: TextStyle(fontWeight: FontWeight.bold, decoration: isDeleted ? TextDecoration.lineThrough : null, color: isDeleted ? Colors.grey.shade700 : Colors.black)),
        subtitle: Text(
          'Code: ${machine.machineCode ?? '-'} | Tap to manage Tags',
          style: TextStyle(color: isDeleted ? Colors.grey : Colors.grey.shade600),
        ),
        trailing: isDeleted ? const Chip(label: Text('Deleted', style: TextStyle(color: Colors.red, fontSize: 10))) : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditMachineDialog(context, machine, viewModel, jobId),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteMachine(context, machine, viewModel),
            ),
          ],
        ),
        onTap: isDeleted ? null : () {
          Navigator.pushNamed(context, '/draft_tag_list', arguments: {
            'jobId': jobId,
            'machineId': machine.uid,
            'machineName': machine.machineName ?? 'Unnamed',
            'machineCode': machine.machineCode,
          });
        },
      ),
    );
  }

  void _showAddMachineDialog(BuildContext context, DraftJobViewModel viewModel, String jobId) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Machine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Machine Name')),
            const SizedBox(height: 16),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Machine Code (MT System Code)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await viewModel.addMachine(
                  jobId, 
                  nameCtrl.text.trim(),
                  machineCode: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMachineDialog(BuildContext context, DbDraftMachine machine, DraftJobViewModel viewModel, String jobId) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: machine.machineName);
    final codeCtrl = TextEditingController(text: machine.machineCode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Machine'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Machine Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Machine Code (MT System Code)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await viewModel.updateMachineDetails(
                  machine.uid,
                  jobId,
                  nameCtrl.text.trim(),
                  machineCode: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
