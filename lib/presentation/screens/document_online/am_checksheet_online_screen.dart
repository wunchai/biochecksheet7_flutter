import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/am_checksheet_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_image_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart';
import 'package:collection/collection.dart';
import 'package:biochecksheet7_flutter/core/utils/app_toast.dart';

class AMChecksheetOnlineScreen extends StatefulWidget {
  final String title;
  final String documentId;
  final String machineId;

  const AMChecksheetOnlineScreen({
    super.key,
    required this.title,
    required this.documentId,
    required this.machineId,
  });

  @override
  State<AMChecksheetOnlineScreen> createState() => _AMChecksheetOnlineScreenState();
}

class _AMChecksheetOnlineScreenState extends State<AMChecksheetOnlineScreen> {
  bool _showOnlyAbnormal = false;

  void _showImageDialog(String tagName, List<DbDocumentImageOnline> images) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                child: Text('รูปถ่าย: $tagName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final base64String = images[index].picture;
                    if (base64String == null || base64String.isEmpty) {
                      return Container(
                        color: Colors.white,
                        child: const Center(child: Text('รูปภาพไม่สมบูรณ์')),
                      );
                    }
                    return InteractiveViewer(
                      child: Image.memory(base64Decode(base64String), fit: BoxFit.contain),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: Text('ปัดซ้าย-ขวา เพื่อดูรูปถัดไป (${images.length} รูป)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActionMenu(BuildContext context, DbDocumentRecordOnline item) {
    // Capture the ViewModels and Navigator using the valid screen context
    final imageViewModel = Provider.of<DocumentImageOnlineViewModel>(context, listen: false);
    final navigator = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('เรียกดูรูปถ่าย'),
                onTap: () async {
                  navigator.pop(); // ปิดเมนูก่อนอย่างปลอดภัย
                  
                  try {
                    final images = await imageViewModel.getImagesForTag(
                      widget.documentId,
                      widget.machineId,
                      item.tagId ?? '',
                    );
                    
                    if (!mounted) return;
                    if (images.isEmpty) {
                      AppToast.show('ไม่มีรูปภาพ หรือยังไม่ได้ดาวน์โหลดรูปลงเครื่อง');
                    } else {
                      _showImageDialog(item.tagName ?? 'รูปถ่าย', images);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    AppToast.show('เกิดข้อผิดพลาด: $e', isError: true);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('เปิด Case'),
                onTap: () {
                  navigator.pop(); // ปิดเมนูอย่างปลอดภัย
                  AppToast.show('เปิด Case สำหรับ ${item.tagName} (อยู่ระหว่างพัฒนา)');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_showOnlyAbnormal ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: _showOnlyAbnormal ? 'แสดงข้อมูลทั้งหมด' : 'แสดงเฉพาะที่ผิดปกติ',
            onPressed: () {
              setState(() {
                _showOnlyAbnormal = !_showOnlyAbnormal;
              });
            },
          ),
          Consumer2<DocumentImageOnlineViewModel, LoginViewModel>(
            builder: (context, imageViewModel, loginViewModel, child) {
              if (imageViewModel.isDownloading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.cloud_download),
                tooltip: 'ดึงรูปภาพทั้งหมด',
                onPressed: () async {
                  final username = loginViewModel.loggedInUser?.userCode ?? '000000';
                  await imageViewModel.downloadImagesForDocument(widget.documentId, username);
                  if (!context.mounted) return;
                  AppToast.show(imageViewModel.downloadStatus);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AMChecksheetOnlineViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<List<DbDocumentRecordOnline>>(
            stream: viewModel.getRecordsForMachine(widget.documentId, widget.machineId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('ไม่พบรายการสำหรับเครื่องนี้'));
              }

              var records = snapshot.data!;
              
              if (_showOnlyAbnormal) {
                records = records.where((r) {
                  return r.unReadable == 'true' || 
                         (r.value != null && (r.value!.contains('ผิดปกติ') || r.value == 'ไม่ผ่าน'));
                }).toList();
                
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 80, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีรายการที่ผิดปกติ 🎉',
                          style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
              }

              final groupedRecords = groupBy(records, (DbDocumentRecordOnline r) => r.tagGroupName ?? 'อื่นๆ');

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: groupedRecords.keys.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = groupedRecords.keys.elementAt(groupIndex);
                  final groupItems = groupedRecords[groupName]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[100],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: Text(
                            groupName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: groupItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, itemIndex) {
                            final item = groupItems[itemIndex];
                            
                            Color valueColor = Colors.black87;
                            if (item.value == 'ปกติ' || item.value == 'ผ่าน' || item.value == 'Pass') {
                              valueColor = Colors.green[700]!;
                            } else if (item.value != null && item.value!.contains('ผิดปกติ') || item.value == 'ไม่ผ่าน') {
                              valueColor = Colors.red[700]!;
                            }

                            return InkWell(
                              onTap: () => _showActionMenu(context, item), // <<< NEW MENU
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        '${itemIndex + 1}',
                                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.tagName ?? 'Unknown Tag',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          if (item.description != null && item.description!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                item.description!,
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: valueColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: valueColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            item.value?.isNotEmpty == true ? item.value! : '-',
                                            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (item.unReadable == 'true')
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2.0),
                                            child: Text('อ่านไม่ได้', style: TextStyle(color: Colors.red, fontSize: 10)),
                                          ),
                                        // Action icon hint
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Icon(Icons.more_horiz, size: 20, color: Colors.grey[400]),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
