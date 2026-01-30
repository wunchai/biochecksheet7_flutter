// lib/ui/home/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_viewmodel.dart';

/// Custom AppBar for HomeScreen, handling title, search, and action buttons.
class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final VoidCallback onRefreshPressed;
  final VoidCallback onImagePressed;
  final VoidCallback onUploadPressed;
  final VoidCallback onLogoutPressed;

  const HomeAppBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onRefreshPressed,
    required this.onImagePressed,
    required this.onUploadPressed,
    required this.onLogoutPressed,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}

class _HomeAppBarState extends State<HomeAppBar> {
  bool _isSearching = false; // State to control search bar visibility

  @override
  Widget build(BuildContext context) {
    final viewModel =
        Provider.of<HomeViewModel>(context); // Listen to ViewModel changes.

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
      // Conditional title/search bar
      title: _isSearching
          ? TextField(
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
                viewModel
                    .setSearchQuery(value); // Call ViewModel's setSearchQuery
              },
              autofocus: true,
            )
          : Text(
              widget.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),

      actions: [
        // Search / Close Search Button
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                widget.searchController
                    .clear(); // Clear search text when closing
                viewModel.setSearchQuery(''); // Clear search in ViewModel
              }
            });
          },
        ),
        // Refresh Button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.onRefreshPressed,
        ),
        // Sync Master Images Button
        IconButton(
          icon: const Icon(Icons.cloud_sync_sharp), // <<< ไอคอนใหม่
          tooltip: 'Sync Master Images',
          onPressed: widget.onImagePressed,
        ),
        // Upload Document Records button
        IconButton(
          icon: const Icon(Icons.cloud_upload), // Use cloud_upload icon
          onPressed: viewModel.isLoading
              ? null // Disable if loading
              : widget.onUploadPressed, // Call the provided callback
        ),
        // Logout Button
        IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogoutPressed // Call the provided callback
            ),
      ],
    );
  }
}
