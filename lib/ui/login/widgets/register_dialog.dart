// lib/ui/login/widgets/register_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/ui/widgets/error_dialog.dart'; // Import ErrorDialog

/// Dialog สำหรับการลงทะเบียนผู้ใช้ใหม่.
class RegisterDialog extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const RegisterDialog({
    super.key,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  @override
  void initState() {
    super.initState();
    // Clear controllers when dialog opens
    widget.usernameController.clear();
    widget.passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ลงทะเบียนผู้ใช้ใหม่'),
      content: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          // Show SnackBar/ErrorDialog for registration messages
          if (viewModel.registerMessage != null) {
            // CRUCIAL FIX: Capture the message before async operation
            final String currentRegisterMessage = viewModel.registerMessage!;

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // Make callback async
              if (mounted) {
                bool isError =
                    currentRegisterMessage.toLowerCase().contains('ล้มเหลว') ||
                        currentRegisterMessage.toLowerCase().contains('error');

                if (isError) {
                  await showDialog(
                    // Await the dialog to close
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return ErrorDialog(
                        title: 'ลงทะเบียนไม่สำเร็จ',
                        message: currentRegisterMessage, // Use captured message
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            currentRegisterMessage)), // Use captured message
                  );
                  // Optional: Close dialog on successful registration
                  Navigator.of(context).pop();
                }
                // CRUCIAL FIX: Clear message AFTER dialog/snackbar has been shown and potentially closed.
                viewModel.registerMessage = null;
              }
            });
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column take minimum space
              children: [
                TextField(
                  controller: widget.usernameController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสพนักงาน (Username)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: widget.passwordController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: viewModel
                          .loginFormState.isLoading // Use general loading state
                      ? null
                      : () {
                          viewModel.register(
                            widget.usernameController.text,
                            widget.passwordController.text,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.loginFormState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ลงทะเบียน'),
                ),
              ],
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('ยกเลิก'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}
