// lib/ui/login/login_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // Import both LoginResult and SyncResult
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/ui/login/login_form_state.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // <<< เพิ่มบรรทัดนี้
import 'package:biochecksheet7_flutter/ui/login/login_screen.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginRepository _loginRepository;

  LoginFormState _loginFormState = LoginFormState.initial;
  LoginFormState get loginFormState => _loginFormState;

  LoginViewModel({LoginRepository? loginRepository})
      : _loginRepository = loginRepository ?? LoginRepository();

  LoggedInUser? _loggedInUser;
  LoggedInUser? get loggedInUser => _loggedInUser;

  String? _loginError;
  String? get loginError => _loginError;

  String? _syncMessage;
  String? get syncMessage => _syncMessage;

   String? _loginMessage;
  String? get loginMessage => _loginMessage;
  set loginMessage(String? value) {
    _loginMessage = value;
    notifyListeners();
  }

  Future<void> checkLoggedInUser() async {
    final user = await _loginRepository.getLoggedInUserFromLocal();
    if (user != null) {
      _loggedInUser = user;
      notifyListeners();
    }
  }

  void loginDataChanged(String username, String password) {
    _loginError = null;
    _loggedInUser = null;
    _syncMessage = null;

    String? usernameError;
    String? passwordError;
    bool isDataValid = true;

    if (username.isEmpty) {
      usernameError = "Username cannot be empty";
      isDataValid = false;
    } else if (!isUserNameValid(username)) {
      usernameError = "Invalid username format";
      isDataValid = false;
    }

    if (password.isEmpty) {
      passwordError = "Password cannot be empty";
      isDataValid = false;
    } else if (!isPasswordValid(password)) {
      passwordError = "Password must be > 5 characters";
      isDataValid = false;
    }

    _loginFormState = _loginFormState.copyWith(
      usernameError: usernameError,
      passwordError: passwordError,
      isDataValid: isDataValid,
      isLoading: false,
    );
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _loginFormState = _loginFormState.copyWith(isLoading: true);
    notifyListeners();

    final result = await _loginRepository.login(username, password);

    if (result is LoginSuccess) {
      _loggedInUser = result.loggedInUser;
      _loginError = null;
      _loginFormState = _loginFormState.copyWith(
        isDataValid: true,
        isLoading: false,
      );
    } else if (result is LoginFailed) {
      _loggedInUser = null;
      _loginError = result.errorMessage;
      _loginFormState = _loginFormState.copyWith(
        isLoading: false,
      );
    } else if (result is LoginError) {
      _loggedInUser = null;
      _loginError = result.exception.toString();
      _loginFormState = _loginFormState.copyWith(
        isLoading: false,
      );
    }
    notifyListeners();
  }

  // New method to trigger user sync
  Future<void> syncUsers() async {
    _loginFormState = _loginFormState.copyWith(isLoading: true);
    _syncMessage = null;
    _loginError = null;
    notifyListeners();

    final result = await _loginRepository.syncUsers();

    if (result is SyncSuccess) { // Check specifically for SyncSuccess
      _syncMessage = "User data synced successfully!";
    } else if (result is SyncFailed) { // Check specifically for SyncFailed
      _syncMessage = "Sync failed: ${result.errorMessage}"; // Access errorMessage safely
    } else if (result is SyncError) { // Check specifically for SyncError
      _syncMessage = "Sync error: ${result.exception.toString()}"; // Access exception safely
    }
    _loginFormState = _loginFormState.copyWith(isLoading: false);
    notifyListeners();
  }

 
  

  bool isUserNameValid(String username) {
    return username.isNotEmpty && username.length > 3;
  }

  bool isPasswordValid(String password) {
    return password.isNotEmpty && password.length > 5;
  }

    /// Logout method for LoginViewModel.
  /// Clears user data and navigates to the login screen.
  Future<void> logout(BuildContext context) async { // <<< CRUCIAL FIX: Add BuildContext parameter
    _loginFormState = _loginFormState.copyWith(isLoading: true);
    _loginMessage = null;
    notifyListeners();

    try {
      await _loginRepository.logout(); // Call logout on the repository
      _loggedInUser = null; // Clear logged in user
      _loginMessage = 'Logged out successfully.';

      // CRUCIAL FIX: Navigate back to the login screen and remove all previous routes.
      // This ensures a clean navigation stack.
      if (context.mounted) { // Check if context is still valid
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to LoginScreen
          (Route<dynamic> route) => false, // Remove all routes from stack
        );
      }
    } catch (e) {
      _loginMessage = 'Logout failed: $e';
    } finally {
      _loginFormState = _loginFormState.copyWith(isLoading: false);
      notifyListeners();
    }
  }
}