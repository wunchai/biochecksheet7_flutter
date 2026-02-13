import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/views/am_checksheet_view_mixin.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';

class AmChecksheetLandscapeView extends StatefulWidget {
  final DocumentRecordWithTagAndProblem recordWithTag;
  final AMChecksheetViewModel viewModel;
  final Map<int, TextEditingController> controllers;
  final Map<int, String?> selectedComboBoxValues;

  const AmChecksheetLandscapeView({
    super.key,
    required this.recordWithTag,
    required this.viewModel,
    required this.controllers,
    required this.selectedComboBoxValues,
  });

  @override
  State<AmChecksheetLandscapeView> createState() =>
      _AmChecksheetLandscapeViewState();
}

class _AmChecksheetLandscapeViewState extends State<AmChecksheetLandscapeView>
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Left Column: Master Image (40%) ---
          Expanded(
            flex: 4,
            child: StreamBuilder<List<DbCheckSheetMasterImage>>(
              stream: jobTag != null
                  ? viewModel.watchMasterImagesForTag(jobTag)
                  : Stream.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final images = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: images.isEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade400)),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        size: 60, color: Colors.grey[600]),
                                    const SizedBox(height: 8),
                                    Text('ไม่มีรูปภาพประกอบ',
                                        style:
                                            TextStyle(color: Colors.grey[700])),
                                  ],
                                ),
                              ),
                            )
                          : images.length == 1
                              ? Builder(builder: (context) {
                                  // --- Single Image Display (Full Size) ---
                                  final currentImageRecord = images.first;
                                  final path = currentImageRecord.path;
                                  final uniqueKey = ValueKey(
                                      currentImageRecord.updatedAt.toString());

                                  Widget imageWidget;
                                  VoidCallback? onTap;

                                  if (path == null) {
                                    imageWidget = const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                              strokeWidth: 2),
                                          SizedBox(height: 8),
                                          Text("กำลังโหลด...",
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                    onTap = null;
                                  } else {
                                    imageWidget = kIsWeb
                                        ? Image.memory(
                                            base64Decode(path),
                                            key: uniqueKey,
                                            fit: BoxFit
                                                .contain, // Show full image
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 60,
                                                        color: Colors.grey)),
                                          )
                                        : Image.file(
                                            File(path),
                                            key: uniqueKey,
                                            fit: BoxFit
                                                .contain, // Show full image
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 60,
                                                        color: Colors.grey)),
                                          );
                                    onTap = () =>
                                        showFullScreenImage(context, path);
                                  }

                                  return GestureDetector(
                                    onTap: onTap,
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade400)),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(child: imageWidget),
                                          if (path != null)
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      size: 20,
                                                      color: Colors.white),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  tooltip: "แก้ไขรูปภาพ",
                                                  onPressed: () {
                                                    openImageEditor(context,
                                                        currentImageRecord);
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    final currentImageRecord = images[index];
                                    final path = currentImageRecord.path;
                                    final uniqueKey = ValueKey(
                                        currentImageRecord.updatedAt
                                            .toString());

                                    Widget imageWidget;
                                    VoidCallback? onTap;

                                    if (path == null) {
                                      // --- Syncing / Downloading State ---
                                      imageWidget = const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                                strokeWidth: 2),
                                            SizedBox(height: 4),
                                            Text("กำลังโหลด...",
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                      onTap = null;
                                    } else {
                                      // --- Image Ready State ---
                                      imageWidget = kIsWeb
                                          ? Image.memory(
                                              base64Decode(path),
                                              key: uniqueKey,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Center(
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                          color: Colors.grey)),
                                            )
                                          : Image.file(
                                              File(path),
                                              key: uniqueKey,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Center(
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                          color: Colors.grey)),
                                            );
                                      onTap = () =>
                                          showFullScreenImage(context, path);
                                    }

                                    return GestureDetector(
                                      onTap: onTap,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade400)),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(child: imageWidget),
                                            // Edit button overlay (Only show if path is available)
                                            if (path != null)
                                              Positioned(
                                                bottom: 4,
                                                right: 4,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        size: 16,
                                                        color: Colors.white),
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    tooltip: "แก้ไขรูปภาพ",
                                                    onPressed: () {
                                                      openImageEditor(context,
                                                          currentImageRecord);
                                                    },
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (jobTag != null)
                          TextButton.icon(
                            icon: const Icon(Icons.add_a_photo, size: 18),
                            label: const Text("Master Image"),
                            onPressed: isRecordReadOnly
                                ? null
                                : () => showImageSourceDialog(context, jobTag),
                          ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // --- Right Column: Checksheet Form (60%) ---
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Row(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            Text(
                              jobTag?.tagName ?? 'N/A',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall // Bigger title for landscape
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                        onPressed: () => showRecordDetailsDialog(
                            context, widget.recordWithTag),
                      ),
                    ],
                  ),

                  if (jobTag?.description != null &&
                      jobTag!.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        jobTag.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
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
                  const SizedBox(height: 8),
                  Text(
                    'หน่วย: ${jobTag?.unit ?? '-'} | มาตรฐาน: ${jobTag?.specMin ?? '-'} - ${jobTag?.specMax ?? '-'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Input Field
                  buildInputField(
                    context,
                    record,
                    jobTag,
                    null,
                    isRecordReadOnly: isRecordReadOnly,
                  ),

                  const SizedBox(height: 12),

                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: Text(
                            record.remark != null && record.remark!.isNotEmpty
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
                            record.syncStatus == 1
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            size: 16,
                            color: record.syncStatus == 1
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (record.remark != null && record.remark!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        "หมายเหตุ: ${record.remark}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
