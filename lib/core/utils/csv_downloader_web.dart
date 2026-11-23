// lib/core/utils/csv_downloader_web.dart
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

@JS('Blob')
external JSFunction get _blobConstructor;

@JS('URL.createObjectURL')
external String _createObjectURL(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectURL(String url);

@JS('document')
external JSObject get _document;

/// Triggers a native browser download for a CSV file (UTF-8 with BOM).
Future<String> saveCsvFile(String fileName, String content) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final options = JSObject()..['type'] = 'text/csv;charset=utf-8'.toJS;
  final blob = _blobConstructor.callAsConstructor<JSObject>(
    <JSAny>[bytes.toJS].toJS,
    options,
  );
  final url = _createObjectURL(blob);

  final anchor =
      _document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  anchor['href'] = url.toJS;
  anchor['download'] = fileName.toJS;

  final body = _document['body'] as JSObject?;
  body?.callMethod<JSAny?>('appendChild'.toJS, anchor);
  anchor.callMethod<JSAny?>('click'.toJS);
  anchor.callMethod<JSAny?>('remove'.toJS);

  Future<void>.delayed(const Duration(seconds: 2), () {
    _revokeObjectURL(url);
  });

  return fileName;
}
