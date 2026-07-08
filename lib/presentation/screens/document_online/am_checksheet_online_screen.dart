import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/am_checksheet_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/document_image_online_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';
import 'package:biochecksheet7_flutter/data/network/api_request_models.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
import 'package:collection/collection.dart';
import 'package:biochecksheet7_flutter/core/utils/app_toast.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
  State<AMChecksheetOnlineScreen> createState() =>
      _AMChecksheetOnlineScreenState();
}

class _AMChecksheetOnlineScreenState extends State<AMChecksheetOnlineScreen> {
  bool _showOnlyAbnormal = false;

  void _showImageDialog(String tagName, List<DbDocumentImageOnline> images) {
    int currentIndex = 0;
    
    showDialog(
      context: context,
      useSafeArea: false, // เพื่อให้แสดงผลเต็มจอไปจนถึงขอบโทรศัพท์ (Full Screen)
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero, // ไม่มีขอบขาวรอบๆ
              child: Stack(
                children: [
                  // 1. พื้นหลังสีดำแบบกึ่งโปร่งใส
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withValues(alpha: 0.95),
                  ),
                  
                  // 2. โซนแสดงรูปภาพ (PhotoViewGallery)
                  PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: (BuildContext context, int index) {
                      final base64String = images[index].picture;
                      if (base64String == null || base64String.isEmpty) {
                        return PhotoViewGalleryPageOptions.customChild(
                          child: const Center(
                            child: Text('รูปภาพไม่สมบูรณ์', style: TextStyle(color: Colors.white54, fontSize: 16)),
                          ),
                          initialScale: PhotoViewComputedScale.contained,
                        );
                      }
                      return PhotoViewGalleryPageOptions(
                        imageProvider: MemoryImage(base64Decode(base64String)),
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4.1,
                        heroAttributes: PhotoViewHeroAttributes(tag: images[index].uid.toString()),
                      );
                    },
                    itemCount: images.length,
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                  ),
                  
                  // 3. แถบด้านบน (ชื่อ Tag และปุ่มปิด) มี Gradient สีดำเพื่อให้อ่านตัวหนังสือชัด
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16, // หลบติ่งหน้าจอ
                        left: 20, right: 16, bottom: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                tagName,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. แถบตัวเลขบอกหน้าด้านล่าง
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 24, top: 32,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentIndex + 1} / ${images.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (images.length > 1)
                            const Text(
                              'ปัดซ้าย-ขวา เพื่อดูรูปถัดไป',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showActionMenu(DbDocumentRecordOnline item) {
    final imageViewModel = Provider.of<DocumentImageOnlineViewModel>(context, listen: false);
    final apiService = Provider.of<DocumentOnlineApiService>(context, listen: false);
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
    final username = loginViewModel.loggedInUser?.userCode ?? 'Unknown';
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
                      AppToast.show(
                          'ไม่มีรูปภาพ หรือยังไม่ได้ดาวน์โหลดรูปลงเครื่อง');
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
                  
                  print('DEBUG UI ITEM: ${item.toString()}');
                  print('DEBUG UI API_ID: ${item.apiId}');

                  // Call dialog with pre-fetched dependencies
                  _showOpenCaseDialog(context, item, apiService, username);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOpenCaseDialog(BuildContext context, DbDocumentRecordOnline item, DocumentOnlineApiService apiService, String username) {
    if (item.apiId == null) {
      AppToast.show('ไม่สามารถเปิด Case ได้ เนื่องจากไม่มี API ID สำหรับจุดตรวจนี้', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int selectedStatus = 1; // Default: ตรวจสอบแล้วปกติ
        TextEditingController remarkController = TextEditingController();
        bool isLoading = true;
        bool isSaving = false;
        List<OpenCaseHistory> history = [];

        return StatefulBuilder(
          builder: (context, setState) {
            // ดึงข้อมูลเก่ามาแสดง (ทำครั้งเดียวเมื่อโหลดเสร็จ)
            if (isLoading) {
              apiService.getOpenCase(item.apiId!).then((response) {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                    if (response != null) {
                      if (response.status != null) {
                        selectedStatus = response.status!;
                      }
                      if (response.remark != null) {
                        remarkController.text = response.remark!;
                      }
                      if (response.history != null) {
                        history = response.history!;
                      }
                    } else {
                       // MOCK DATA FOR DEMO PURPOSES
                       history = [
                         OpenCaseHistory(date: '2026-07-08 10:00:00', user: 'System (Mock)', status: 1, remark: 'ตรวจสอบครั้งแรก ปกติ'),
                         OpenCaseHistory(date: '2026-07-08 15:30:00', user: 'Admin (Mock)', status: 2, remark: 'เจอพัดลมเสียงดัง ขอเปิด case ซ่อม'),
                       ];
                    }
                  });
                }
              }).catchError((error) {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                     // MOCK DATA FOR DEMO PURPOSES
                     history = [
                       OpenCaseHistory(date: '2026-07-08 10:00:00', user: 'System (Mock)', status: 1, remark: 'ตรวจสอบครั้งแรก ปกติ (Mock Error Case)'),
                     ];
                  });
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('เปิด Case: ${item.tagName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('สถานะการตรวจสอบ', style: TextStyle(fontWeight: FontWeight.w600)),
                              RadioListTile<int>(
                                title: const Text('ตรวจสอบแล้วปกติ'),
                                value: 1,
                                groupValue: selectedStatus,
                                onChanged: (val) => setState(() => selectedStatus = val!),
                                contentPadding: EdgeInsets.zero,
                              ),
                              RadioListTile<int>(
                                title: const Text('เปิด Case ซ่อมเอง'),
                                value: 2,
                                groupValue: selectedStatus,
                                onChanged: (val) => setState(() => selectedStatus = val!),
                                contentPadding: EdgeInsets.zero,
                              ),
                              RadioListTile<int>(
                                title: const Text('เปิด Case ใบแจ้งซ่อม'),
                                value: 3,
                                groupValue: selectedStatus,
                                onChanged: (val) => setState(() => selectedStatus = val!),
                                contentPadding: EdgeInsets.zero,
                              ),
                              RadioListTile<int>(
                                title: const Text('ผิดปกติแต่มี case อยู่แล้ว'),
                                value: 4,
                                groupValue: selectedStatus,
                                onChanged: (val) => setState(() => selectedStatus = val!),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: remarkController,
                                decoration: const InputDecoration(
                                  labelText: 'หมายเหตุ (Remark)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              if (history.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Text('ประวัติการตรวจสอบ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: history.length,
                                  itemBuilder: (context, index) {
                                    final h = history[index];
                                    String statusText = '';
                                    Color statusColor = Colors.grey;
                                    switch (h.status) {
                                      case 1: statusText = 'ตรวจสอบแล้วปกติ'; statusColor = Colors.green; break;
                                      case 2: statusText = 'เปิด Case ซ่อมเอง'; statusColor = Colors.orange; break;
                                      case 3: statusText = 'เปิด Case ใบแจ้งซ่อม'; statusColor = Colors.red; break;
                                      case 4: statusText = 'ผิดปกติแต่มี case อยู่แล้ว'; statusColor = Colors.redAccent; break;
                                      default: statusText = 'ไม่ระบุ';
                                    }
                                    return Card(
                                      elevation: 0,
                                      color: Colors.grey[100],
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(h.user ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text(h.date ?? '-', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            if (h.remark != null && h.remark!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(h.remark!, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: (isLoading || isSaving)
                              ? null
                              : () async {
                                  setState(() => isSaving = true);
                                  
                                  final request = OpenCaseSetRequest(
                                    apiId: item.apiId!,
                                    status: selectedStatus,
                                    userId: username,
                                    remark: remarkController.text,
                                  );

                                  final success = await apiService.setOpenCase(request);
                                  
                                  if (mounted) {
                                    setState(() => isSaving = false);
                                    if (success) {
                                      Navigator.pop(dialogContext);
                                      AppToast.show('บันทึก Case เรียบร้อยแล้ว');
                                    } else {
                                      AppToast.show('เกิดข้อผิดพลาดในการบันทึก Case', isError: true);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                          child: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('บันทึก'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDownloadProgressDialog(BuildContext context,
      DocumentImageOnlineViewModel viewModel, String username) {
    showDialog(
      context: context,
      barrierDismissible: false, // ป้องกันการกดข้างนอกเพื่อปิด
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<DocumentImageOnlineViewModel>(
              builder: (context, vm, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ดึงรูปภาพออนไลน์',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 20),
                    if (vm.isDownloading)
                      LinearProgressIndicator(
                          value: vm.downloadProgress > 0
                              ? vm.downloadProgress
                              : null),
                    if (!vm.isDownloading)
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(vm.downloadStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    if (!vm.isDownloading)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('ตกลง'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    // เริ่มดาวน์โหลดหลังจากเปิดหน้าต่างแล้ว
    viewModel.downloadImagesForDocument(widget.documentId, username).then((_) {
      // หลังจากดาวน์โหลดเสร็จ ผู้ใช้จะเห็นปุ่ม 'ตกลง' โผล่ขึ้นมาให้กดปิด
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // สีพื้นหลังแบบสว่างดูสะอาดตา
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showOnlyAbnormal
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            tooltip:
                _showOnlyAbnormal ? 'แสดงข้อมูลทั้งหมด' : 'แสดงเฉพาะที่ผิดปกติ',
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
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.cloud_download),
                tooltip: 'ดึงรูปภาพทั้งหมด',
                onPressed: () {
                  final username =
                      loginViewModel.loggedInUser?.userCode ?? '000000';
                  _showDownloadProgressDialog(
                      context, imageViewModel, username);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AMChecksheetOnlineViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<List<DbDocumentRecordOnline>>(
            stream: viewModel.getRecordsForMachine(
                widget.documentId, widget.machineId),
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
                      (r.value != null &&
                          (r.value!.contains('ผิดปกติ') ||
                              r.value == 'ไม่ผ่าน'));
                }).toList();

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 80, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีรายการที่ผิดปกติ 🎉',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
              }

              final groupedRecords = groupBy(records,
                  (DbDocumentRecordOnline r) => r.tagGroupName ?? 'อื่นๆ');

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                itemCount: groupedRecords.keys.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = groupedRecords.keys.elementAt(groupIndex);
                  final groupItems = groupedRecords[groupName]!;

                  return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border(
                                  left: BorderSide(
                                      color: Colors.blue[700]!, width: 4),
                                ),
                              ),
                              child: Text(
                                groupName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue[900]),
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: groupItems.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, itemIndex) {
                                final item = groupItems[itemIndex];

                                Color valueColor = Colors.black87;
                                if (item.value == 'ปกติ' ||
                                    item.value == 'ผ่าน' ||
                                    item.value == 'Pass') {
                                  valueColor = Colors.green[700]!;
                                } else if (item.value != null &&
                                        item.value!.contains('ผิดปกติ') ||
                                    item.value == 'ไม่ผ่าน') {
                                  valueColor = Colors.red[700]!;
                                }

                                return InkWell(
                                  onTap: () => _showActionMenu(
                                      item), // <<< NEW MENU
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${itemIndex + 1}',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800]),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6.0,
                                                runSpacing: 4.0,
                                                children: [
                                                  Text(
                                                    item.tagName ?? 'Unknown Tag',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15),
                                                  ),
                                                  if (item.apiId != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[50],
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Colors.blue[200]!),
                                                      ),
                                                      child: Text(
                                                        'API ID: ${item.apiId}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.blue[700],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (item.description != null &&
                                                  item.description!.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4.0),
                                                  child: Text(
                                                    item.description!,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: valueColor.withValues(
                                                    alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20), // Pill shape
                                                border: Border.all(
                                                    color:
                                                        valueColor.withValues(
                                                            alpha: 0.2)),
                                              ),
                                              child: Text(
                                                item.value?.isNotEmpty == true
                                                    ? item.value!
                                                    : '-',
                                                style: TextStyle(
                                                    color: valueColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                            ),
                                            if (item.unReadable == 'true')
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(top: 2.0),
                                                child: Text('อ่านไม่ได้',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 10)),
                                              ),
                                            // Action icon hint
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Icon(Icons.more_horiz,
                                                  size: 20,
                                                  color: Colors.grey[400]),
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
                      ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
