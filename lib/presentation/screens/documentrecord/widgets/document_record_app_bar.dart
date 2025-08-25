// lib/ui/documentrecord/widgets/document_record_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/document_record_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart'; // For DocumentRecordWithTagAndProblem
import 'dart:async'; // Required for StreamSubscription

/// Custom AppBar for DocumentRecordScreen, handling title, search, and action buttons.
class DocumentRecordAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final VoidCallback onRefreshPressed;
  final VoidCallback onSavePressed;

  const DocumentRecordAppBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onRefreshPressed,
    required this.onSavePressed,
  });

  @override
  State<DocumentRecordAppBar> createState() => _DocumentRecordAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}

class _DocumentRecordAppBarState extends State<DocumentRecordAppBar> {
  bool _isSearching = false; // Internal state to control search bar visibility.
  bool _canPostButtonEnabled =
      false; // Internal state for the Post button's enabled status.
  bool _canUploadButtonEnabled =
      false; // Internal state for the Upload button's enabled status.

  StreamSubscription<List<DocumentRecordWithTagAndProblem>>?
      _recordsSubscription;
  late DocumentRecordViewModel _viewModel; // Store a reference to the ViewModel

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<DocumentRecordViewModel>(context, listen: false);

    _recordsSubscription = _viewModel.recordsStream?.listen((records) {
      _updateButtonStates(records, _viewModel.isLoading);
    }, onError: (error) {
      print("AppBar Stream Subscription Error: $error");
      if (mounted) {
        setState(() {
          _canPostButtonEnabled = false;
          _canUploadButtonEnabled = false;
        });
      }
    });

    _viewModel.addListener(_onViewModelChange);

    _updateButtonStates(null, _viewModel.isLoading);
  }

  void _onViewModelChange() {
    _updateButtonStates(null, _viewModel.isLoading);
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    _viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  /// Helper to update the state of the Post and Upload buttons based on records data and loading status.
  Future<void> _updateButtonStates(
      List<DocumentRecordWithTagAndProblem>? records,
      bool viewModelIsLoading) async {
    List<DocumentRecordWithTagAndProblem> currentRecords = records ?? [];
    if (records == null) {
      currentRecords =
          await (_viewModel.recordsStream?.first ?? Future.value([]));
    }

    bool newCanPost = true;
    bool newCanUpload =
        false; // Start as false, set to true only if conditions are met

    print('--- Update Button States Debug ---');
    print('ViewModel Loading: $viewModelIsLoading');
    print('Total Records: ${currentRecords.length}');

    if (currentRecords.isEmpty) {
      newCanPost = false;
      newCanUpload = false;
      print('No records found. Buttons disabled.');
    } else {
      bool allAreStatus1 = true;
      bool allAreStatus2 = true; // NEW: Check if ALL records are Status 2
      bool anyAreStatus0 = false;
      bool anyAreStatus1 = false; // NEW: Check if ANY record is Status 1
      bool anyAreStatus2 = false; // Check if ANY record is Status 2 (old var)

      print('Records Status Details:');
      for (var r in currentRecords) {
        print(
            '  UID: ${r.documentRecord.uid}, TagName: ${r.jobTag?.tagName}, Status: ${r.documentRecord.status}');
        if (r.documentRecord.status != 1) {
          allAreStatus1 = false;
        } else {
          anyAreStatus1 = true; // At least one is status 1
        }
        if (r.documentRecord.status != 2) {
          // Check if not status 2 for 'allAreStatus2'
          allAreStatus2 = false;
        } else {
          anyAreStatus2 = true; // At least one is status 2
        }
        if (r.documentRecord.status == 0) {
          anyAreStatus0 = true; // At least one is status 0
        }
      }

      print(
          'Summary: allAreStatus1=$allAreStatus1, anyAreStatus0=$anyAreStatus0, allAreStatus2=$allAreStatus2, anyAreStatus2(old)=$anyAreStatus2'); // Corrected anyAreStatus2 logging

      // Logic for Post button (unchanged logic, only name changed for clarity)
      if (allAreStatus1 && !anyAreStatus2) {
        // All Status 1, and NONE are Status 2
        newCanPost = true;
        print('Post button: ENABLED (All Status 1, None Status 2)');
      } else {
        newCanPost = false;
        print('Post button: DISABLED (Not all Status 1 OR some Status 2)');
      }

      // NEW Logic for Upload button:
      // It should be enabled if:
      // A) All records are Status 1 (ready for initial upload, not yet posted)
      // OR B) All records are Status 2 (already posted, allowing re-upload).
      // AND C) No records are Status 0 (all must be validated or posted).
      // This means currentRecords.every((r) => r.documentRecord.status == 1 || r.documentRecord.status == 2)
      if (currentRecords.isNotEmpty && !anyAreStatus0) {
        // If there are records AND NONE are status 0
        if (allAreStatus1 || allAreStatus2) {
          // If ALL are status 1 OR ALL are status 2
          newCanUpload = true;
          print('Upload button: ENABLED (All Status 1 OR All Status 2)');
        } else {
          newCanUpload = false;
          print(
              'Upload button: DISABLED (Records are mixed, e.g., some 1, some 2, but not ALL 1 or ALL 2)');
        }
      } else {
        // No records OR some records are status 0
        newCanUpload = false;
        print(
            'Upload button: DISABLED (No records OR some records are Status 0)');
      }
    }

    // Also disable buttons if ViewModel is globally loading.
    if (viewModelIsLoading) {
      newCanPost = false;
      newCanUpload = false;
      print('ViewModel is loading. Buttons DISABLED.');
    }

    // Only update if the button's enabled state actually changed and widget is still mounted.
    if (mounted) {
      if (_canPostButtonEnabled != newCanPost) {
        setState(() {
          _canPostButtonEnabled = newCanPost;
        });
      }
      if (_canUploadButtonEnabled != newCanUpload) {
        setState(() {
          _canUploadButtonEnabled = newCanUpload;
        });
      }
    }
    print('--- End Button States Debug ---');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DocumentRecordViewModel>(
        context); // Listen to ViewModel changes.

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
                _viewModel.setSearchQuery(value);
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
                //_viewModel.setSearchQuery('');
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.onRefreshPressed,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: widget.onSavePressed,
        ),
        // Post Button
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: (viewModel.isLoading || !_canPostButtonEnabled)
              ? null
              : () {
                  viewModel.postRecords();
                },
        ),
        // Upload Button
        IconButton(
          icon: const Icon(Icons.cloud_upload),
          onPressed: (viewModel.isLoading || !_canUploadButtonEnabled)
              ? null
              : () {
                  viewModel.uploadAllChangesToServer();
                },
        ),
      ],
    );
  }
}
