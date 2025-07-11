// lib/ui/documentmachine/document_machine_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/documentmachine/document_machine_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart'; // สำหรับ DbDocumentMachine
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_screen.dart'; // สำหรับนำทางไป DocumentRecordScreen

/// เทียบเท่ากับ DocumentMachineActivity.kt ในโปรเจกต์ Kotlin เดิม
/// หน้าจอนี้แสดงรายการเครื่องจักรที่เกี่ยวข้องกับเอกสารและ Job ที่ระบุ
class DocumentMachineScreen extends StatefulWidget {
  final String title; // ชื่อหน้าจอที่จะแสดงใน AppBar
  final String jobId; // รหัส Job ที่จำเป็น
  final String documentId; // รหัสเอกสารที่จำเป็น

  const DocumentMachineScreen({
    super.key,
    required this.title,
    required this.jobId,
    required this.documentId,
  });

  @override
  State<DocumentMachineScreen> createState() => _DocumentMachineScreenState();
}

class _DocumentMachineScreenState extends State<DocumentMachineScreen> {
  @override
  void initState() {
    super.initState();
    // เรียกโหลดเครื่องจักรเมื่อหน้าจอเริ่มต้น โดยส่ง documentId และ jobId ที่ได้รับมา
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentMachineViewModel>(context, listen: false)
          .loadMachines(widget.documentId, widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // แสดงชื่อหน้าจอใน AppBar
        actions: [
          // ปุ่ม Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DocumentMachineViewModel>(context, listen: false)
                  .refreshMachines(); // เรียก refresh ใน ViewModel
            },
          ),
          // TODO: เพิ่มไอคอนค้นหาที่นี่ หากมีการใช้งานฟังก์ชันค้นหาสำหรับเครื่องจักร
        ],
      ),
      body: Consumer<DocumentMachineViewModel>(
        // Consumer ฟังการเปลี่ยนแปลงใน DocumentMachineViewModel และ rebuild builder
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
                    child: StreamBuilder<List<DbDocumentMachine>>(
                      // StreamBuilder ฟัง stream ของรายการเครื่องจักรจาก ViewModel
                      stream: viewModel.machinesStream,
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
                          // แสดงข้อความถ้าไม่พบเครื่องจักรสำหรับเอกสารนี้
                          return const Center(
                              child: Text('ไม่พบเครื่องจักรสำหรับเอกสารนี้.'));
                        } else {
                          // ถ้ามีข้อมูล, สร้างรายการเครื่องจักร
                          final machines = snapshot.data!;
                          return ListView.builder(
                            itemCount:
                                machines.length, // จำนวนเครื่องจักรในรายการ
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0), // Padding สำหรับทั้งรายการ
                            itemBuilder: (context, index) {
                              final machine = machines[
                                  index]; // ได้รับรายการเครื่องจักรปัจจุบัน
                              // แสดงแต่ละเครื่องจักรเป็น Card คล้ายกับ document_machine_fragment_item.xml
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical:
                                        8.0), // ระยะห่างแนวตั้งระหว่าง Card
                                elevation: 4.0, // เพิ่มเงาให้กับ Card
                                child: InkWell(
                                  // InkWell ให้ผลตอบรับด้วยภาพเมื่อแตะ Card
                                  onTap: () {
                                    // นำทางไปยัง DocumentRecordScreen เมื่อแตะเครื่องจักร
                                    print(
                                        'แตะเครื่องจักร: ${machine.machineName}');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DocumentRecordScreen(
                                          title:
                                              'บันทึก: ${machine.machineName ?? 'N/A'}', // Title สำหรับหน้า Record
                                          documentId: widget
                                              .documentId, // ส่ง documentId ปัจจุบัน
                                          machineId: machine.machineId ?? '',
                                          jobId: viewModel.jobId ??
                                              '', // <<< ส่ง jobId ไปด้วย // ส่ง machineId ของเครื่องจักรที่แตะ
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        16.0), // Padding ภายในเนื้อหา Card
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start, // จัดข้อความชิดซ้าย
                                      children: [
                                        Text(
                                          machine.machineName ??
                                              'N/A', // แสดงชื่อเครื่องจักร
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight
                                                      .bold), // ชื่อตัวหนา
                                        ),
                                        const SizedBox(
                                            height:
                                                4.0), // ช่องว่างแนวตั้งเล็กน้อย
                                        Text(
                                            'รหัสเครื่องจักร: ${machine.machineId ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall), // แสดงรหัสเครื่องจักร
                                        Text(
                                            'ประเภท: ${machine.machineType ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall), // แสดงประเภท
                                        Text(
                                            'คำอธิบาย: ${machine.description ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall), // แสดงคำอธิบาย
                                        Text(
                                            'ข้อมูลจำเพาะ: ${machine.specification ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall), // แสดงข้อมูลจำเพาะ
                                        Text(
                                            'สถานะ: ${machine.status ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall), // แสดงสถานะ
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
                  alignment: Alignment
                      .center, // จัดวาง CircularProgressIndicator ตรงกลาง
                  child: const CircularProgressIndicator(), // Loading spinner
                ),
            ],
          );
        },
      ),
    );
  }
}
