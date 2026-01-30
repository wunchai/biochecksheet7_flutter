// lib/ui/documentrecord/widgets/record_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';

/// Dialog แสดงรายละเอียดทั้งหมดของ Document Record แบบสวยงาม Modern Header
class AmRecordDetailDialog extends StatelessWidget {
  final DocumentRecordWithTagAndProblem recordWithTag;

  const AmRecordDetailDialog({super.key, required this.recordWithTag});

  // Helper method เพื่อสร้างแถวสำหรับแสดงรายละเอียด
  Widget _buildDetailRow(BuildContext context, String label, String? value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value ?? '-',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = recordWithTag.documentRecord;
    final jobTag = recordWithTag.jobTag;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, offset: Offset(0, 4), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // --- Header ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'รายละเอียดบันทึก',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'ปิด',
                  ),
                ],
              ),
            ),

            // --- Body ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    // Section 1: ข้อมูลทั่วไป (General Info)
                    _buildSectionHeader(context, 'ข้อมูล Tag', Icons.tag),
                    _buildDetailRow(context, 'Tag Name', jobTag?.tagName,
                        isBold: true),
                    _buildDetailRow(context, 'Tag ID', jobTag?.tagId),
                    _buildDetailRow(context, 'Type', jobTag?.tagType),
                    _buildDetailRow(
                        context, 'Description', jobTag?.description),

                    // Section 2: ข้อกำหนด (Specifications)
                    if (jobTag?.specMin != null || jobTag?.specMax != null) ...[
                      _buildSectionHeader(
                          context, 'มาตรฐานและการวัด', Icons.rule),
                      _buildDetailRow(
                          context, 'Specification', jobTag?.specification),
                      if (jobTag?.specMin != null)
                        _buildDetailRow(context, 'Spec Min', jobTag?.specMin),
                      if (jobTag?.specMax != null)
                        _buildDetailRow(context, 'Spec Max', jobTag?.specMax),
                      _buildDetailRow(context, 'Unit', jobTag?.unit),
                    ],

                    // Section 3: สถานะและการบันทึก (Status & Records)
                    _buildSectionHeader(
                        context, 'สถานะการบันทึก', Icons.assignment_turned_in),
                    _buildDetailRow(
                        context, 'ค่าที่อ่านได้ (Value)', record.value,
                        isBold: true, valueColor: Colors.blue[800]),
                    _buildDetailRow(
                        context, 'หมายเหตุ (Remark)', record.remark),
                    if (jobTag?.note != null && jobTag!.note!.isNotEmpty)
                      _buildDetailRow(
                          context, 'Note (จาก Master)', jobTag.note),

                    const SizedBox(height: 8),
                    // Status Badges Row
                    Row(
                      children: [
                        _buildStatusBadge(context, 'Record Status',
                            record.status?.toString()),
                        const SizedBox(width: 8),
                        _buildStatusBadge(
                            context, 'Sync', record.syncStatus.toString(),
                            isSync: true),
                      ],
                    ),

                    if (record.unReadable == 'true')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!)),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Text('ระบุว่า "อ่านค่าไม่ได้"',
                                  style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label, String? value,
      {bool isSync = false}) {
    Color bgColor = Colors.grey[200]!;
    Color textColor = Colors.black87;
    String displayValue = value ?? 'N/A';

    if (isSync) {
      if (value == '1') {
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        displayValue = 'Synced (1)';
      } else {
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        displayValue = 'Unsynced (0)';
      }
    } else {
      // Record Status Logic
      if (value == '2') {
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        displayValue = 'Posted (2)';
      } else if (value == '1') {
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        displayValue = 'Saved (1)';
      } else {
        displayValue = 'Pending ($value)';
      }
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(displayValue,
                style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
