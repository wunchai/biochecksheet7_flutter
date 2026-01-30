import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/views/am_checksheet_view_mixin.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';

class AmChecksheetPortraitView extends StatefulWidget {
  final DocumentRecordWithTagAndProblem recordWithTag;
  final AMChecksheetViewModel viewModel;
  final Map<int, TextEditingController> controllers;
  final Map<int, String?> selectedComboBoxValues;

  const AmChecksheetPortraitView({
    super.key,
    required this.recordWithTag,
    required this.viewModel,
    required this.controllers,
    required this.selectedComboBoxValues,
  });

  @override
  State<AmChecksheetPortraitView> createState() =>
      _AmChecksheetPortraitViewState();
}

class _AmChecksheetPortraitViewState extends State<AmChecksheetPortraitView>
    with AmChecksheetViewMixin {
  @override
  AMChecksheetViewModel get viewModel => widget.viewModel;
  @override
  Map<int, TextEditingController> get controllers => widget.controllers;
  @override
  Map<int, String?> get selectedComboBoxValues => widget.selectedComboBoxValues;

  @override
  Widget build(BuildContext context) {
    final DbDocumentRecord record = widget.recordWithTag.documentRecord;
    final DbJobTag? jobTag = widget.recordWithTag.jobTag;
    final bool isRecordReadOnly =
        record.status == 2 || viewModel.isDocumentClosed; // <<< Global ReadOnly

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Master Image Section ---
          StreamBuilder<DbCheckSheetMasterImage?>(
            stream: jobTag != null
                ? viewModel.watchMasterImageForTag(jobTag)
                : Stream.value(null),
            builder: (context, snapshot) {
              Widget imageWidget;
              DbCheckSheetMasterImage? currentImageRecord;
              String? pathOrBase64ForDialog;

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                imageWidget = const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData && snapshot.data?.path != null) {
                currentImageRecord = snapshot.data;
                pathOrBase64ForDialog = currentImageRecord!.path!;
                // Key to force refresh
                final uniqueKey =
                    ValueKey(currentImageRecord.updatedAt.toString());

                imageWidget = kIsWeb
                    ? Image.memory(
                        base64Decode(pathOrBase64ForDialog),
                        key: uniqueKey,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                                child: Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey)),
                      )
                    : Image.file(
                        File(pathOrBase64ForDialog),
                        key: uniqueKey,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                                child: Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey)),
                      );
              } else {
                imageWidget = Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          size: 60, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('ไม่มีรูปภาพประกอบ',
                          style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () =>
                        showFullScreenImage(context, pathOrBase64ForDialog),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400)),
                      child: imageWidget,
                    ),
                  ),
                  if (currentImageRecord != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("แก้ไขรูปภาพ"),
                        onPressed: () {
                          openImageEditor(context, currentImageRecord!);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // --- 2. Title and Details Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (jobTag?.tagGroupName != null &&
                        jobTag!.tagGroupName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          jobTag.tagGroupName!,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    Text(
                      jobTag?.tagName ?? 'N/A',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (jobTag?.description != null &&
                        jobTag!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          jobTag.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    if (jobTag?.note != null && jobTag!.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          jobTag.note!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'หน่วย: ${jobTag?.unit ?? '-'} | มาตรฐาน: ${jobTag?.specMin ?? '-'} - ${jobTag?.specMax ?? '-'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    Row(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Master Image",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_a_photo,
                                  color: Colors.blueAccent),
                              onPressed: isRecordReadOnly
                                  ? null
                                  : () {
                                      if (jobTag != null) {
                                        showImageSourceDialog(context, jobTag);
                                      }
                                    },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => showRecordDetailsDialog(
                              context, widget.recordWithTag),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.image_search),
                tooltip: 'ดูรูปภาพที่บันทึก',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/image_record',
                    arguments: {
                      'title': 'รูปภาพ: ${jobTag?.tagName ?? 'N/A'}',
                      'documentId': record.documentId,
                      'machineId': record.machineId,
                      'jobId': record.jobId,
                      'tagId': record.tagId,
                      'isReadOnly': isRecordReadOnly,
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'ดูรายละเอียด',
                onPressed: () =>
                    showRecordDetailsDialog(context, widget.recordWithTag),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // --- 3. Input Fields ---
          buildInputField(
            context,
            record,
            jobTag,
            null, // problem
            isRecordReadOnly: isRecordReadOnly,
          ),
          const SizedBox(height: 20),

          // --- 4. Footer Actions (Remark/Status) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_note, size: 20),
                label: Text(record.remark != null && record.remark!.isNotEmpty
                    ? 'แก้ไขหมายเหตุ'
                    : 'เพิ่มหมายเหตุ'),
                onPressed: isRecordReadOnly
                    ? null
                    : () => showRemarkInputDialog(context, record),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'สถานะ: ${getStatusText(record.status)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    record.syncStatus == 1 ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: record.syncStatus == 1 ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
          if (record.remark != null && record.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                "หมายเหตุ: ${record.remark}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
