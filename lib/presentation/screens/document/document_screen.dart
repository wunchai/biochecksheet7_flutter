// lib/ui/document/document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // <<< 1. เพิ่ม Import สำหรับ DateFormat

import 'package:biochecksheet7_flutter/presentation/screens/document/document_viewmodel.dart'; // Import DocumentFilter
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // สำหรับ DbDocument
import 'package:biochecksheet7_flutter/presentation/screens/documentmachine/document_machine_screen.dart'; // สำหรับนำทางไป DocumentMachineScreen

/// หน้าจอนี้แสดงรายการเอกสาร จัดการโดย DocumentViewModel.
/// เทียบเท่ากับ DocumentActivity.kt ในโปรเจกต์ Kotlin เดิม
class DocumentScreen extends StatefulWidget {
  final String title; // ชื่อหน้าจอที่จะแสดงใน AppBar
  final String?
      jobId; // ตัวเลือก: jobId เพื่อกรองเอกสารที่เกี่ยวข้องกับ Job เฉพาะ

  const DocumentScreen({super.key, required this.title, this.jobId});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final TextEditingController _searchController =
      TextEditingController(); // Controller สำหรับ TextField ค้นหา
  bool _isSearching = false; // สถานะควบคุมการแสดงผลของ Search Bar

  @override
  void initState() {
    super.initState();
    // เรียกโหลดเอกสารเมื่อหน้าจอเริ่มต้น โดยส่ง jobId หากมี
    // listen: false เพราะเราเรียกใช้ method เท่านั้น ไม่ได้ฟังการ rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentViewModel>(context, listen: false)
          .loadDocuments(widget.jobId);
    });

    // ฟังการเปลี่ยนแปลงของ search controller เพื่อ trigger การค้นหาใน ViewModel
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Method จัดการเมื่อข้อความค้นหาเปลี่ยน
  void _onSearchChanged() {
    Provider.of<DocumentViewModel>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

/*
  // แสดง Dialog สำหรับสร้างเอกสารใหม่
  Future<void> _showCreateNewDocumentDialog(
      BuildContext context, DocumentViewModel viewModel) async {
    // <<< 2. สร้างวันที่และเวลาที่จัดรูปแบบแล้ว
    final String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // <<< 3. กำหนดค่าเริ่มต้นให้กับ Controller
    final TextEditingController documentIdController =
        TextEditingController(text: formattedDate);

    String? newDocumentName;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('สร้างเอกสารใหม่'), // Title ของ Dialog
          content: TextField(
            autofocus: true, // โฟกัสอัตโนมัติเมื่อ Dialog เปิด
            controller: documentIdController, // ใช้ Controller ที่สร้าง
            decoration: const InputDecoration(
                hintText: 'ชื่อเอกสาร'), // Placeholder Text

            onChanged: (value) {
              newDocumentName = value; // เก็บชื่อเอกสารที่ผู้ใช้ป้อน
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
              },
            ),
            TextButton(
              child: const Text('สร้าง'),
              onPressed: () async {
                if (newDocumentName != null && newDocumentName!.isNotEmpty) {
                  final success =
                      await viewModel.createNewDocument(newDocumentName!);
                  if (success) {
                    Navigator.of(context).pop(); // ปิด Dialog หากสร้างสำเร็จ
                  } else {
                    // จัดการข้อผิดพลาด (Snackbar แสดงโดย ViewModel แล้ว)
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

*/

  Future<void> _showCreateNewDocumentDialog(
      BuildContext context, DocumentViewModel viewModel) async {
    // 1. สร้างวันที่และเวลาที่จัดรูปแบบแล้ว
    final String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // 2. กำหนดค่าเริ่มต้นให้กับ Controller
    final TextEditingController documentIdController =
        TextEditingController(text: formattedDate);

    await showDialog<void>(
      // เปลี่ยนเป็น void เพราะเราจัดการทุกอย่างข้างใน
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('สร้างเอกสารใหม่'),
          content: TextField(
            autofocus: true,
            controller: documentIdController, // ใช้ Controller
            decoration: const InputDecoration(hintText: 'ชื่อเอกสาร'),
            // --- <<< 3. ลบ onChanged ที่ไม่จำเป็นออกไป >>> ---
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('สร้าง'),
              onPressed: () async {
                // --- <<< 4. อ่านค่าจาก Controller โดยตรง >>> ---
                final String documentName = documentIdController.text;

                if (documentName.isNotEmpty) {
                  final success =
                      await viewModel.createNewDocument(documentName);
                  if (success && context.mounted) {
                    Navigator.of(context).pop(); // ปิด Dialog หากสร้างสำเร็จ
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // แสดง Dialog สำหรับคัดลอกเอกสาร
  Future<void> _showCopyDocumentDialog(
      BuildContext context, DocumentViewModel viewModel) async {
    String? newDocumentName;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'คัดลอกเอกสาร: ${viewModel.selectedDocument?.documentName ?? ''}'), // Title แสดงชื่อเอกสารเดิม
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'ชื่อเอกสารใหม่'),
            onChanged: (value) {
              newDocumentName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('คัดลอก'),
              onPressed: () async {
                if (newDocumentName != null && newDocumentName!.isNotEmpty) {
                  final success =
                      await viewModel.copySelectedDocument(newDocumentName!);
                  if (success) {
                    Navigator.of(context).pop();
                  } else {
                    // จัดการข้อผิดพลาด
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Conditional title/search bar in AppBar
        title: _isSearching // ถ้ากำลังค้นหา, แสดง TextField, มิฉะนั้นแสดง Title
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ค้นหาเอกสาร...', // Placeholder text
                  border: InputBorder.none, // ไม่มีเส้นขอบเพื่อความสะอาด
                  hintStyle:
                      TextStyle(color: Colors.white70), // สไตล์ของ placeholder
                ),
                style: const TextStyle(
                    color: Colors.white, fontSize: 18.0), // สไตล์ข้อความที่ป้อน
                onChanged:
                    (value) {}, // การเปลี่ยนแปลงข้อความถูกจัดการโดย addListener
                autofocus: true, // โฟกัสอัตโนมัติเมื่อ Search Bar ปรากฏ
              )
            : Text(widget.title), // Title เดิมของหน้าจอ

        actions: [
          // Search icon
          IconButton(
            icon: Icon(_isSearching
                ? Icons.close
                : Icons.search), // เปลี่ยนไอคอนตามสถานะการค้นหา
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching; // สลับสถานะการแสดงผล Search Bar
                if (!_isSearching) {
                  _searchController
                      .clear(); // ล้างข้อความค้นหาเมื่อปิด Search Bar
                  Provider.of<DocumentViewModel>(context, listen: false)
                      .setSearchQuery(''); // ล้างการค้นหาใน ViewModel
                }
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DocumentViewModel>(context, listen: false)
                  .refreshDocuments(); // เรียก refresh ใน ViewModel
            },
          ),
          // NEW: Filter Button
          PopupMenuButton<DocumentFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Documents',
            onSelected: (DocumentFilter result) {
              Provider.of<DocumentViewModel>(context, listen: false)
                  .setFilter(result);
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<DocumentFilter>>[
              const PopupMenuItem<DocumentFilter>(
                value: DocumentFilter.all,
                child: Text('ทั้งหมด (All)'),
              ),
              const PopupMenuItem<DocumentFilter>(
                value: DocumentFilter.active,
                child: Text('กำลังดำเนินการ (Active)'),
              ),
              const PopupMenuItem<DocumentFilter>(
                value: DocumentFilter.closed,
                child: Text('เสร็จสิ้น (Closed)'),
              ),
            ],
          ),
          Consumer<DocumentViewModel>(
            // Consumer สำหรับฟังการเปลี่ยนแปลง selectedDocument
            builder: (context, viewModel, child) {
              // แสดง Popup Menu Button เฉพาะเมื่อมีเอกสารถูกเลือก
              if (viewModel.selectedDocument != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'copy') {
                      await _showCopyDocumentDialog(
                          context, viewModel); // แสดง Dialog คัดลอก
                    } else if (value == 'delete') {
                      // แสดง Dialog ยืนยันการลบ
                      final confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('ยืนยันการลบ'),
                            content: Text(
                                'คุณแน่ใจหรือไม่ว่าต้องการลบเอกสาร "${viewModel.selectedDocument!.documentName}"?'),
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
                        await viewModel
                            .deleteSelectedDocument(); // ลบเอกสารหากยืนยัน
                      }
                    }
                    viewModel.clearSelection(); // ล้างการเลือกหลังจากดำเนินการ
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'copy',
                      child: Text('คัดลอกเอกสาร'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      enabled: viewModel.selectedDocument?.status ==
                          0, // NEW: Disable if not 0
                      child: Text(
                        'ลบเอกสาร',
                        style: TextStyle(
                            color: viewModel.selectedDocument?.status == 0
                                ? null
                                : Colors.grey),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert), // ไอคอนสามจุดแนวตั้ง
                );
              }
              return const SizedBox.shrink(); // ซ่อนถ้าไม่มีเอกสารถูกเลือก
            },
          ),
        ],
      ),
      body: Consumer<DocumentViewModel>(
        // Consumer ฟังการเปลี่ยนแปลงใน DocumentViewModel และ rebuild builder
        builder: (context, viewModel, child) {
          // แสดง SnackBar สำหรับข้อความ Sync
          if (viewModel.syncMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.syncMessage!)),
              );
              viewModel.syncMessage =
                  null; // ล้างข้อความหลังจากแสดงเพื่อป้องกันการแสดงซ้ำ
            });
          }

          return Stack(
            // Stack สำหรับวาง Widgets ซ้อนทับกัน (ใช้สำหรับ Loading Overlay)
            children: [
              Column(
                // Column หลักสำหรับจัดเรียง UI ในแนวตั้ง
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.all(8.0), // <<< Changed padding to 8.0
                    child: Text(
                      viewModel.statusMessage,
                      style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.black), // <<< Changed text style
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    // Expanded ทำให้ ListView ใช้พื้นที่แนวตั้งที่เหลือทั้งหมด
                    child: StreamBuilder<List<DbDocument>>(
                      // StreamBuilder ฟัง stream ของเอกสารจาก ViewModel
                      stream: viewModel.documentsStream,
                      builder: (context, snapshot) {
                        if (viewModel.isLoading && !snapshot.hasData) {
                          // แสดง CircularProgressIndicator ถ้ากำลังโหลดข้อมูลเริ่มต้น
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // แสดงข้อผิดพลาดถ้า stream มีปัญหา
                          return Center(
                              child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          // แสดงข้อความถ้าไม่พบเอกสาร
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'ไม่พบเอกสาร (No Documents Found)',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'กดปุ่ม + เพื่อสร้างเอกสารใหม่',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // ถ้ามีข้อมูล, สร้างรายการเอกสาร
                          final documents = snapshot.data!;
                          return ListView.builder(
                            itemCount: documents.length,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            itemBuilder: (context, index) {
                              final document = documents[index];
                              return _buildDocumentCard(
                                  context, document, viewModel);
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
      floatingActionButton: Consumer<DocumentViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton.extended(
            onPressed: viewModel.isLoading
                ? null
                : () => _showCreateNewDocumentDialog(context, viewModel),
            label: const Text('New Document'),
            icon: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(
      BuildContext context, DbDocument document, DocumentViewModel viewModel) {
    bool isSelected = viewModel.selectedDocument == document;
    bool isClosed = document.status >= 2;
    Color statusColor = isClosed ? Colors.grey : Colors.green;
    String statusText = isClosed ? "Closed" : "Active";

    return Card(
      elevation: isSelected ? 8.0 : 2.0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2.0)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (viewModel.selectedDocument == document) {
            viewModel.clearSelection();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentMachineScreen(
                  title: 'Machines: ${document.documentName ?? 'N/A'}',
                  jobId: document.jobId ?? '',
                  documentId: document.documentId ?? '',
                ),
              ),
            );
          } else {
            viewModel.selectDocument(document);
          }
        },
        onLongPress: () {
          viewModel.selectDocument(document);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 6.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        document.documentName ?? 'Untitled Document',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Divider(color: Colors.grey.withOpacity(0.2)),
                const SizedBox(height: 8.0),
                _buildInfoRow(
                    Icons.event,
                    "Created: ${_formatDate(document.createDate)}",
                    Colors.grey[700]),
                const SizedBox(height: 4.0),
                _buildInfoRow(Icons.work_outline,
                    "Job ID: ${document.jobId ?? '-'}", Colors.grey[700]),
                const SizedBox(height: 4.0),
                if (document.userId != null)
                  _buildInfoRow(Icons.person_outline,
                      "User: ${document.userId}", Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color? color) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: color ?? Colors.grey),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown Date";
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return isoDate;
    }
  }
}
