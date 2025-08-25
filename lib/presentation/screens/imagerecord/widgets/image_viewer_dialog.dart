// lib/ui/imagerecord/widgets/image_viewer_dialog.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'dart:convert'; // Import for base64Decode


/// Dialog สำหรับแสดงรูปภาพที่สามารถ Zoom และ Pan ได้
class ImageViewerDialog extends StatelessWidget {
  final String imagePath; // Path ของรูปภาพที่ต้องการแสดง (อาจจะเป็น FilePath หรือ Data URI)

  const ImageViewerDialog({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    print('ImageViewerDialog: เข้าสู่ Build, imagePath: "$imagePath"'); // <<< Debug

    if (kIsWeb && imagePath.startsWith('data:image')) {
      try {
        final uriBytes = base64Decode(imagePath.split(',').last);
        imageProvider = MemoryImage(uriBytes);
        print('ImageViewerDialog (Web): Data URI detected. Bytes length: ${uriBytes.length}'); // <<< Debug
      } catch (e) {
        print('ImageViewerDialog (Web): Error decoding data URI in viewer: $e'); // <<< Debug
        imageProvider = null; // Ensure null if error
      }
    } else if (!kIsWeb && imagePath.isNotEmpty) {
      imageProvider = FileImage(File(imagePath));
      print('ImageViewerDialog (Native): File path detected: "$imagePath"'); // <<< Debug
    } else {
      imageProvider = null;
      print('ImageViewerDialog: ไม่มี ImageProvider ที่ถูกต้อง.'); // <<< Debug
    }

    return Dialog(
      backgroundColor: Colors.transparent, 
      insetPadding: EdgeInsets.zero,

      child: Stack(
        children: [
          if (imageProvider != null) // Only show PhotoView if imageProvider is valid
            PhotoView(
              imageProvider: imageProvider, // Use the determined imageProvider
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 4.0,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              loadingBuilder: (context, event) {
                print('ImageViewerDialog: กำลังโหลดรูปภาพ...'); // <<< Debug
                return Center(
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      value: event == null
                          ? null
                          : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('ImageViewerDialog: Error loading image in PhotoView: $error'); // <<< Debug
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                );
              },
            )
          else
            const Center(
              child: Text(
                'ไม่สามารถแสดงรูปภาพได้',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          // ปุ่มปิด Dialog ที่มุมบนขวา
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}