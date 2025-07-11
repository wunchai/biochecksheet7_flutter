// lib/ui/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/ui/main_wrapper/main_wrapper_screen.dart';
import 'package:biochecksheet7_flutter/ui/widgets/error_dialog.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // <<< NEW: Import LoginResult
import 'package:biochecksheet7_flutter/ui/login/widgets/register_dialog.dart'; // <<< NEW: Import RegisterDialog

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onLoginDataChanged);
    _passwordController.addListener(_onLoginDataChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onLoginDataChanged);
    _passwordController.removeListener(_onLoginDataChanged);
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _onLoginDataChanged() {
    Provider.of<LoginViewModel>(context, listen: false).loginDataChanged(
      _usernameController.text,
      _passwordController.text,
    );
  }

  void _onLoginPressed() async {
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);

    // CRUCIAL FIX: Get LoginResult directly from viewModel.login()
    final LoginResult loginResult = await viewModel.login(
      // <<< Get the result
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      // Ensure widget is still mounted before navigating or showing dialog
      if (loginResult is LoginSuccess) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainWrapperScreen()),
          (Route<dynamic> route) => false,
        );
      } else if (loginResult is LoginFailed) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return ErrorDialog(
              title: 'เข้าสู่ระบบล้มเหลว',
              message:
                  loginResult.errorMessage, // LoginFailed has 'error' property
            );
          },
        );
      } else if (loginResult is LoginError) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return ErrorDialog(
              title: 'ข้อผิดพลาด',
              message:
                  'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: ${loginResult.exception}', // LoginError has 'exception'
            );
          },
        );
      }
    }
    // No need to clear loginMessage here, as it's not used for error display anymore.
  }

  void _onSyncUsersPressed() async {
    // Make this async to await sync result
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    await viewModel.syncUsers(); // Await the sync operation

    if (mounted) {
      // Ensure widget is still mounted
      // Handle sync message/error after sync completes
      if (viewModel.syncMessage != null) {
        bool isError =
            viewModel.syncMessage!.toLowerCase().contains('failed') ||
                viewModel.syncMessage!.toLowerCase().contains('error');

        if (isError) {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return ErrorDialog(
                title: 'ข้อผิดพลาดในการซิงค์ข้อมูล',
                message: viewModel.syncMessage!,
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(viewModel.syncMessage!)),
          );
        }
        // Clear syncMessage from ViewModel after showing
        viewModel.syncMessage = null; // Direct assignment is fine here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        // REMOVED: Old loginMessage handling as it's now done in _onLoginPressed
        // if (viewModel.loginMessage != null) { ... }

        // REMOVED: Old syncMessage handling as it's now done in _onSyncUsersPressed
        // if (viewModel.syncMessage != null) { ... }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Login'),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32.0),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: viewModel.loginFormState.usernameError,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onChanged: (text) {
                      _onLoginDataChanged();
                    },
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: viewModel.loginFormState.passwordError,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (text) {
                      _onLoginDataChanged();
                    },
                    onSubmitted: (_) => _onLoginPressed(),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: viewModel.loginFormState.isDataValid &&
                            !viewModel.loginFormState.isLoading
                        ? _onLoginPressed
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: viewModel.loginFormState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 16.0),
                  OutlinedButton(
                    onPressed: viewModel.loginFormState.isLoading
                        ? null
                        : _onSyncUsersPressed,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.blue),
                    ),
                    child: viewModel.loginFormState.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Sync User Data'),
                  ),
                  const SizedBox(height: 16.0),
                  // NEW: Register Button (opens dialog)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return RegisterDialog(
                            // Pass new controllers for the dialog
                            usernameController: TextEditingController(),
                            passwordController: TextEditingController(),
                          );
                        },
                      );
                    },
                    child: const Text('Don\'t have an account? Register'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
