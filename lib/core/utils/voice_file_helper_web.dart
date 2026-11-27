// lib/core/utils/voice_file_helper_web.dart

String detectVoicePlatformName() => 'web';

Future<String?> prepareVoiceRecordingPath(
        String clientRecordId, String extension) async =>
    null;

Future<bool> voiceFileExists(String? path) async =>
    path != null && path.isNotEmpty;

Future<void> deleteVoiceFileIfExists(String? path) async {}
