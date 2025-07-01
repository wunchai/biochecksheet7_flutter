// lib/ui/imagerecord/image_processor.dart

// Conditional exports must be at the top of the file.
export 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_native.dart'
    if (dart.library.html) 'package:biochecksheet7_flutter/ui/imagerecord/image_processor_web.dart';

import 'dart:typed_data'; // For Uint8List
import 'package:image_picker/image_picker.dart'; // For XFile

/// Abstract class for platform-specific image processing.
abstract class ImageProcessor {
  // Factory constructor to create platform-specific instance.
  // This will be implemented in image_processor_native.dart and image_processor_web.dart.
  factory ImageProcessor() => getImageProcessor(); // Implemented in platform-specific files

  Future<Uint8List?> processAndSaveImage(XFile pickedFile);
}

// This function will be defined in platform-specific files.
// It returns the concrete implementation of ImageProcessor.
ImageProcessor getImageProcessor() => throw UnsupportedError('Cannot create ImageProcessor on this platform.');