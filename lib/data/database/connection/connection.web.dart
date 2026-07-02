// lib/data/database/connection/connection.web.dart
import 'package:drift/wasm.dart';
import 'package:drift/drift.dart';
import 'package:biochecksheet7_flutter/core/app_config.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: AppConfig.databaseName,
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
  }));
}
