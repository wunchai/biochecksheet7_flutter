// lib/data/network/user_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // Now imports both LoginResult and SyncResult

// Define your base URL (from Constants.kt or similar)
const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

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
}
