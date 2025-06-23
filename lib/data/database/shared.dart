// lib/data/database/shared.dart
import 'package:drift/drift.dart';

/// This function provides the DatabaseConnection to AppDatabase.
/// Its implementation is conditionally imported based on the platform.
DatabaseConnection connect() {
  // This is a placeholder. The actual implementation is in
  // connection/connection.web.dart and connection/connection.native.dart.
  // The conditional export in connection/connection.dart will resolve this.
  throw UnimplementedError(
    'No database connection implementation found for this platform.',
  );
}
