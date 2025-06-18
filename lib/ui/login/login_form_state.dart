// lib/ui/login/login_form_state.dart
/// Equivalent to data class LoginFormState in Kotlin
class LoginFormState {
  final String? usernameError;
  final String? passwordError;
  final bool isDataValid;
  final bool isLoading; // To represent loading state

  LoginFormState({
    this.usernameError,
    this.passwordError,
    this.isDataValid = false,
    this.isLoading = false,
  });

  // Convenience methods to create states
  LoginFormState copyWith({
    String? usernameError,
    String? passwordError,
    bool? isDataValid,
    bool? isLoading,
  }) {
    return LoginFormState(
      usernameError: usernameError,
      passwordError: passwordError,
      isDataValid: isDataValid ?? this.isDataValid,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Initial state
  static LoginFormState get initial => LoginFormState(
    usernameError: null,
    passwordError: null,
    isDataValid: false,
    isLoading: false,
  );
}