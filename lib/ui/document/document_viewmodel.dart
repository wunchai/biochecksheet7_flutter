// lib/ui/document/document_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // สำหรับ DbDocument
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart'; // สำหรับ DocumentDao


/// Equivalent to DocumentViewModel.kt
class DocumentViewModel extends ChangeNotifier {
  final DocumentDao _documentDao;

  // ตัวแปรสำหรับเก็บ jobId ที่ส่งเข้ามา (ถ้ามี)
  String? _jobId;
  String? get jobId => _jobId;

  // Stream สำหรับรายการเอกสาร
  Stream<List<DbDocument>>? _documentsStream;
  Stream<List<DbDocument>>? get documentsStream => _documentsStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // สามารถเพิ่มข้อความแสดงสถานะได้เหมือน ViewModel อื่นๆ
  String _statusMessage = "Loading documents...";
  String get statusMessage => _statusMessage;

  DocumentViewModel({required AppDatabase appDatabase})
      : _documentDao = appDatabase.documentDao;

  // เมธอดสำหรับโหลดเอกสาร
  Future<void> loadDocuments(String? jobId) async {
    _isLoading = true;
    _jobId = jobId; // เก็บ jobId ไว้
    _statusMessage = "Fetching documents...";
    notifyListeners();

    try {
      if (jobId != null && jobId.isNotEmpty) {
        // หากมี jobId ให้ดึงเอกสารตาม jobId
        _documentsStream = _documentDao.watchDocumentsByJobId(jobId); // <<< แก้ไขตรงนี้
        _statusMessage = "Documents for Job ID: $jobId loaded.";
      } else {
        // หากไม่มี jobId ให้ดึงเอกสารทั้งหมด
        _documentsStream = _documentDao.watchAllDocuments();
        _statusMessage = "All documents loaded.";
      }
    } catch (e) {
      _statusMessage = "Failed to load documents: $e";
      print("Error loading documents: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // เมธอดสำหรับ Refresh
  void refreshDocuments() {
    _statusMessage = "Refreshing documents...";
    loadDocuments(_jobId); // โหลดเอกสารใหม่ด้วย jobId เดิม
  }

  // TODO: เพิ่มเมธอดสำหรับค้นหา/ฟิลเตอร์เอกสาร หากมี UI สำหรับการค้นหา
  /*
  void searchDocuments(String query) {
    // Implement search logic here, re-filter _documentsStream
    // e.g., _documentsStream = _documentDao.searchDocuments(query).watch();
    _statusMessage = "Searching for: $query";
    notifyListeners();
  }
  */
}