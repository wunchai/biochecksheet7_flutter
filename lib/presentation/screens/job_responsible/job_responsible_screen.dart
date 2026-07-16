import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/job_responsible/job_responsible_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

class JobResponsibleScreen extends StatelessWidget {
  final String jobId;
  final String jobName;

  const JobResponsibleScreen({
    super.key,
    required this.jobId,
    required this.jobName,
  });

  @override
  Widget build(BuildContext context) {
    // Provide the ViewModel to the widget tree
    return ChangeNotifierProvider<JobResponsibleViewModel>(
      create: (context) => JobResponsibleViewModel(Provider.of<AppDatabase>(context, listen: false), jobId),
      child: _JobResponsibleContent(jobId: jobId, jobName: jobName),
    );
  }
}

class _JobResponsibleContent extends StatefulWidget {
  final String jobId;
  final String jobName;

  const _JobResponsibleContent({
    required this.jobId,
    required this.jobName,
  });

  @override
  State<_JobResponsibleContent> createState() => _JobResponsibleContentState();
}

class _JobResponsibleContentState extends State<_JobResponsibleContent> {
  final TextEditingController _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าผู้รับการแจ้งเตือน'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Consumer<JobResponsibleViewModel>(
        builder: (context, viewModel, child) {
          // Listen to status messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (viewModel.successMessage != null) {
              final msg = viewModel.successMessage!;
              viewModel.successMessage = null; // Reset
              _userIdController.clear(); // Clear input on success
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text('สำเร็จ', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  content: Text(msg, style: const TextStyle(fontSize: 16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            }
            if (viewModel.errorMessage != null) {
              final msg = viewModel.errorMessage!;
              viewModel.errorMessage = null; // Reset
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text('เกิดข้อผิดพลาด', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  content: Text(msg, style: const TextStyle(fontSize: 16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            }
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'งาน: ${widget.jobName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Job ID: ${widget.jobId}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                const Text(
                  'User ID ที่ต้องการให้รับแจ้งเตือน:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintText: 'พิมพ์ User ID',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: viewModel.isLoading
                        ? null
                        : () async {
                            await viewModel.setJobResponsible(_userIdController.text);
                          },
                    child: viewModel.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('บันทึก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(thickness: 1.5),
                const SizedBox(height: 8),
                Text(
                  'รายชื่อผู้รับผิดชอบงานนี้:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: viewModel.isLoading && viewModel.responsibleUsers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.responsibleUsers.isEmpty
                          ? const Center(child: Text('ยังไม่มีผู้รับผิดชอบงานนี้'))
                          : ListView.builder(
                              itemCount: viewModel.responsibleUsers.length,
                              itemBuilder: (context, index) {
                                final user = viewModel.responsibleUsers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Icon(Icons.person, color: Colors.blue.shade900),
                                    ),
                                    title: Text(
                                      (user.userName != null && user.userName!.trim().isNotEmpty)
                                          ? '${user.userName} (ID: ${user.userId})'
                                          : 'User ID: ${user.userId}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('เพิ่มเมื่อ: ${user.createDate}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: user.status == 1 ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.status == 1 ? 'ใช้งาน' : 'ยกเลิก',
                                        style: TextStyle(
                                          color: user.status == 1 ? Colors.green.shade700 : Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
