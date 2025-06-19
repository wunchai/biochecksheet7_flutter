// lib/data/repositories/login_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/user_api_service.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // ยังคง import LoginResult
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // <<< เพิ่ม import SyncStatus
import 'package:biochecksheet7_flutter/data/database/tables/user_table.dart';
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:drift/drift.dart';

class LoginRepository {
  final UserApiService _userApiService;
  final UserDao _userDao;

  LoggedInUser? _user;

  bool get isLoggedIn => _user != null;

  LoginRepository._internal({
    required UserApiService userApiService,
    required UserDao userDao,
  })  : _userApiService = userApiService,
        _userDao = userDao;

  static final LoginRepository _instance = LoginRepository._internal(
    userApiService: UserApiService(),
    userDao: AppDatabase.instance.userDao,
  );

  factory LoginRepository() {
    return _instance;
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
        return const LoginFailed("Invalid username or password. Please sync user data first.");
      }
    } catch (e) {
      return LoginError(Exception("Login repository error: $e"));
    }
  }

  // ปรับ syncUsers ให้คืนค่า SyncStatus
  Future<SyncStatus> syncUsers() async { // <<< เปลี่ยน return type เป็น SyncStatus
    try {
      // UserApiService.syncUsers() ตอนนี้จะคืนค่า List<LoggedInUser>
      final List<LoggedInUser> syncedUsers = await _userApiService.syncUsers(); // <<< รับ List<LoggedInUser> โดยตรง

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

      return const SyncSuccess(); // <<< คืน SyncSuccess
    } on Exception catch (e) { // Catch more general Exception if _userApiService.syncUsers throws directly
      return SyncError(e); // Use SyncError for exceptions
    }
    // ไม่จำเป็นต้องมี else if (apiResult is SyncFailed/SyncError) แล้ว เพราะ _userApiService.syncUsers จะโยน exception หากเกิด error
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