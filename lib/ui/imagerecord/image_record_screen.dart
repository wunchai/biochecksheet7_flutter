// lib/ui/imagerecord/image_record_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/ui/imagerecord/image_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart'; // For DbImage
import 'dart:io'; // For File (แสดงรูปภาพจาก path)
import 'package:biochecksheet7_flutter/ui/imagerecord/widgets/image_viewer_dialog.dart'; // NEW: Import ImageViewerDialog
import 'package:flutter/foundation.dart'; // NEW: Import for kIsWeb
import 'dart:convert'; // For base64Decode
import 'package:biochecksheet7_flutter/ui/widgets/error_dialog.dart'; // <<< NEW: Import ErrorDialog



/// หน้าจอนี้แสดงรายการรูปภาพที่ผูกกับ Record (Tag) เฉพาะ
class ImageRecordScreen extends StatefulWidget {
  final String title;
  final String documentId;
  final String machineId;
  final String jobId;
  final String tagId; // Tag ID ของ Record ที่ผูกรูปภาพด้วย
  final String? problemId; // <<< เปลี่ยนเป็น String? เหมือนเดิม แต่จะตรวจสอบค่า
  final bool isReadOnly; // <<< NEW: Add isReadOnly parameter


  const ImageRecordScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
    required this.jobId,
    required this.tagId,
    this.problemId, // <<< Keep as optional, but ensure it's passed correctly
    required this.isReadOnly, // <<< NEW
  });

  @override
  State<ImageRecordScreen> createState() => _ImageRecordScreenState();
}

class _ImageRecordScreenState extends State<ImageRecordScreen> {
   bool _isShowingDialog = false; // <<< NEW: Flag to prevent multiple dialogs/snackbars

