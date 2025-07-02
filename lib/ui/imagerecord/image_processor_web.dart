// lib/ui/imagerecord/image_processor_web.dart
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart'; // Import the abstract class

// Concrete implementation for Web platforms.
class ImageProcessorWeb implements ImageProcessor {
  @override
  Future<Uint8List?> processAndSaveImage(XFile pickedFile) async {
    final Uint8List originalBytes = await pickedFile.readAsBytes();
    img.Image? image = img.decodeImage(originalBytes);

    if (image == null) {
      throw Exception("ไม่สามารถโหลดรูปภาพได้จากข้อมูล Web.");
    }

    int targetWidth = 800;
    int targetHeight = (image.height * targetWidth / image.width).round();
    if (image.width > targetWidth) {
      image = img.copyResize(image, width: targetWidth, height: targetHeight);
    }

    print('รูปภาพถูกประมวลผลแล้ว (Web).');
    return img.encodeJpg(image, quality: 85);
  }
}

// REMOVED: ImageProcessor getPlatformSpecificImageProcessor() => ImageProcessorWeb(); // <<< REMOVE THIS LINE
