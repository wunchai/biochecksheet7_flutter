// lib/ui/imagerecord/image_processor.dart

// REMOVED: Conditional exports are no longer needed in this file.
// export 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_native.dart'
//     if (dart.library.html) 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_web.dart';

import 'dart:typed_data'; // For Uint8List
import 'package:image_picker/image_picker.dart'; // For XFile

/// Abstract class for platform-specific image processing.
/// This defines the contract for how images are processed and saved locally.
abstract class ImageProcessor {
  // REMOVED: static ImageProcessor create() => getPlatformSpecificImageProcessor(); // Remove static factory constructor

  /// Processes and saves an image obtained from ImagePicker.
  /// Returns the processed image bytes (Uint8List) or null if processing fails.
  Future<Uint8List?> processAndSaveImage(XFile pickedFile);
}

// REMOVED: ImageProcessor getPlatformSpecificImageProcessor() => throw UnsupportedError('Cannot create ImageProcessor on this platform.');
