// lib/ui/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For Provider package
import 'package:biochecksheet7_flutter/ui/login/login_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart'; // Assuming you might use this to navigate or display info

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
    // Listen for changes in the loginFormState to update UI validation
    _usernameController.addListener(_onLoginDataChanged);
    _passwordController.addListener(_onLoginDataChanged);

    // Optional: Check if user is already logged in when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LoginViewModel>(context, listen: false).checkLoggedInUser();
    });
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
    // This will trigger validation in the ViewModel as text changes
    Provider.of<LoginViewModel>(context, listen: false).loginDataChanged(
      _usernameController.text,
      _passwordController.text,
    );
  }

  void _onLoginPressed() {
    Provider.of<LoginViewModel>(context, listen: false).login(
      _usernameController.text,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to changes in LoginViewModel
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        // Show a SnackBar if there's a login error
        if (viewModel.loginError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.loginError!)),
            );
            // Clear the error after showing to prevent repeat
            // (You might want a more sophisticated way to clear errors in ViewModel)
            viewModel.loginDataChanged(_usernameController.text, _passwordController.text); // A simple way to clear the error by re-validating
          });
        }

        // Navigate to home screen on successful login
        if (viewModel.loggedInUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Navigate to your main app screen (e.g., HomeScreen or DashboardScreen)
            // Using pushReplacementNamed to prevent going back to login screen
            Navigator.of(context).pushReplacementNamed('/home'); // Assuming '/home' is your main route
          });
        }

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
                  // Logo or app icon (e.g., from ic_launcher2.xml, adjust assets in pubspec.yaml)
                  const FlutterLogo(size: 100), // Placeholder
                  const SizedBox(height: 24.0),

                  // Username/User Code Input
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: viewModel.loginFormState.usernameError,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text, // Equivalent to textPersonName
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(), // Move to next field
                  ),
                  const SizedBox(height: 16.0),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: viewModel.loginFormState.passwordError,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true, // Equivalent to password field
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onLoginPressed(), // Trigger login on done
                  ),
                  const SizedBox(height: 24.0),

                  // Login Button
                  ElevatedButton(
                    onPressed: viewModel.loginFormState.isDataValid && !viewModel.loginFormState.isLoading
                        ? _onLoginPressed
                        : null, // Disable button if data is invalid or loading
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50), // Make button wider
                    ),
                    child: viewModel.loginFormState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 16.0),

                  // Optional: Register button or forgot password
                  TextButton(
                    onPressed: () {
                      // Handle register/forgot password navigation
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