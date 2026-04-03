// lib/presentation/screens/document_online/document_record_online_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/repositories/document_record_online_repository.dart';

class DocumentRecordOnlineViewModel extends ChangeNotifier {
  final DocumentRecordOnlineRepository _repository;

  DocumentRecordOnlineViewModel({required DocumentRecordOnlineRepository repository})
      : _repository = repository;

  Stream<List<DbDocumentRecordOnline>> getRecordsForMachine(String documentId, String machineId) {
    return _repository.watchRecordsForMachine(documentId, machineId);
  }
}
