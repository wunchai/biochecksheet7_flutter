// lib/data/repositories/login_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/user_api_service.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart';
// Removed: import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart'; // No longer directly needed
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // เพิ่ม import SyncStatus
import 'package:drift/drift.dart';

class LoginRepository {
  final UserApiService _userApiService;
  final UserDao _userDao; // Now it's a direct UserDao, not Future<UserDao>

  LoggedInUser? _user;

  bool get isLoggedIn => _user != null;

  // Constructor now takes resolved AppDatabase instance
  LoginRepository._internal({
    required UserApiService userApiService,
    required AppDatabase appDatabase, // <<< Change to AppDatabase
  })  : _userApiService = userApiService,
        _userDao = appDatabase.userDao; // Access dao directly from appDatabase

  // Singleton instance now needs an async initializer
  static LoginRepository? _instance; // Make nullable
  factory LoginRepository() {
    // This factory should only be called after AppDatabase.instance is resolved.
    // Or, pass AppDatabase instance during main app initialization.
    // For simplicity with current setup, we assume AppDatabase.instance is ready.
    if (_instance == null) {
      throw Exception(
          "LoginRepository must be initialized after AppDatabase is ready.");
    }
    return _instance!;
  }

  // NEW static async initializer for AppDatabase and LoginRepository
  static Future<void> initialize(AppDatabase appDatabase) async {
    _instance = LoginRepository._internal(
      userApiService: UserApiService(),
      appDatabase: appDatabase, // Pass the resolved AppDatabase
    );
  }

  Future<void> logout() async {
    _user = null;
    await _userDao.deleteAllUsers();
  }

  Future<LoginResult> login(String username, String password) async {
    try {
      final localUser = await _userDao.getLogin(username, password);

      if (localUser != null) {
        _user = LoggedInUser(
          userId: localUser.userId ?? '',
          displayName: localUser.userName ?? '',
          userCode: localUser.userCode ?? '',
          password: localUser.password ?? '',
          position: localUser.position,
          status: localUser.status,
        );
        return LoginSuccess(_user!);
      } else {
        return const LoginFailed(
            "Invalid username or password. Please sync user data first.");
      }
    } catch (e) {
      return LoginError(Exception("Login repository error: $e"));
    }
  }

  Future<SyncStatus> syncUsers() async {
    try {
      final List<LoggedInUser> syncedUsers = await _userApiService.syncUsers();

      await _userDao.deleteAllUsers();

      final List<UsersCompanion> usersToInsert = syncedUsers.map((user) {
        return UsersCompanion(
          userId: Value(user.userId),
          userCode: Value(user.userCode),
          password: Value(user.password),
          userName: Value(user.displayName),
          position: Value(user.position),
          status: Value(user.status!),
          lastSync: Value(DateTime.now().toIso8601String()),
        );
      }).toList();

      await _userDao.insertAllUsers(usersToInsert);

      return const SyncSuccess();
    } on Exception catch (e) {
      return SyncError(e);
    }
  }

  Future<LoggedInUser?> getLoggedInUserFromLocal() async {
    final users = await _userDao.getAllUsers();
    if (users.isNotEmpty) {
      final dbUser = users.first;
      _user = LoggedInUser(
        userId: dbUser.userId ?? '',
        displayName: dbUser.userName ?? '',
        userCode: dbUser.userCode ?? '',
        password: dbUser.password ?? '',
        position: dbUser.position,
        status: dbUser.status,
      );
      return _user;
    }
    return null;
  }
}
