// lib/ui/documentmachine/document_machine_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentmachine/document_machine_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/document_machine_table.dart'; // สำหรับ DbDocumentMachine
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/document_record_screen.dart'; // สำหรับนำทางไป DocumentRecordScreen
import 'package:biochecksheet7_flutter/presentation/screens/documentmachine/widgets/machine_card.dart';

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

  Future<void> _showCloseJobConfirmationDialog(
      BuildContext context, DocumentMachineViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันปิดงาน'),
        content: const Text(
            'คุณต้องการปิดงานนี้ใช่หรือไม่?\nหากปิดงานแล้วจะไม่สามารถแก้ไขข้อมูลได้อีก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ยืนยันปิดงาน'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final error = await viewModel.closeJob();
      if (context.mounted) {
        if (error == null) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ปิดงานเรียบร้อยแล้ว'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(); // Go back to document list
        } else {
          // Failure
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ไม่สามารถปิดงานได้'),
              content: Text(error),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          );
        }
      }
    }
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
          ],
        ),
        floatingActionButton: Consumer<DocumentMachineViewModel>(
          builder: (context, viewModel, child) {
            // NEW: If job is closed, hide the button
            if (viewModel.isJobClosed) {
              return Container(); // Or null if strictly FAB
            }
            return FloatingActionButton.extended(
              onPressed: viewModel.isLoading
                  ? null
                  : () => _showCloseJobConfirmationDialog(context, viewModel),
              label: const Text('ปิดงาน'),
              icon: const Icon(Icons.check_circle),
              backgroundColor: Colors.green,
            );
          },
        ),
        body: SafeArea(
          child: Consumer<DocumentMachineViewModel>(
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
                        padding: const EdgeInsets.all(
                            8.0), // <<< Changed padding to 8.0
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
                                  child:
                                      Text('ไม่พบเครื่องจักรสำหรับเอกสารนี้.'));
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
                                  final machine = machines[index];
                                  return MachineCard(
                                    machine: machine,
                                    onTap: () {
                                      print(
                                          'แตะเครื่องจักร: ${machine.machineName}');
                                      String routeName = '/document_record';
                                      String title =
                                          'Record: ${machine.machineName ?? ''}';

                                      if (machine.uiType == 1) {
                                        routeName = '/am_checksheet';
                                        title =
                                            'AM Check: ${machine.machineName ?? ''}';
                                      }

                                      Navigator.pushNamed(
                                        context,
                                        routeName,
                                        arguments: {
                                          'title': title,
                                          'documentId': widget.documentId,
                                          'machineId': machine.machineId,
                                          'jobId': widget.jobId,
                                        },
                                      );
                                    },
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
                      color:
                          Colors.black.withOpacity(0.5), // พื้นหลังสีดำโปร่งแสง
                      alignment: Alignment
                          .center, // จัดวาง CircularProgressIndicator ตรงกลาง
                      child:
                          const CircularProgressIndicator(), // Loading spinner
                    ),
                ],
              );
            },
          ),
        ));
  }
}
