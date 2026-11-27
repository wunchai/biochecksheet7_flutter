// lib/core/utils/voice_file_helper_io.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

String detectVoicePlatformName() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'android'; // Backend accepts 'android', 'ios', or 'web' (Section 4.2)
}

Future<String?> prepareVoiceRecordingPath(
    String clientRecordId, String extension) async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/voice_queue');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return '${dir.path}/voice_$clientRecordId.$extension';
}

Future<bool> voiceFileExists(String? path) async {
  if (path == null || path.isEmpty) return false;
  return File(path).exists();
}

Future<void> deleteVoiceFileIfExists(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}
