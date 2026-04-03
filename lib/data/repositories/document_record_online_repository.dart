// lib/data/repositories/document_record_online_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_record_online_dao.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';
import 'package:drift/drift.dart' as drift;

class DocumentRecordOnlineRepository {
  final DocumentRecordOnlineDao _dao;
  final DocumentOnlineApiService _apiService;

  DocumentRecordOnlineRepository(this._dao, this._apiService);

  /// Fetch all pages for a specific document and save them locally.
  Future<void> fetchAndSaveAllOnlineRecords(String userId, String jobId, String documentId) async {
    try {
      // 1. Clear existing records for this document to avoid duplicates
      await _dao.deleteRecordsByDocumentId(documentId);

      // 2. Fetch first page to get TotalPages
      int currentPage = 1;
      int totalPages = 1;
      final int pageSize = 1000;

      do {
        final response = await _apiService.fetchDocumentRecordPagedOnline(
          userId: userId,
          jobId: jobId,
          documentId: documentId,
          pageIndex: currentPage,
          pageSize: pageSize,
        );

        totalPages = response.totalPages;

        // Convert network response to Db insertions
        if (response.records.isNotEmpty) {
          final companions = response.records.map((record) => DocumentRecordOnlinesCompanion(
            documentId: drift.Value(record.documentId),
            documentCreateDate: drift.Value(record.documentCreateDate),
            documentCreateUser: drift.Value(record.documentCreateUser),
            machineId: drift.Value(record.machineId),
            jobId: drift.Value(record.jobId),
            tagId: drift.Value(record.tagId),
            tagName: drift.Value(record.tagName),
            tagGroupId: drift.Value(record.tagGroupId),
            tagGroupName: drift.Value(record.tagGroupName),
            tagType: drift.Value(record.tagType),
            tagSelectionValue: drift.Value(record.tagSelectionValue),
            description: drift.Value(record.description),
            specification: drift.Value(record.specification),
            specMin: drift.Value(record.specMin),
            specMax: drift.Value(record.specMax),
            unit: drift.Value(record.unit),
            valueType: drift.Value(record.valueType),
            value: drift.Value(record.value),
            status: drift.Value(record.status),
            unReadable: drift.Value(record.unReadable),
            remark: drift.Value(record.remark),
            syncDate: drift.Value(record.syncDate),
            uiType: drift.Value(record.uiType),
          )).toList();

          await _dao.insertMultipleRecords(companions);
        }

        currentPage++;
      } while (currentPage <= totalPages);
      
    } catch (e) {
      print('Error within DocumentRecordOnlineRepository fetchAndSaveAllOnlineRecords: $e');
      throw Exception('Failed to fetch and save online document records: $e');
    }
  }

  /// Watch distinct machines configured for a document
  Stream<List<DbDocumentRecordOnline>> watchDistinctMachines(String documentId) {
    return _dao.watchDistinctMachines(documentId);
  }

  /// Watch all records for a specific machine in a document
  Stream<List<DbDocumentRecordOnline>> watchRecordsForMachine(String documentId, String machineId) {
    return _dao.watchRecordsForMachine(documentId, machineId);
  }
}
