// lib/ui/documentrecord/widgets/document_record_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart'; // For DocumentRecordWithTagAndProblem
import 'dart:async'; // Required for StreamSubscription

/// Custom AppBar for DocumentRecordScreen, handling title, search, and action buttons.
class AmDocumentRecordAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final VoidCallback onRefreshPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onImagePressed; // <<< NEW Callback for Image Sync button
  final VoidCallback onFilterPressed; // <<< NEW Callback for Filter button

  const AmDocumentRecordAppBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onRefreshPressed,
    required this.onSavePressed,
    required this.onImagePressed, // <<< Add to constructor
    required this.onFilterPressed, // <<< Add to constructor
  });

  @override
  State<AmDocumentRecordAppBar> createState() => _AmDocumentRecordAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}

class _AmDocumentRecordAppBarState extends State<AmDocumentRecordAppBar> {
  bool _isSearching = false; // Internal state to control search bar visibility.

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AMChecksheetViewModel>(
        context); // Listen to ViewModel changes.

    // Calculate button states directly from ViewModel data
    final records = viewModel.records;
    bool canPost = false;
    bool canUpload = false;
    bool canSave = true;

    if (records.isNotEmpty && !viewModel.isLoading) {
      bool allAreStatus1 = true;
      bool allAreStatus2 = true;
      bool anyAreStatus0 = false;
      bool anyAreStatus2 = false;

      for (var r in records) {
        if (r.documentRecord.status != 1) allAreStatus1 = false;
        if (r.documentRecord.status != 2) allAreStatus2 = false;
        if (r.documentRecord.status == 0) anyAreStatus0 = true;
        if (r.documentRecord.status == 2) anyAreStatus2 = true;
      }

      if (allAreStatus1 && !anyAreStatus2) {
        canPost = true;
      }

      if (!anyAreStatus0 && (allAreStatus1 || allAreStatus2)) {
        canUpload = true;
      }

      if (allAreStatus2) {
        canSave = false;
      }
    } else {
      // Empty or Loading
      canSave = false;
    }

    // Override canSave logic: if loading, disable. If empty, maybe disable?
    if (viewModel.isLoading) {
      canPost = false;
      canUpload = false;
      // canSave = false; // Already handled above?
    }
    if (records.isEmpty) {
      canSave = false;
    }

    return AppBar(
      title: _isSearching
          ? TextField(
              controller: widget.searchController,
              decoration: const InputDecoration(
                hintText: 'ค้นหาเอกสาร...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18.0),
              onChanged: (value) {
                // _viewModel.setSearchQuery(value); // Not used in AM Checksheet
              },
              autofocus: true,
            )
          : Text(widget.title),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                widget.searchController.clear();
              }
            });
          },
        ),
        // NEW: Filter Button
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter',
          onPressed: widget.onFilterPressed,
        ),
        IconButton(
          icon: const Icon(
              Icons.image), // Image Sync Button (similar to HomeScreen)
          tooltip: 'Sync Master Images',
          onPressed: widget.onImagePressed,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.onRefreshPressed,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed:
              (viewModel.isLoading || !canSave || viewModel.isDocumentClosed)
                  ? null
                  : widget.onSavePressed,
        ),
        // Post Button
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: (viewModel.isLoading || !canPost)
              ? null
              : () {
                  viewModel.postRecords();
                },
        ),
        // Upload Button
        IconButton(
          icon: const Icon(Icons.cloud_upload),
          onPressed: (viewModel.isLoading || !canUpload)
              ? null
              : () {
                  viewModel.uploadAllChangesToServer();
                },
        ),
      ],
    );
  }
}
