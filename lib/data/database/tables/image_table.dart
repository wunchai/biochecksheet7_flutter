// lib/data/database/tables/image_table.dart
import 'package:drift/drift.dart';

@DataClassName('DbImage') // กำหนดชื่อ DataClass ที่จะถูกสร้างโดย drift
class Images extends Table {
  // Primary Key (autoIncrement)
  IntColumn get uid => integer().autoIncrement().named('uid')();

  // NEW: Fields from Kotlin DbImage entity
  TextColumn get guid => text().named('guid').nullable()(); // Unique ID for image (if generated externally)
  TextColumn get imageIndex => text().named('imageIndex').nullable()(); // Index or order of image
  TextColumn get picture => text().named('picture').nullable()(); // Base64 string of image (if stored directly) - NOT RECOMMENDED FOR LARGE IMAGES
  TextColumn get imageUri => text().named('imageUri').nullable()(); // URI of image (e.g., local file path, web URL)
  TextColumn get filename => text().named('filename').nullable()(); // Original filename
  TextColumn get filepath => text().named('filepath').nullable()(); // Local filepath where image is stored

  // Foreign Keys / Relationships
  TextColumn get documentId => text().named('documentId').nullable()();
  TextColumn get jobId => text().named('jobId').nullable()();
  TextColumn get machineId => text().named('machineId').nullable()();
  TextColumn get tagId => text().named('tagId').nullable()(); // Link to the specific tag/record
  TextColumn get problemId => text().named('problemId').nullable()(); // <<< NEW: Link to the specific problem

  // Metadata
  TextColumn get createDate => text().named('createDate').nullable()(); // Date/Time image was taken
  IntColumn get status => integer().named('status').withDefault(const Constant(0))(); // Status (e.g., 0=local, 1=synced, 2=deleted)
  TextColumn get lastSync => text().named('lastSync').nullable()(); // Last sync timestamp
  IntColumn get statusSync => integer().named('statusSync').withDefault(const Constant(0))(); // Sync status (e.g., 0=pending, 1=synced)
  TextColumn get updatedAt => text().named('updatedAt').nullable()(); // Stores ISO 8601 string
}