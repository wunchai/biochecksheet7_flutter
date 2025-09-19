// lib/data/network/user_api_service.dart
import 'dart:convert';
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // Now imports both LoginResult and SyncResult
import 'package:biochecksheet7_flutter/data/network/api_request_models.dart'; // Import API Request Models

// Define your base URL (from Constants.kt or similar)
//const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";
final String _baseUrl = AppConfig.baseUrl;

class UserApiService {
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
        if (responseJson['Table'] != null && responseJson['Table'].isNotEmpty) {
          final userData = responseJson['Table'][0];
          final loggedInUser = LoggedInUser(
            userId: userData['UserId'] ?? '',
            displayName: userData['UserName'] ?? '',
            userCode: userData['UserCode'] ?? '',
            password: userData['Password'] ?? '',
          );
          return LoginSuccess(loggedInUser);
        } else {
          return const LoginFailed(
              "Invalid username or password (API returned no user).");
        }
      } else {
        return LoginFailed("Login failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      return LoginError(Exception("Network error: ${e.message}"));
    } catch (e) {
      return LoginError(Exception("An unexpected error occurred: $e"));
    }
  }

  // Modified: Return type is now Future<SyncResult>
  Future<List<LoggedInUser>> syncUsers() async {
    // <<< เปลี่ยน return type
    final uri = Uri.parse("$_baseUrl/CheckSheet_User_Sync_V2");
    //print("Sync URI: $uri");
    final headers = {"Content-Type": "application/json"};
    final body =
        jsonEncode({"ServiceName": "CheckSheet_User_Sync_V2", "Paremeter": {}});

    try {
      final response = await http.post(uri, headers: headers, body: body);

      //print("Sync response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        //print("Sync response JSON: $responseJson");
        if (responseJson['Table'] != null && responseJson['Table'] is List) {
          final List<dynamic> userList = responseJson['Table'];
          final List<LoggedInUser> syncedUsers = userList.map((userData) {
            return LoggedInUser(
              userId: userData['UserId'] ?? '',
              displayName: userData['UserName'] ?? '',
              userCode: userData['UserCode'] ?? '',
              password: userData['Password'] ?? '',
              position: userData['Position'] ?? '',
              status: int.tryParse(userData['Status'].toString()) ?? 0,
            );
          }).toList();
          return syncedUsers; // <<< คืน List<LoggedInUser> โดยตรง
        } else {
          throw Exception(
              "Sync API response format invalid."); // <<< โยน Exception แทน SyncFailed
        }
      } else {
        throw Exception(
            "Sync failed: Status code ${response.statusCode}"); // <<< โยน Exception แทน SyncFailed
      }
    } on http.ClientException catch (e) {
      //print("Network error during sync: ${e}");
      throw Exception(
        "Network error during sync: ${e.message}",
      ); // <<< โยน Exception แทน SyncError
    } catch (e) {
      //print("An unexpected error occurred during sync: $e");
      throw Exception(
        "An unexpected error occurred during sync: $e",
      ); // <<< โยน Exception แทน SyncError
    }
  }

  /// NEW: Registers a new user with the API.
  /// Returns true if registration is successful, false otherwise.
  Future<bool> registerUser({
    required String userId,
    required String password,
  }) async {
    final uri = Uri.parse(
        "$_baseUrl/CheckSheet_Register_User"); // Assumed API Endpoint for registration
    print("Registering user with URL: $uri");
    final headers = {"Content-Type": "application/json"};

    final requestBody = RegisterUserRequest(
      userId: userId,
      password: password,
      // userCode and displayName will default to userId if not provided
    );

    final body = jsonEncode({
      "ServiceName": "CheckSheet_RegisterUser",
      "Paremeter": jsonEncode(requestBody.toJson()),
    });
    print("Request body for user registration: $body");

    try {
      final http.Response response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15)); // Set timeout

      final String decodedBody = utf8.decode(response.bodyBytes);
      print("User Registration API Response status: ${response.statusCode}");
      print("User Registration API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        if (responseJson['Table'] != null &&
            responseJson['Table'] is List &&
            responseJson['Table'].isNotEmpty) {
          final Map<String, dynamic> resultData = responseJson['Table'][0];
          final String? apiResult =
              resultData['result']?.toString(); // Get result as String
          final String? apiMessage =
              resultData['message']?.toString(); // Get message

          if (apiResult == "1") {
            // <<< CRUCIAL FIX: Check for "1" as success
            return true; // Registration successful
          } else {
            // If result is not "1", it's a failure or specific message (like "3" for user exists)
            throw Exception(apiMessage ??
                'Registration failed with unknown reason (API result: $apiResult).');
          }
        } else {
          throw Exception(
              "User Registration API response format invalid or empty 'Table'.");
        }
      } else {
        throw Exception(
            "User Registration API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error during user registration.");
      throw Exception(
        "Network error during sync: ${e.message}",
      ); // <<< โยน Exception แทน SyncError
    } catch (e) {
      print("An unexpected error occurred during user registration: $e");
      throw Exception("เกิดข้อผิดพลาดที่ไม่คาดคิดในการลงทะเบียนผู้ใช้: $e");
    }
  }
}
