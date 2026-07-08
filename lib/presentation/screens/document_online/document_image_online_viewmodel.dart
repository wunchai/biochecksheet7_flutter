import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/document_image_online_api_service.dart';
import 'package:drift/drift.dart' as drift;

class DocumentImageOnlineViewModel extends ChangeNotifier {
  final AppDatabase appDatabase;
  final DocumentImageOnlineApiService apiService;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  String _downloadStatus = '';
  String get downloadStatus => _downloadStatus;

  DocumentImageOnlineViewModel({
    required this.appDatabase,
    required this.apiService,
  });

  /// Download all images for a document and store them locally
  Future<void> downloadImagesForDocument(String documentId, String username) async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadStatus = 'กำลังลบข้อมูลรูปเก่า...';
    notifyListeners();

    try {
      final dao = appDatabase.documentImageOnlineDao;

      // 1. Delete old images for this document
      await dao.deleteImagesByDocumentId(documentId);

      _downloadStatus = 'กำลังขอรายการรูปภาพ...';
      notifyListeners();

      // 2. Fetch Metadata
      final metadataList = await apiService.fetchDocumentImageMetadata(documentId);

      if (metadataList.isEmpty) {
        _downloadStatus = 'ไม่มีรูปภาพสำหรับเอกสารนี้';
        _isDownloading = false;
        notifyListeners();
        return;
      }

      final totalImages = metadataList.length;

      // 3. Loop through metadata, fetch base64 for each, and save to DB
      for (int i = 0; i < totalImages; i++) {
        final meta = metadataList[i];
        
        _downloadStatus = 'กำลังโหลดรูปภาพ ${i + 1} จาก $totalImages...';
        _downloadProgress = (i) / totalImages;
        notifyListeners();

        String base64String = "";
        if (meta.id > 0) {
          base64String = await apiService.fetchDocumentImageBase64(meta.id, username);
        }

        // Save complete data (with base64) to local DB
        await dao.insertImage(
          DocumentImageOnlinesCompanion(
            guid: drift.Value(meta.guid),
            documentId: drift.Value(meta.documentId),
            machineId: drift.Value(meta.machineId),
            jobId: drift.Value(meta.jobId),
            tagId: drift.Value(meta.tagId),
            createDate: drift.Value(meta.createDate),
            picture: drift.Value(base64String.isNotEmpty ? base64String : null),
          )
        );
      }

      _downloadProgress = 1.0;
      _downloadStatus = 'ดาวน์โหลดสำเร็จ $totalImages รูป';

    } catch (e) {
      _downloadStatus = 'เกิดข้อผิดพลาด: $e';
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Get images from local database for a specific tag
  Future<List<DbDocumentImageOnline>> getImagesForTag(String documentId, String machineId, String tagId) async {
    return await appDatabase.documentImageOnlineDao.getImagesForTag(documentId, machineId, tagId);
  }
}
