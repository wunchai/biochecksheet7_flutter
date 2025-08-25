// lib/ui/login/login_form_state.dart
/// Equivalent to data class LoginFormState in Kotlin
class LoginFormState {
  // CRUCIAL FIX: Add username and password as properties
  final String username; // <<< NEW
  final String password; // <<< NEW

  final String? usernameError;
  final String? passwordError;
  final bool isDataValid;
  final bool isLoading; // To represent loading state

  LoginFormState({
    this.username = '', // <<< Initialize username
    this.password = '', // <<< Initialize password

    this.usernameError,
    this.passwordError,
    this.isDataValid = false,
    this.isLoading = false,
  });

  // Convenience methods to create states
  LoginFormState copyWith({
    String? username,
    String? password,
    String? usernameError,
    String? passwordError,
    bool? isDataValid,
    bool? isLoading,
  }) {
    return LoginFormState(
      username: username ?? this.username, // <<< Update username
      password: password ?? this.password, // <<< Update password

      usernameError: usernameError,
      passwordError: passwordError,
      isDataValid: isDataValid ?? this.isDataValid,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginFormState &&
        other.username == username &&
        other.password == password &&
        other.usernameError == usernameError &&
        other.passwordError == passwordError &&
        other.isDataValid == isDataValid &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        password.hashCode ^
        usernameError.hashCode ^
        passwordError.hashCode ^
        isDataValid.hashCode ^
        isLoading.hashCode;
  }

  // Initial state
  static LoginFormState get initial => LoginFormState(
        username: '', // Initialize with empty username
        password: '', // Initialize with empty password
        usernameError: null,
        passwordError: null,
        isDataValid: false,
        isLoading: false,
      );
}