  @override
  void initState() {
    super.initState();
    // โหลดรูปภาพเมื่อหน้าจอเริ่มต้น
     print('ImageRecordScreen: initState called. DocID=${widget.documentId}, MachineID=${widget.machineId}, JobID=${widget.jobId}, TagID=${widget.tagId}, ProblemID=${widget.problemId}'); // <<< Debugging

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ImageViewModel>(context, listen: false).loadImages(
        documentId: widget.documentId,
        machineId: widget.machineId,
        jobId: widget.jobId,
        tagId: widget.tagId,
        problemId: widget.problemId, // <<< NEW: Pass problemId
        isReadOnly: widget.isReadOnly, // <<< Pass isReadOnly to ViewModel
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // ปุ่ม Refresh รูปภาพ
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ImageViewModel>(context, listen: false).refreshImages();
            },
          ),
          // ปุ่มถ่ายรูป
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: widget.isReadOnly ? null : () {
              final viewModel = Provider.of<ImageViewModel>(context, listen: false);
              viewModel.takePhotoAndSave();
            },
          ),
          // ปุ่มอัปโหลดรูปภาพจากไฟล์
          IconButton(
            icon: const Icon(Icons.photo_library), // Icon for picking from gallery
            onPressed:widget.isReadOnly ? null : () {
              final viewModel = Provider.of<ImageViewModel>(context, listen: false);
              viewModel.pickImageAndSave(); // Call the new method
            },
          ),
          // TODO: ปุ่ม Upload รูปภาพไปยัง Server (จะ Implement ใน Phase 4)
        ],
      ),
      body: Consumer<ImageViewModel>(
        builder: (context, viewModel, child) {
            // NEW: Show ErrorDialog/SnackBar for sync messages
          if (viewModel.syncMessage != null && !_isShowingDialog) { // <<< Check _isShowingDialog
            // Capture the message before async operation
            final String currentSyncMessage = viewModel.syncMessage!; 
            print('ImageRecordScreen: 1.currentSyncMessage (outside callback) is $currentSyncMessage'); // Debugging
            _isShowingDialog = true; // Set flag to true

            WidgetsBinding.instance.addPostFrameCallback((_) async { // Make callback async
              if (mounted) {
                print('ImageRecordScreen: 2.currentSyncMessage (inside callback) is $currentSyncMessage'); // Debugging

                bool isError = currentSyncMessage.toLowerCase().contains('ล้มเหลว') ||
                               currentSyncMessage.toLowerCase().contains('ข้อผิดพลาด') ||
                               currentSyncMessage.toLowerCase().contains('failed') ||
                               currentSyncMessage.toLowerCase().contains('error') ||
                               currentSyncMessage.toLowerCase().contains('exception') ||
                               currentSyncMessage.toLowerCase().contains('timed out') ||
                               currentSyncMessage.toLowerCase().contains('ไม่สามารถเชื่อมต่อ');

                if (isError) {
                  await showDialog( // Await the dialog to close
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return ErrorDialog(
                        title: 'ข้อผิดพลาดในการจัดการรูปภาพ',
                        message: currentSyncMessage, // Use captured message
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(currentSyncMessage)), // Use captured message
                  );
                }
                // CRUCIAL FIX: Clear the message AFTER the dialog/snackbar has been shown and potentially closed.
                // Reset flag after operation
                viewModel.syncMessage = null; 
                _isShowingDialog = false; // Reset flag
              }
            });
          }

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.statusMessage,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<DbImage>>(
                      stream: viewModel.imagesStream, // ฟัง Stream ของรูปภาพ
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('ไม่พบรูปภาพสำหรับ Record นี้.'));
                        } else {
                          final images = snapshot.data!;
                          return GridView.builder( // แสดงรูปภาพใน Grid
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 รูปต่อแถว
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: images.length,
                            padding: const EdgeInsets.all(8.0),
                            itemBuilder: (context, index) {
                              final image = images[index];

                              // Determine how to display the image based on platform and stored data
                              ImageProvider? imageProvider;
                               String? viewerImagePath; // Path to pass to ImageViewerDialog

                              if (kIsWeb && image.picture != null && image.picture!.isNotEmpty) {
                                // On Web, if picture (base64) is stored
                                imageProvider = MemoryImage(base64Decode(image.picture!));
                                 viewerImagePath = 'data:image/jpeg;base64,${image.picture!}'; // Pass data URI for viewer
                              } else if (!kIsWeb && image.filepath != null && image.filepath!.isNotEmpty) {
                                // On Native, if filepath is stored
                                imageProvider = FileImage(File(image.filepath!));
                                viewerImagePath = image.filepath!; // Pass file path for viewer
                              } else if (image.imageUri != null && image.imageUri!.startsWith('data:image')) {
                                // Fallback for data URI (if stored in imageUri)
                                try {
                                  final uriBytes = base64Decode(image.imageUri!.split(',').last);
                                  imageProvider = MemoryImage(uriBytes);
                                    viewerImagePath = image.imageUri!; // Pass data URI for viewer
                                } catch (e) {
                                  print('Error decoding data URI from imageUri for display: $e');
                                }
                              }

                              if (imageProvider != null) {
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () {
                                      // Pass the correct image path for viewer
                                      // On web, if base64 is stored, pass base64 string to viewer.
                                      // On native, pass filepath.
                                      if (kIsWeb && image.picture != null) {
                                          //print('Image tapped for UID: ${image.uid}, Viewer Path: "$viewerImagePath"'); // <<< Debug
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            //return ImageViewerDialog(imagePath: 'data:image/jpeg;base64,${image.picture!}'); // Pass data URI
                                           return ImageViewerDialog(imagePath: viewerImagePath!);
                                          },
                                        );
                                      } else if (!kIsWeb && image.filepath != null) {
                                          //print('Image tapped for UID: ${image.uid}, Viewer Path: "$viewerImagePath"'); // <<< Debug
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                           // return ImageViewerDialog(imagePath: image.filepath!); // Pass file path
                                           return ImageViewerDialog(imagePath: viewerImagePath!);
                                          },
                                        );
                                      }
                                     else {
                                            print('Error: No valid viewerImagePath for UID ${image.uid}'); // <<< Debug
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('ไม่สามารถแสดงรูปภาพได้: Path ไม่ถูกต้อง.')),
                                            );
                                          }
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image( // Use Image widget with imageProvider
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Center(child: Icon(Icons.broken_image, size: 50)),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            color: Colors.black54,
                                            child: Text(
                                              'Status: ${image.status}',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: viewModel.isReadOnly ? null : () async {
                                              final confirmDelete = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('ยืนยันการลบ'),
                                                    content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรูปภาพนี้?'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: const Text('ยกเลิก'),
                                                        onPressed: () {
                                                          Navigator.of(context).pop(false);
                                                        },
                                                      ),
                                                      TextButton(
                                                        child: const Text('ลบ'),
                                                        onPressed: () {
                                                          Navigator.of(context).pop(true);
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              if (confirmDelete == true) {
                                                Provider.of<ImageViewModel>(context, listen: false).deleteImage(image.uid);
                                              }
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return const Card(
                                  child: Center(child: Text('ไม่มีรูปภาพ หรือ Path ไม่ถูกต้อง')),
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Loading overlay
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}