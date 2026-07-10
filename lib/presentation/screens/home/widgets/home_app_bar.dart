// lib/ui/home/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_viewmodel.dart';
import 'package:biochecksheet7_flutter/presentation/screens/notifications/notifications_viewmodel.dart'; // <<< NEW

/// Custom AppBar for HomeScreen, handling title, search, and action buttons.
class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final VoidCallback onRefreshPressed;
  final VoidCallback onImagePressed;
  final VoidCallback onUploadPressed;
  final VoidCallback onLogoutPressed;
  final VoidCallback onCustomJobPressed;
  final bool showFullMenu;

  const HomeAppBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onRefreshPressed,
    required this.onImagePressed,
    required this.onUploadPressed,
    required this.onLogoutPressed,
    required this.onCustomJobPressed,
    this.showFullMenu = true,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}

class _HomeAppBarState extends State<HomeAppBar> {
  bool _isSearching = false; // State to control search bar visibility

  // Helper method เพื่อสร้างปุ่มให้มีขนาดกะทัดรัด (ป้องการการล้นหน้าจอ)
  Widget _buildIconButton({
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero, // ลด Padding เพื่อให้ปุ่มอยู่ใกล้กัน
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
        Provider.of<HomeViewModel>(context); // Listen to ViewModel changes.

    // 1. เตรียมปุ่มทั้งหมดที่จะแสดง
    final List<Widget> menuButtons = [];

    // ปุ่มค้นหา
    menuButtons.add(_buildIconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        setState(() {
          _isSearching = true; // เปิดโหมดค้นหา
        });
      },
    ));

    // ปุ่มแจ้งเตือน (เฉพาะหน้า Home)
    if (widget.showFullMenu) {
      menuButtons.add(
        Consumer<NotificationsViewModel>(
          builder: (context, notificationViewModel, child) {
            return _buildIconButton(
              icon: Badge(
                isLabelVisible: notificationViewModel.unreadCount > 0,
                label: Text(notificationViewModel.unreadCount.toString()),
                child: const Icon(Icons.notifications),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            );
          },
        ),
      );
    }

    // ปุ่มรีเฟรช (แสดงทั้ง Home และ Case)
    menuButtons.add(_buildIconButton(
      icon: const Icon(Icons.refresh),
      onPressed: widget.onRefreshPressed,
    ));

    // ปุ่มที่เหลือแสดงเฉพาะหน้า Home
    if (widget.showFullMenu) {
      menuButtons.add(_buildIconButton(
        icon: const Icon(Icons.add_task),
        tooltip: 'Custom Job',
        onPressed: widget.onCustomJobPressed,
      ));
      menuButtons.add(_buildIconButton(
        icon: const Icon(Icons.cloud_sync_sharp),
        tooltip: 'Sync Master Images',
        onPressed: widget.onImagePressed,
      ));
      menuButtons.add(_buildIconButton(
        icon: const Icon(Icons.cloud_upload),
        onPressed: viewModel.isLoading ? null : widget.onUploadPressed,
      ));
      menuButtons.add(_buildIconButton(
        icon: const Icon(Icons.logout),
        onPressed: widget.onLogoutPressed,
      ));
    }

    // 2. จัดการ Layout ว่าจะแสดง Title และ Actions อย่างไร
    Widget titleWidget;
    List<Widget>? actionsList;

    if (_isSearching) {
      // โหมดกำลังค้นหา: ให้ช่องค้นหาใช้พื้นที่ Title ทั้งหมด และแสดงแค่ปุ่มปิด(กากบาท)ที่ Actions
      titleWidget = TextField(
        controller: widget.searchController,
        decoration: InputDecoration(
          hintText: 'ค้นหา...',
          hintStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          isDense: true,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16.0),
        onChanged: (value) {
          viewModel.setSearchQuery(value);
        },
        autofocus: true,
      );

      actionsList = [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSearching = false; // ปิดโหมดค้นหา
              widget.searchController.clear();
              viewModel.setSearchQuery('');
            });
          },
        ),
      ];
    } else {
      // โหมดปกติ (ไม่ได้ค้นหา)
      if (widget.showFullMenu) {
        // หน้า Home: ไม่มีข้อความ Title ให้เอากลุ่มปุ่มทั้งหมดมาวางตรงกลาง
        titleWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal, // กันล้นจอกรณีจอมือถือเล็กมาก
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: menuButtons,
          ),
        );
        actionsList = null; // ปิด Actions ฝั่งขวา เพราะปุ่มไปอยู่ตรงกลางหมดแล้ว
      } else {
        // หน้า Case: แสดงข้อความ Title ตามปกติ และเอาปุ่มไว้ฝั่งขวา (Actions)
        titleWidget = Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        );
        actionsList = menuButtons; // ปุ่มค้นหากับรีเฟรชไปอยู่ฝั่งขวา
      }
    }

    return AppBar(
      backgroundColor: Colors.blue.shade900,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      centerTitle:
          widget.showFullMenu && !_isSearching, // บังคับปุ่มให้อยู่กึ่งกลางเป๊ะ
      title: titleWidget,
      actions: actionsList,
    );
  }
}
