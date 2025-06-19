// lib/ui/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';

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

    // <<< ลบบรรทัดนี้ออก: ไม่จำเป็นต้องเรียก checkLoggedInUser จาก initState ของ LoginScreen แล้ว
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<LoginViewModel>(context, listen: false).checkLoggedInUser();
    // });
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

  void _onLoginPressed() async { // <<< Make async to await login result
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    await viewModel.login(
      _usernameController.text,
      _passwordController.text,
    );
    // <<< เพิ่ม Logic การนำทางหลัง Login สำเร็จที่นี่
    if (viewModel.loggedInUser != null && mounted) { // Check mounted to avoid error if widget is disposed
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _onSyncUsersPressed() {
    Provider.of<LoginViewModel>(context, listen: false).syncUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        // Show SnackBar for login errors
        if (viewModel.loginError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.loginError!)),
            );
            viewModel.loginDataChanged(_usernameController.text, _passwordController.text);
          });
        }

        // Show SnackBar for sync messages
        if (viewModel.syncMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.syncMessage!)),
            );
            viewModel.loginDataChanged(_usernameController.text, _passwordController.text);
          });
        }

        // <<< ลบ Logic การนำทางอัตโนมัติจากตรงนี้ออก:
        // if (viewModel.loggedInUser != null) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     Navigator.of(context).pushReplacementNamed('/home');
        //   });
        // }

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
                  const FlutterLogo(size: 100),
                  const SizedBox(height: 24.0),

                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: viewModel.loginFormState.usernameError,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
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
                    onSubmitted: (_) => _onLoginPressed(),
                  ),
                  const SizedBox(height: 24.0),

                  ElevatedButton(
                    onPressed: viewModel.loginFormState.isDataValid && !viewModel.loginFormState.isLoading
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

                  TextButton(
                    onPressed: () {
                      print('Register button pressed');
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