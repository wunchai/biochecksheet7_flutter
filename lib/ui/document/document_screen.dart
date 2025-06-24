// lib/ui/document/document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/document/document_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // สำหรับ DbDocument
import 'package:biochecksheet7_flutter/ui/documentmachine/document_machine_screen.dart'; // สำหรับนำทางไป DocumentMachineScreen

/// หน้าจอนี้แสดงรายการเอกสาร จัดการโดย DocumentViewModel.
/// เทียบเท่ากับ DocumentActivity.kt ในโปรเจกต์ Kotlin เดิม
class DocumentScreen extends StatefulWidget {
  final String title; // ชื่อหน้าจอที่จะแสดงใน AppBar
  final String? jobId; // ตัวเลือก: jobId เพื่อกรองเอกสารที่เกี่ยวข้องกับ Job เฉพาะ

  const DocumentScreen({super.key, required this.title, this.jobId});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final TextEditingController _searchController = TextEditingController(); // Controller สำหรับ TextField ค้นหา
  bool _isSearching = false; // สถานะควบคุมการแสดงผลของ Search Bar

  @override
  void initState() {
    super.initState();
    // เรียกโหลดเอกสารเมื่อหน้าจอเริ่มต้น โดยส่ง jobId หากมี
    // listen: false เพราะเราเรียกใช้ method เท่านั้น ไม่ได้ฟังการ rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentViewModel>(context, listen: false).loadDocuments(widget.jobId);
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
    Provider.of<DocumentViewModel>(context, listen: false).setSearchQuery(_searchController.text);
  }

