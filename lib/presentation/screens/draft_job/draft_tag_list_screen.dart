// lib/presentation/screens/draft_job/draft_tag_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/draft_job/draft_job_viewmodel.dart';

class DraftTagListScreen extends StatelessWidget {
  final int jobId;
  final int machineId;
  final String machineName;

  const DraftTagListScreen({
    super.key,
    required this.jobId,
    required this.machineId,
    required this.machineName,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DraftJobViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tags: $machineName'),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<List<DbDraftTag>>(
        stream: viewModel.watchTags(machineId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tags = snapshot.data ?? [];
          if (tags.isEmpty) {
            return const Center(
              child: Text('No tags added yet.\nTap + to add one.', textAlign: TextAlign.center),
            );
          }

          // Group by tagGroupName manually
          final groupedTags = <String, List<DbDraftTag>>{};
          for (var tag in tags) {
            final groupName = tag.tagGroupName ?? 'Uncategorized';
            groupedTags.putIfAbsent(groupName, () => []).add(tag);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groupedTags.keys.length,
            itemBuilder: (context, index) {
              final groupName = groupedTags.keys.elementAt(index);
              final groupItems = groupedTags[groupName]!;
              
              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  children: groupItems.map((tag) => _buildTagTile(context, tag, viewModel)).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddTagDialog(context, viewModel, jobId, machineId);
        },
      ),
    );
  }

  Widget _buildTagTile(BuildContext context, DbDraftTag tag, DraftJobViewModel viewModel) {
    return ListTile(
      leading: const Icon(Icons.label_outline, color: Colors.black54),
      title: Text(tag.tagName ?? 'Unnamed Tag', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${tag.tagType ?? '-'} | Min: ${tag.specMin ?? '-'} | Max: ${tag.specMax ?? '-'} | Unit: ${tag.unit ?? '-'}'),
          if (tag.description != null && tag.description!.isNotEmpty)
            Text('Desc: ${tag.description}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () {
          viewModel.deleteTag(tag.uid);
        },
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, DraftJobViewModel viewModel, int jobId, int machineId) async {
    // Fetch distinct lists
    final groupOptions = await viewModel.getDistinctGroupNames(jobId);
    final tagOptions = await viewModel.getDistinctTagNames(jobId);

    if (!context.mounted) return;

    TextEditingController? groupCtrl;
    TextEditingController? nameCtrl;
    final minCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'number';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Tag'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue val) {
                        if (val.text == '') return const Iterable<String>.empty();
                        return groupOptions.where((opt) => opt.toLowerCase().contains(val.text.toLowerCase()));
                      },
                      fieldViewBuilder: (ctx, ctrl, focus, submit) {
                        groupCtrl = ctrl;
                        return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: 'Group Name'));
                      },
                    ),
                    const SizedBox(height: 16),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue val) {
                        if (val.text == '') return const Iterable<String>.empty();
                        return tagOptions.where((opt) => opt.toLowerCase().contains(val.text.toLowerCase()));
                      },
                      fieldViewBuilder: (ctx, ctrl, focus, submit) {
                        nameCtrl = ctrl;
                        return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: 'Tag Name'));
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Data Type'),
                      items: const [
                        DropdownMenuItem(value: 'number', child: Text('Number')),
                        DropdownMenuItem(value: 'text', child: Text('Text')),
                        DropdownMenuItem(value: 'boolean', child: Text('Boolean (Pass/Fail)')),
                      ],
                      onChanged: (val) {
                        setState(() { selectedType = val!; });
                      },
                    ),
                    if (selectedType == 'number') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Min Spec'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: maxCtrl, decoration: const InputDecoration(labelText: 'Max Spec'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g. °C, PSI)')),
                    ],
                    const SizedBox(height: 16),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (Optional)'), maxLines: 2),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl != null && nameCtrl!.text.isNotEmpty && groupCtrl != null && groupCtrl!.text.isNotEmpty) {
                      await viewModel.addTag(
                        jobId: jobId,
                        machineId: machineId,
                        groupName: groupCtrl!.text,
                        tagName: nameCtrl!.text,
                        tagType: selectedType,
                        specMin: minCtrl.text.isEmpty ? null : minCtrl.text,
                        specMax: maxCtrl.text.isEmpty ? null : maxCtrl.text,
                        unit: unitCtrl.text.isEmpty ? null : unitCtrl.text,
                        description: descCtrl.text.isEmpty ? null : descCtrl.text,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
