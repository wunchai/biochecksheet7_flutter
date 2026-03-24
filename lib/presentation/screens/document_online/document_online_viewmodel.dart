// lib/presentation/screens/document_online/document_online_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_online_repository.dart';

class DocumentOnlineViewModel extends ChangeNotifier {
  final DocumentOnlineRepository _repository;

  Stream<List<DbDocumentOnline>>? documentsStream;
  bool isLoading = false;
  String? errorMessage;
  String? syncMessage;

  // Selected Dates
  DateTime startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime endDate = DateTime.now();

  DocumentOnlineViewModel({required DocumentOnlineRepository repository})
      : _repository = repository {
    _initStream();
  }

  void _initStream() {
    documentsStream = _repository.watchAllDocumentOnlines();
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    endDate = date;
    notifyListeners();
  }

  Future<void> syncOnlineData(String userId, String jobId) async {
    isLoading = true;
    errorMessage = null;
    syncMessage = null;
    notifyListeners();

    // Format dates to "2026-03-13 00:00:00"
    final startStr = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} 00:00:00";
    final endStr = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')} 23:59:59";

    final success = await _repository.syncDocumentOnlineData(
      userId: userId,
      jobId: jobId,
      start: startStr,
      stop: endStr,
    );

    if (success) {
      syncMessage = "ซิงค์ข้อมูลออนไลน์สำเร็จ";
    } else {
      errorMessage = "เกิดข้อผิดพลาดในการดึงข้อมูลจากออนไลน์";
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> clearOnlineData() async {
    await _repository.clearAllDocumentOnlines();
    notifyListeners();
  }
}