  // แสดง Dialog สำหรับสร้างเอกสารใหม่
  Future<void> _showCreateNewDocumentDialog(BuildContext context, DocumentViewModel viewModel) async {
    String? newDocumentName;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('สร้างเอกสารใหม่'), // Title ของ Dialog
          content: TextField(
            autofocus: true, // โฟกัสอัตโนมัติเมื่อ Dialog เปิด
            decoration: const InputDecoration(hintText: 'ชื่อเอกสาร'), // Placeholder Text
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
                  final success = await viewModel.createNewDocument(newDocumentName!);
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

  // แสดง Dialog สำหรับคัดลอกเอกสาร
  Future<void> _showCopyDocumentDialog(BuildContext context, DocumentViewModel viewModel) async {
    String? newDocumentName;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('คัดลอกเอกสาร: ${viewModel.selectedDocument?.documentName ?? ''}'), // Title แสดงชื่อเอกสารเดิม
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
                  final success = await viewModel.copySelectedDocument(newDocumentName!);
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
                  hintStyle: TextStyle(color: Colors.white70), // สไตล์ของ placeholder
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18.0), // สไตล์ข้อความที่ป้อน
                onChanged: (value) {}, // การเปลี่ยนแปลงข้อความถูกจัดการโดย addListener
                autofocus: true, // โฟกัสอัตโนมัติเมื่อ Search Bar ปรากฏ
              )
            : Text(widget.title), // Title เดิมของหน้าจอ

        actions: [
          // Search icon
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search), // เปลี่ยนไอคอนตามสถานะการค้นหา
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching; // สลับสถานะการแสดงผล Search Bar
                if (!_isSearching) {
                  _searchController.clear(); // ล้างข้อความค้นหาเมื่อปิด Search Bar
                  Provider.of<DocumentViewModel>(context, listen: false).setSearchQuery(''); // ล้างการค้นหาใน ViewModel
                }
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DocumentViewModel>(context, listen: false).refreshDocuments(); // เรียก refresh ใน ViewModel
            },
          ),
          Consumer<DocumentViewModel>( // Consumer สำหรับฟังการเปลี่ยนแปลง selectedDocument
            builder: (context, viewModel, child) {
              // แสดง Popup Menu Button เฉพาะเมื่อมีเอกสารถูกเลือก
              if (viewModel.selectedDocument != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'copy') {
                      await _showCopyDocumentDialog(context, viewModel); // แสดง Dialog คัดลอก
                    } else if (value == 'delete') {
                      // แสดง Dialog ยืนยันการลบ
                      final confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('ยืนยันการลบ'),
                            content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบเอกสาร "${viewModel.selectedDocument!.documentName}"?'),
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
                        await viewModel.deleteSelectedDocument(); // ลบเอกสารหากยืนยัน
                      }
                    }
                    viewModel.clearSelection(); // ล้างการเลือกหลังจากดำเนินการ
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'copy',
                      child: Text('คัดลอกเอกสาร'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('ลบเอกสาร'),
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
              viewModel.syncMessage = null; // ล้างข้อความหลังจากแสดงเพื่อป้องกันการแสดงซ้ำ
            });
          }

          return Stack(
            // Stack สำหรับวาง Widgets ซ้อนทับกัน (ใช้สำหรับ Loading Overlay)
            children: [
              Column(
                // Column หลักสำหรับจัดเรียง UI ในแนวตั้ง
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Padding รอบข้อความสถานะ
                    child: Text(
                      viewModel.statusMessage, // แสดงข้อความสถานะจาก ViewModel
                      style: Theme.of(context).textTheme.headlineSmall, // ใช้สไตล์หัวข้อ
                      textAlign: TextAlign.center, // จัดข้อความให้อยู่กึ่งกลาง
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
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // แสดงข้อผิดพลาดถ้า stream มีปัญหา
                          return Center(child: Text('ข้อผิดพลาด: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          // แสดงข้อความถ้าไม่พบเอกสาร
                          return const Center(child: Text('ไม่พบเอกสาร.'));
                        } else {
                          // ถ้ามีข้อมูล, สร้างรายการเอกสาร
                          final documents = snapshot.data!;
                          return ListView.builder(
                            itemCount: documents.length, // จำนวนเอกสารในรายการ
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Padding สำหรับทั้งรายการ
                            itemBuilder: (context, index) {
                              final document = documents[index]; // ได้รับรายการเอกสารปัจจุบัน
                              // แสดงแต่ละเอกสารเป็น Card คล้ายกับ document_fragment_item.xml
                              return Card(
                                // ไฮไลต์เอกสารที่ถูกเลือก
                                color: viewModel.selectedDocument == document
                                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.2) // สีไฮไลต์
                                    : null, // ไม่มีไฮไลต์
                                margin: const EdgeInsets.symmetric(vertical: 8.0), // ระยะห่างแนวตั้งระหว่าง Card
                                elevation: 4.0, // เพิ่มเงาให้กับ Card
                                child: InkWell(
                                  // InkWell ให้ผลตอบรับด้วยภาพเมื่อแตะ Card
                                  onTap: () {
                                    // เมื่อแตะ, เลือกเอกสาร (ถ้ายังไม่ได้เลือก) หรือไปยังรายละเอียด
                                    if (viewModel.selectedDocument == document) {
                                      // ถ้าถูกเลือกอยู่แล้ว, นำทางไปยังหน้ารายละเอียด (DocumentRecordScreen)
                                      print('นำทางไปยังรายละเอียดของ: ${document.documentName}');
                                      viewModel.clearSelection(); // ล้างการเลือกหลังจากการนำทาง
                                      
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DocumentMachineScreen( // นำทางไป DocumentMachineScreen
                                            title: 'เครื่องจักรสำหรับ ${document.documentName ?? 'N/A'}',
                                            jobId: document.jobId ?? '', // ส่ง jobId
                                            documentId: document.documentId ?? '', // ส่ง documentId
                                          ),
                                        ),
                                      );
                                    } else {
                                      viewModel.selectDocument(document); // เลือกเอกสาร
                                    }
                                  },
                                  onLongPress: () {
                                    // เมื่อกดค้าง, เลือกเอกสารเพื่อแสดงเมนูตัวเลือก
                                    viewModel.selectDocument(document);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0), // Padding ภายในเนื้อหา Card
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // จัดข้อความชิดซ้าย
                                      children: [
                                        Text(
                                          document.documentName ?? 'N/A', // แสดงชื่อเอกสาร
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // ชื่อตัวหนา
                                        ),
                                        const SizedBox(height: 4.0), // ช่องว่างแนวตั้งเล็กน้อย
                                        Text('รหัสเอกสาร: ${document.documentId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // แสดงรหัสเอกสาร
                                        Text('รหัส Job: ${document.jobId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // แสดงรหัส Job ที่เกี่ยวข้อง
                                        Text('รหัสผู้ใช้: ${document.userId ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // แสดงรหัสผู้ใช้
                                        Text('วันที่สร้าง: ${document.createDate ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // แสดงวันที่สร้าง
                                        Text('สถานะ: ${document.status ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall), // แสดงสถานะเอกสาร
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Loading overlay ที่ปรากฏทับเนื้อหาเมื่อ isLoading เป็น true
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5), // พื้นหลังสีดำโปร่งแสง
                  alignment: Alignment.center, // จัดวาง CircularProgressIndicator ตรงกลาง
                  child: const CircularProgressIndicator(), // Loading spinner
                ),
            ],
          );
        },
      ),
      // Floating Action Button สำหรับสร้างเอกสารใหม่
      floatingActionButton: Consumer<DocumentViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton(
            onPressed: viewModel.isLoading
                ? null // ปิดการใช้งานปุ่มถ้ากำลังโหลด
                : () => _showCreateNewDocumentDialog(context, viewModel), // แสดง Dialog สร้างเอกสารใหม่
            child: const Icon(Icons.add), // ไอคอนเพิ่ม
          );
        },
      ),
    );
  }
}
