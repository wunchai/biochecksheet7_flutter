// lib/data/database/connection/connection.web.dart
import 'package:drift/wasm.dart';
import 'package:drift/drift.dart';

Future<DatabaseConnection> connect() async {
  final result = await WasmDatabase.open(
    databaseName: 'db.sqlite',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift.worker.js'),
  );

  if (result.missingFeatures.isNotEmpty) {
    print(
      '⚠️ Fallback to ${result.chosenImplementation} due to: ${result.missingFeatures}',
    );
  } else {
    print('✅ Using WasmDatabase');
  }

  return result.resolvedExecutor;
}
