// lib/ui/imagerecord/image_processor_native.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:biochecksheet7_flutter/ui/imagerecord/image_processor.dart'; // Import the abstract class

// Concrete implementation for Native platforms.
class ImageProcessorNative implements ImageProcessor {
  final Uuid _uuid = const Uuid();

  @override
  Future<Uint8List?> processAndSaveImage(XFile pickedFile) async {
    File originalFile = File(pickedFile.path);
    img.Image? image = img.decodeImage(originalFile.readAsBytesSync());

    if (image == null) {
      throw Exception("ไม่สามารถโหลดรูปภาพได้จากไฟล์ Native.");
    }

    int targetWidth = 800;
    int targetHeight = (image.height * targetWidth / image.width).round();
    if (image.width > targetWidth) {
      image = img.copyResize(image, width: targetWidth, height: targetHeight);
    }

    final directory = await getApplicationDocumentsDirectory();
    final String appSpecificDir =
        p.join(directory.path, 'biochecksheet_images');
    await Directory(appSpecificDir).create(recursive: true);

    final String uniqueFileName = '${_uuid.v4()}.jpg';
    final String newFilePath = p.join(appSpecificDir, uniqueFileName);
    File newFile = File(newFilePath);
    await newFile.writeAsBytes(img.encodeJpg(image, quality: 85));

    print('รูปภาพถูกบันทึกที่ (Native): $newFilePath');
    return newFile.readAsBytes();
  }
}

// REMOVED: ImageProcessor getPlatformSpecificImageProcessor() => ImageProcessorNative(); // <<< REMOVE THIS LINE
