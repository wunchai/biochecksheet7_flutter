// lib/core/utils/csv_downloader_io.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Saves a CSV string (UTF-8) to the Downloads directory (or App Documents fallback).
Future<String> saveCsvFile(String fileName, String content) async {
  Directory? targetDir;
  try {
    targetDir = await getDownloadsDirectory();
  } catch (_) {
    targetDir = null;
  }
  targetDir ??= await getApplicationDocumentsDirectory();

  final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(utf8.encode(content), flush: true);
  return file.path;
}
