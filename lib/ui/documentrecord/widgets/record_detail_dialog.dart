// lib/ui/documentrecord/widgets/record_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';
import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart';

/// Dialog แสดงรายละเอียดทั้งหมดของ Document Record
class RecordDetailDialog extends StatelessWidget {
  final DocumentRecordWithTagAndProblem recordWithTag;

  const RecordDetailDialog({super.key, required this.recordWithTag});

  // Helper method เพื่อสร้างแถวสำหรับแสดงรายละเอียด
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // กำหนดความกว้างของ Label เพื่อจัดแนวให้สวยงาม
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
    final record = recordWithTag.documentRecord;
    final jobTag = recordWithTag.jobTag;

    return AlertDialog(
      title: const Text('รายละเอียดบันทึก'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildDetailRow('Tag Name', jobTag?.tagName),
            _buildDetailRow('Tag ID', jobTag?.tagId),
            _buildDetailRow('Tag Type', jobTag?.tagType),
            _buildDetailRow('Description', jobTag?.description),
            _buildDetailRow('Specification', jobTag?.specification),
            _buildDetailRow('Spec Min', jobTag?.specMin),
            _buildDetailRow('Spec Max', jobTag?.specMax),
            _buildDetailRow('Value (ปัจจุบัน)', record.value),
            _buildDetailRow('Unit', jobTag?.unit),
            _buildDetailRow('Remark', record.remark),
            _buildDetailRow('Note', jobTag?.note),
            _buildDetailRow('Status (Tag)', jobTag?.status?.toString()), // Status จาก JobTag
            _buildDetailRow('Record Status', record.status?.toString()), // Status จาก Record
            _buildDetailRow('ไม่อ่านค่าได้', record.unReadable), // <<< NEW: Add unReadable
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