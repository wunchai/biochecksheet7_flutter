// lib/data/database/tables/document_online_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbDocumentOnline')
class DocumentOnlines extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();

  TextColumn get documentId => text().named('documentId').nullable()();

  TextColumn get jobId => text().named('jobId').nullable()();

  TextColumn get documentName => text().named('documentName').nullable()();

  TextColumn get userId => text().named('userId').nullable()();

  TextColumn get createDate => text().named('createDate').nullable()(); // Stored as String (ISO 8601)

  IntColumn get status => integer().named('status').withDefault(const Constant(0))();

  TextColumn get lastSync => text().named('lastSync').nullable()(); // Stored as String (ISO 8601)

  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}
