// lib/ui/amchecksheet/am_checksheet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ViewModel and Models
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
// import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/widgets/am_document_record_app_bar.dart';
import 'package:biochecksheet7_flutter/presentation/widgets/sync_progress_dialog.dart';

// Views
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/views/am_checksheet_portrait_view.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/views/am_checksheet_landscape_view.dart';

class AMChecksheetScreen extends StatefulWidget {
  final String title;
  final String documentId;
  final String machineId;
  final String jobId;

  const AMChecksheetScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
    required this.jobId,
  });

  @override
  State<AMChecksheetScreen> createState() => _AMChecksheetScreenState();
}

class _AMChecksheetScreenState extends State<AMChecksheetScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String?> _selectedComboBoxValues = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AMChecksheetViewModel>(context, listen: false)
          .loadRecords(widget.documentId, widget.machineId, widget.jobId);
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _searchController.dispose();
    super.dispose();
  }

  void _onSyncMasterImagesPressed(
      BuildContext context, AMChecksheetViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SyncProgressDialog(
        progressNotifier: viewModel.syncProgressNotifier,
        statusNotifier: viewModel.syncStatusNotifier,
      ),
    );

    final String resultMessage = await viewModel.syncMasterImages();

    if (context.mounted) Navigator.of(context).pop();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AMChecksheetViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.syncMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(viewModel.syncMessage!),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(
                    bottom: 100.0, left: 16.0, right: 16.0),
              ),
            );
            viewModel.syncMessage = null;
          });
        }

        return Scaffold(
          appBar: AmDocumentRecordAppBar(
            title: widget.title,
            searchController: _searchController,
            onRefreshPressed: () {
              // Refresh logic if needed
            },
            onSavePressed: () {
              viewModel.saveAllChanges(
                allControllers: _controllers,
                allComboBoxValues: _selectedComboBoxValues,
              );
            },
            onImagePressed: () {
              _onSyncMasterImagesPressed(context, viewModel);
            },
            // NEW: Filter Button Action
            onFilterPressed: () => _showFilterDialog(context, viewModel),
          ),
          body: Stack(
            children: [
              // Removes StreamBuilder, use viewModel.records directly (Consumer is already above)
              Builder(
                builder: (context) {
                  // Logic moved from StreamBuilder
                  if (viewModel.isLoading && viewModel.records.isEmpty) {
                    // Show loading only if no records are loaded yet
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Checks moved to here
                  final records = viewModel.records;

                  if (records.isEmpty) {
                    return Center(child: Text(viewModel.statusMessage));
                  }

                  return Column(
                    children: [
                      // --- Top Status Message ---
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                viewModel.statusMessage.isEmpty
                                    ? 'พร้อมสำหรับการตรวจสอบ'
                                    : viewModel.statusMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: viewModel.pageController,
                          itemCount: records.length,
                          onPageChanged: viewModel.onPageChanged,
                          itemBuilder: (context, index) {
                            final recordWithTag = records[index];
                            return OrientationBuilder(
                              builder: (context, orientation) {
                                if (orientation == Orientation.portrait) {
                                  return AmChecksheetPortraitView(
                                    recordWithTag: recordWithTag,
                                    viewModel: viewModel,
                                    controllers: _controllers,
                                    selectedComboBoxValues:
                                        _selectedComboBoxValues,
                                  );
                                } else {
                                  return AmChecksheetLandscapeView(
                                    recordWithTag: recordWithTag,
                                    viewModel: viewModel,
                                    controllers: _controllers,
                                    selectedComboBoxValues:
                                        _selectedComboBoxValues,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      // --- Bottom Navigation Bar ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.05), // Fixed deprecation
                              offset: const Offset(0, -2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress Indicator
                              LinearProgressIndicator(
                                value: records.isNotEmpty
                                    ? (viewModel.currentPage + 1) /
                                        records.length
                                    : 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor),
                                minHeight: 4,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Previous Button
                                    OutlinedButton.icon(
                                      onPressed: viewModel.currentPage > 0
                                          ? viewModel.navigateToPreviousPage
                                          : null,
                                      icon: const Icon(Icons.arrow_back_ios_new,
                                          size: 16),
                                      label: const Text('ย้อนกลับ'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),

                                    // Page Indicator Text
                                    if (records.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${viewModel.currentPage + 1} / ${records.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800]),
                                        ),
                                      ),

                                    // Next Button
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: ElevatedButton.icon(
                                        onPressed: viewModel.currentPage <
                                                records.length - 1
                                            ? viewModel.navigateToNextPage
                                            : null,
                                        icon: const Icon(
                                            Icons.arrow_back_ios_new,
                                            size:
                                                16), // Rotated by RTL? No, use correct icon
                                        label: const Text('ถัดไป'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (viewModel.isLoading)
                Container(
                  color:
                      Colors.black.withValues(alpha: 0.5), // Fixed deprecation
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog(
      BuildContext context, AMChecksheetViewModel viewModel) {
    String tempTagName = '';
    String? tempGroupName;
    bool tempUnfilled = false; // Initialize

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get preview of records based on current temporary filters
            final previewRecords = viewModel.getFilteredPreview(
              tagName: tempTagName,
              groupName: tempGroupName,
              unfilled: tempUnfilled,
            );

            return AlertDialog(
              title: const Text('กรองข้อมูล (Filter)'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Filter Inputs ---
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ Tag (บางส่วน)',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          tempTagName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'กลุ่ม Tag',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      value: tempGroupName,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('ทั้งหมด'),
                        ),
                        ...viewModel.availableTagGroups.map((group) {
                          return DropdownMenuItem<String>(
                            value: group,
                            child: Text(group, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          tempGroupName = value;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('แสดงเฉพาะที่ยังไม่ระบุค่า'),
                      value: tempUnfilled,
                      onChanged: (bool? value) {
                        setState(() {
                          tempUnfilled = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    // --- Filtered List Preview ---
                    Text(
                      'พบข้อมูล ${previewRecords.length} รายการ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: previewRecords.isEmpty
                          ? const Center(
                              child: Text('ไม่พบข้อมูล',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: previewRecords.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final record = previewRecords[index];
                                final isValueEmpty =
                                    record.documentRecord.value == null ||
                                        record.documentRecord.value!.isEmpty;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    record.jobTag?.tagName ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${record.jobTag?.tagGroupName ?? '-'} | ${isValueEmpty ? "ยังไม่ระบุ" : record.documentRecord.value}',
                                    style: TextStyle(
                                      color: isValueEmpty
                                          ? Colors.red
                                          : Colors.black54,
                                    ),
                                  ),
                                  onTap: () {
                                    // Apply filters and jump to this record
                                    viewModel.setFilters(
                                        tagName: tempTagName,
                                        groupName: tempGroupName,
                                        unfilled: tempUnfilled);

                                    // Wait a bit for list to filter, then jump
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      viewModel.jumpToRecord(
                                          record.documentRecord.uid);
                                    });

                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    viewModel.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('ล้างตัวกรอง',
                      style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    viewModel.setFilters(
                        tagName: tempTagName,
                        groupName: tempGroupName,
                        unfilled: tempUnfilled);
                    Navigator.pop(context);
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
