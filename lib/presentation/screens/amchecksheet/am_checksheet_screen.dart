// lib/ui/amchecksheet/am_checksheet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ViewModel and Models
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
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
          ),
          body: Stack(
            children: [
              StreamBuilder<List<DocumentRecordWithTagAndProblem>>(
                stream: viewModel.recordsStream,
                builder: (context, snapshot) {
                  if (viewModel.isLoading && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('ไม่พบรายการตรวจเช็ค'));
                  }

                  final records = snapshot.data!;

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
                              color: Colors.black.withOpacity(0.05),
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
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}
