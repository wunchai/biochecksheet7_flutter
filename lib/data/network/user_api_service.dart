// lib/data/network/user_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // Your defined LoginResult

// Define your base URL (from Constants.kt or similar)
const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc"; // Example base URL

class UserApiService {
  // Equivalent to fun getWebServiceLogin(userCode: String, pass: String): LoginUser? in DbUserCode.kt
  Future<LoginResult> login(String userCode, String password) async {
    final uri = Uri.parse("$_baseUrl/CheckSheet_MasterUser_Login");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "ServiceName": "CheckSheet_MasterUser_Login",
      "Paremeter": {"username": userCode, "password": password}
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        // Assuming your API returns a "Table" key which is a list of users
        // And if login is successful, it returns one user in the list
        if (responseJson['Table'] != null && responseJson['Table'].isNotEmpty) {
          final userData = responseJson['Table'][0]; // Get the first user
          // Parse the JSON data into LoggedInUser
          // Adjust this mapping based on your actual API response structure
          final loggedInUser = LoggedInUser(
            userId: userData['UserId'] ?? '',
            displayName: userData['UserName'] ?? '',
            userCode: userData['UserCode'] ?? '',
            password: userData['Password'] ?? '', // Be cautious storing/passing passwords
          );
          return LoginSuccess(loggedInUser);
        } else {
          return const LoginFailed("Invalid username or password (API returned no user).");
        }
      } else {
        // Handle HTTP error status codes
        return LoginFailed("Login failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      // Handle network errors (e.g., no internet, host unreachable)
      return LoginError(Exception("Network error: ${e.message}"));
    } catch (e) {
      // Handle any other errors
      return LoginError(Exception("An unexpected error occurred: $e"));
    }
  }

  // You might have other user-related API calls here (e.g., getUserDetails)
}