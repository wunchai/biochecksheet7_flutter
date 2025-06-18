// lib/ui/login/login_viewmodel.dart
import 'package:flutter/material.dart'; // For ChangeNotifier
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // Your LoginRepository
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // Your LoginResult
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart'; // Your LoggedInUser
import 'package:biochecksheet7_flutter/ui/login/login_form_state.dart'; // Your LoginFormState

/// Equivalent to LoginViewModel.kt
class LoginViewModel extends ChangeNotifier {
  final LoginRepository _loginRepository;

  LoginFormState _loginFormState = LoginFormState.initial;
  LoginFormState get loginFormState => _loginFormState;

  LoginViewModel({LoginRepository? loginRepository})
      : _loginRepository = loginRepository ?? LoginRepository(); // Use provided or default instance

  // Event for successful login (for UI to react)
  LoggedInUser? _loggedInUser;
  LoggedInUser? get loggedInUser => _loggedInUser;

  // Event for failed login (for UI to show error message)
  String? _loginError;
  String? get loginError => _loginError;

  // Function to check if user is already logged in (e.g., on app start)
  Future<void> checkLoggedInUser() async {
    final user = await _loginRepository.getLoggedInUserFromLocal();
    if (user != null) {
      _loggedInUser = user;
      notifyListeners(); // Notify UI that user is logged in
    }
  }

  // Data changed event (similar to afterTextChanged in Kotlin)
  void loginDataChanged(String username, String password) {
    _loginError = null; // Clear previous login error
    _loggedInUser = null; // Clear previous logged in user

    String? usernameError;
    String? passwordError;
    bool isDataValid = true;

    if (username.isEmpty) {
      usernameError = "Username cannot be empty";
      isDataValid = false;
    } else if (!isUserNameValid(username)) {
      usernameError = "Invalid username format"; // Or provide a specific error message
      isDataValid = false;
    }

    if (password.isEmpty) {
      passwordError = "Password cannot be empty";
      isDataValid = false;
    } else if (!isPasswordValid(password)) {
      passwordError = "Password must be > 5 characters"; // Or provide specific error
      isDataValid = false;
    }

    _loginFormState = _loginFormState.copyWith(
      usernameError: usernameError,
      passwordError: passwordError,
      isDataValid: isDataValid,
      isLoading: false, // Ensure loading is false after validation
    );
    notifyListeners(); // Notify UI of form state changes
  }

  // Login action (similar to login(username, password) in Kotlin ViewModel)
  Future<void> login(String username, String password) async {
    _loginFormState = _loginFormState.copyWith(isLoading: true);
    notifyListeners(); // Show loading indicator

    final result = await _loginRepository.login(username, password);

    if (result is LoginSuccess) {
      _loggedInUser = result.loggedInUser;
      _loginError = null; // Clear any previous error
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
      _loginError = result.exception.toString(); // Display generic error message
      _loginFormState = _loginFormState.copyWith(
        isLoading: false,
      );
    }
    notifyListeners(); // Notify UI of login result
  }

  // Logout action
  Future<void> logout() async {
    await _loginRepository.logout();
    _loggedInUser = null;
    _loginError = null;
    _loginFormState = LoginFormState.initial; // Reset form state
    notifyListeners();
  }

  // A placeholder username validation logic (similar to isUserNameValid)
  bool isUserNameValid(String username) {
    // You can implement more complex validation here
    return username.isNotEmpty && username.length > 3;
  }

  // A placeholder password validation logic (similar to isPasswordValid)
  bool isPasswordValid(String password) {
    // You can implement more complex validation here (e.g., minimum length, special chars)
    return password.isNotEmpty && password.length > 5;
  }
}