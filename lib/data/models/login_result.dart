// lib/data/models/login_result.dart
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';

// Equivalent to sealed class Result in Kotlin
sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess(this.loggedInUser);
  final LoggedInUser loggedInUser;
}

class LoginError extends LoginResult {
  const LoginError(this.exception);
  final Exception exception;
}

class LoginFailed extends LoginResult {
  const LoginFailed(this.errorMessage);
  final String errorMessage;
}

