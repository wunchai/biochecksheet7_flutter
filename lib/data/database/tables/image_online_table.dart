import 'package:drift/drift.dart';

@DataClassName('DbDocumentImageOnline')
class DocumentImageOnlines extends Table {
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // API fields
  TextColumn get guid => text().named('guid').nullable()();
  TextColumn get imageIndex => text().named('imageIndex').nullable()();
  TextColumn get picture => text().named('picture').nullable()(); // Base64
  TextColumn get filename => text().named('filename').nullable()();
  
  // Foreign Keys / Relationships
  TextColumn get documentId => text().named('documentId').nullable()();
  TextColumn get jobId => text().named('jobId').nullable()();
  TextColumn get machineId => text().named('machineId').nullable()();
  TextColumn get tagId => text().named('tagId').nullable()();
  TextColumn get problemId => text().named('problemId').nullable()();

  // Metadata
  TextColumn get createDate => text().named('createDate').nullable()();
  IntColumn get status => integer().named('status').withDefault(const Constant(0))();
}
