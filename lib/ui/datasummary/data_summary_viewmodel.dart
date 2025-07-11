// lib/ui/datasummary/data_summary_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // For AppDatabase
import 'package:biochecksheet7_flutter/data/models/data_summary.dart'; // For DataSummary model

// Import all DAOs needed to fetch summary data
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/job_tag_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/problem_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart';

// Import table models for checking status
import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart'; // For DbDocumentRecord
import 'package:biochecksheet7_flutter/data/database/tables/problem_table.dart'; // For DbProblem

class DataSummaryViewModel extends ChangeNotifier {
  final UserDao _userDao;
  final JobDao _jobDao;
  final DocumentMachineDao _documentMachineDao;
  final JobTagDao _jobTagDao;
  final ProblemDao _problemDao;
  final DocumentRecordDao _documentRecordDao;
  final ImageDao _imageDao;

  DataSummary _summary = DataSummary(); // Initial empty summary
  DataSummary get summary => _summary;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  DataSummaryViewModel({required AppDatabase appDatabase})
      : _userDao = appDatabase.userDao,
        _jobDao = appDatabase.jobDao,
        _documentMachineDao = appDatabase.documentMachineDao,
        _jobTagDao = appDatabase.jobTagDao,
        _problemDao = appDatabase.problemDao,
        _documentRecordDao = appDatabase.documentRecordDao,
        _imageDao = appDatabase.imageDao;

  /// Fetches all summary data from local database.
  Future<void> fetchSummaryData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch lastSync for master data tables
      final lastSyncUser = await _userDao.getLastSync();
      final lastSyncJob = await _jobDao.getLastSync();
      final lastSyncJobMachine = await _documentMachineDao.getLastSync();
      final lastSyncJobTag = await _jobTagDao.getLastSync();
      final lastSyncProblem = await _problemDao.getLastSync();

      // 2. Fetch DocumentRecord summary (status = 2, syncStatus = 0)
      final pendingDocRecordsCount =
          await _documentRecordDao.countRecordsByStatusAndSyncStatus(2, 0);
      final lastSyncPendingDocRecords = await _documentRecordDao
          .getLastSyncForRecordsByStatusAndSyncStatus(2, 0);

      // 3. Fetch Image summary - Divided by source type
      int pendingDocumentImageUploadCount = 0;
      String? lastSyncPendingDocumentImageUpload;
      int pendingProblemImageUploadCount = 0;
      String? lastSyncPendingProblemImageUpload;

      // Get all images with syncStatus = 0
      final allPendingImages = await _imageDao.getImagesBySyncStatus(0);

      for (final image in allPendingImages) {
        if (image.problemId != null && image.problemId!.isNotEmpty) {
          // Image is tied to a Problem
          final DbProblem? parentProblem =
              await _problemDao.getProblemByProblemId(image.problemId!);
          if (parentProblem != null &&
              (parentProblem.problemStatus == 2 ||
                  parentProblem.problemStatus == 3)) {
            pendingProblemImageUploadCount++;
            // Update lastSync for problem images if current image's lastSync is newer
            if (image.lastSync != null) {
              if (lastSyncPendingProblemImageUpload == null ||
                  DateTime.parse(image.lastSync!).isAfter(
                      DateTime.parse(lastSyncPendingProblemImageUpload))) {
                lastSyncPendingProblemImageUpload = image.lastSync;
              }
            }
          }
        } else if (image.documentId != null &&
            image.documentId!.isNotEmpty &&
            image.tagId != null &&
            image.tagId!.isNotEmpty) {
          // Image is tied to a DocumentRecord (problemId is null/empty)
          // We need to find the specific DbDocumentRecord it belongs to
          final DbDocumentRecord? parentRecord =
              await _documentRecordDao.getDocumentRecord(
            documentId: image.documentId!,
            machineId:
                image.machineId ?? '', // machineId might be null for images
            tagId: image.tagId!,
          );
          if (parentRecord != null &&
              (parentRecord.status == 2 || parentRecord.status == 3)) {
            pendingDocumentImageUploadCount++;
            // Update lastSync for document images if current image's lastSync is newer
            if (image.lastSync != null) {
              if (lastSyncPendingDocumentImageUpload == null ||
                  DateTime.parse(image.lastSync!).isAfter(
                      DateTime.parse(lastSyncPendingDocumentImageUpload))) {
                lastSyncPendingDocumentImageUpload = image.lastSync;
              }
            }
          }
        }
        // If image is not tied to a valid parent (problemId is null/empty AND documentId/tagId are null/empty
        // or parent status is not 2/3), it's not counted in pending uploads.
      }

      _summary = DataSummary(
        lastSyncUser: lastSyncUser,
        lastSyncJob: lastSyncJob,
        lastSyncJobMachine: lastSyncJobMachine,
        lastSyncJobTag: lastSyncJobTag,
        lastSyncProblem: lastSyncProblem,
        pendingDocumentRecordsCount: pendingDocRecordsCount,
        lastSyncPendingDocumentRecords: lastSyncPendingDocRecords,
        pendingDocumentImageUploadCount: pendingDocumentImageUploadCount, // NEW
        lastSyncPendingDocumentImageUpload:
            lastSyncPendingDocumentImageUpload, // NEW
        pendingProblemImageUploadCount: pendingProblemImageUploadCount, // NEW
        lastSyncPendingProblemImageUpload:
            lastSyncPendingProblemImageUpload, // NEW
      );
    } catch (e) {
      _errorMessage = 'ข้อผิดพลาดในการโหลดข้อมูลสรุป: $e';
      print('Error fetching data summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
