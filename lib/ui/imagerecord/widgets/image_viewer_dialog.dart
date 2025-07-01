// lib/ui/imagerecord/widgets/image_viewer_dialog.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart'; // Import photo_view library
import 'dart:io'; // For File

/// Dialog สำหรับแสดงรูปภาพที่สามารถ Zoom และ Pan ได้
class ImageViewerDialog extends StatelessWidget {
  final String imagePath; // Path ของรูปภาพที่ต้องการแสดง

  const ImageViewerDialog({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // กำหนดสีพื้นหลังให้โปร่งใสเพื่อให้ PhotoView แสดงผลได้เต็มที่
      backgroundColor: Colors.transparent, 
      insetPadding: EdgeInsets.zero, // ลบ padding รอบ Dialog

      child: Stack(
        children: [
          // PhotoView สำหรับแสดงรูปภาพพร้อม Zoom และ Pan
          PhotoView(
            imageProvider: FileImage(File(imagePath)), // โหลดรูปภาพจาก Local File
            minScale: PhotoViewComputedScale.contained * 0.8, // ซูมออกได้ 80% ของขนาดพอดีจอ
            maxScale: PhotoViewComputedScale.covered * 4.0, // ซูมเข้าได้ 4 เท่าของขนาดเต็มจอ
            initialScale: PhotoViewComputedScale.contained, // ขนาดเริ่มต้นพอดีจอ
            backgroundDecoration: const BoxDecoration(
              color: Colors.black, // พื้นหลังสีดำ
            ),
            loadingBuilder: (context, event) {
              // แสดง CircularProgressIndicator ขณะโหลดรูปภาพ
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
              // แสดงไอคอน Error หากโหลดรูปภาพไม่ได้
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 50,
                ),
              );
            },
          ),
          // ปุ่มปิด Dialog ที่มุมบนขวา
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}