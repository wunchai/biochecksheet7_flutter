// lib/presentation/screens/problem/case_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:biochecksheet7_flutter/presentation/screens/mt_request/mt_request_view.dart';
import 'package:biochecksheet7_flutter/presentation/screens/mt_request/mt_request_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/problem_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/problem_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/widgets/error_dialog.dart';

/// Hub screen for the Bottom Navigation "Case" tab.
/// Switches between:
///   1) ปิดเคส / ซ่อมเอง (existing local ProblemScreen)
///   2) ใบแจ้งซ่อม MT (MtRequestView using CHECKSHEET_MT_REQUEST API)
class CaseHubScreen extends StatefulWidget {
  const CaseHubScreen({super.key});

  @override
  State<CaseHubScreen> createState() => _CaseHubScreenState();
}

class _CaseHubScreenState extends State<CaseHubScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showSyncResultFeedback(
      SyncStatus syncResult, String titlePrefix) async {
    final String? message = (syncResult is SyncSuccess)
        ? syncResult.message
        : (syncResult is SyncError ? syncResult.message : null);
    if (message == null || !mounted) return;

    final lower = message.toLowerCase();
    final isError = lower.contains('ล้มเหลว') ||
        lower.contains('ข้อผิดพลาด') ||
        lower.contains('failed') ||
        lower.contains('error') ||
        lower.contains('exception') ||
        lower.contains('timed out') ||
        lower.contains('ไม่สามารถเชื่อมต่อ');

    if (isError) {
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorDialog(
          title: '$titlePrefix ข้อผิดพลาด',
          message: message,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isProblemTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'จัดการ Case & ใบแจ้งซ่อม',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: isProblemTab
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'ซิงค์รายการ Case จากเซิร์ฟเวอร์',
                  onPressed: () async {
                    final vm = context.read<ProblemViewModel>();
                    final result = await vm.refreshProblems();
                    if (!mounted) return;
                    await _showSyncResultFeedback(result, 'การซิงค์ปัญหา');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'บันทึกการเปลี่ยนแปลงทั้งหมด',
                  onPressed: () async {
                    final vm = context.read<ProblemViewModel>();
                    final ok = await vm.saveAllProblemChanges();
                    if (!mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('บันทึกการเปลี่ยนแปลงสำเร็จ!')),
                      );
                    } else {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => const ErrorDialog(
                          title: 'บันทึกข้อมูลล้มเหลว',
                          message: 'โปรดตรวจสอบข้อผิดพลาดในแต่ละรายการปัญหา.',
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  tooltip: 'อัปโหลด Case ทั้งหมด',
                  onPressed: () async {
                    final vm = context.read<ProblemViewModel>();
                    final ok = await vm.uploadAllProblemsToServer();
                    if (!mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('การอัปโหลดสำเร็จ!')),
                      );
                    } else {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => const ErrorDialog(
                          title: 'การอัปโหลดปัญหา',
                          message: 'โปรดตรวจสอบข้อผิดพลาดในแต่ละรายการปัญหา.',
                        ),
                      );
                    }
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'รีเฟรชข้อมูลใบแจ้งซ่อม MT',
                  onPressed: () {
                    final mtVm = context.read<MtRequestViewModel>();
                    mtVm.loadRequests();
                    if (mtVm.hasLoadedCases) {
                      mtVm.loadCases();
                    }
                  },
                ),
              ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(
              icon: Icon(Icons.build_circle_outlined, size: 18),
              text: 'ปิดเคส / ซ่อมเอง',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined, size: 18),
              text: 'ใบแจ้งซ่อม MT',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProblemScreen(
            title: 'รายการ Case',
            showAppBar: false,
          ),
          MtRequestView(),
        ],
      ),
    );
  }
}
