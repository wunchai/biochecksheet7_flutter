// lib/ui/problem/widgets/problem_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem

/// Dialog แสดงรายละเอียดทั้งหมดของ Problem Record
class ProblemDetailDialog extends StatelessWidget {
  final DbProblem problem;

  const ProblemDetailDialog({super.key, required this.problem});

  // Helper method เพื่อสร้างแถวสำหรับแสดงรายละเอียด
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // กำหนดความกว้างของ Label เพื่อจัดแนวให้สวยงาม
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('รายละเอียดปัญหา'),
      content: SingleChildScrollView( // ใช้ SingleChildScrollView เพื่อให้เลื่อนดูได้
        child: ListBody(
          children: <Widget>[
            _buildDetailRow('Problem ID', problem.problemId),
            _buildDetailRow('Problem Name', problem.problemName),
            _buildDetailRow('Problem Description', problem.problemDescription),
            _buildDetailRow('Problem Status', problem.problemStatus.toString()),
            _buildDetailRow('Solving Description', problem.problemSolvingDescription),
            _buildDetailRow('Solving By', problem.problemSolvingBy),
            _buildDetailRow('Machine Name', problem.machineName),
            _buildDetailRow('Job ID', problem.jobId),
            _buildDetailRow('Tag ID', problem.tagId),
            _buildDetailRow('Tag Name', problem.tagName),
            _buildDetailRow('Tag Type', problem.tagType),
            _buildDetailRow('Tag Description', problem.description), // This is Tag's description
            _buildDetailRow('Note', problem.note),
            _buildDetailRow('Specification', problem.specification),
            _buildDetailRow('Spec Min', problem.specMin),
            _buildDetailRow('Spec Max', problem.specMax),
            _buildDetailRow('Unit', problem.unit),
            _buildDetailRow('Value', problem.value),
            _buildDetailRow('Remark', problem.remark),
            _buildDetailRow('UnReadable', problem.unReadable),
            _buildDetailRow('Last Sync', problem.lastSync),
            _buildDetailRow('Sync Status', problem.syncStatus.toString()),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('ปิด'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}