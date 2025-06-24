// lib/data/repositories/login_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/user_api_service.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart';
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:drift/drift.dart';

class LoginRepository {
  final UserApiService _userApiService;
  final UserDao _userDao;

  LoggedInUser? _user;

  // CRUCIAL ADDITION: Public getter for the logged-in user
  LoggedInUser? get loggedInUser => _user; // <<< เพิ่มบรรทัดนี้

  bool get isLoggedIn => _user != null;

  LoginRepository._internal({
    required UserApiService userApiService,
    required AppDatabase appDatabase,
  })  : _userApiService = userApiService,
        _userDao = appDatabase.userDao;

  static LoginRepository? _instance;
  factory LoginRepository() {
    if (_instance == null) {
      throw Exception("LoginRepository must be initialized after AppDatabase is ready.");
    }
    return _instance!;
  }

  static Future<void> initialize(AppDatabase appDatabase) async {
    _instance = LoginRepository._internal(
      userApiService: UserApiService(),
      appDatabase: appDatabase,
    );
    // After initialization, attempt to load user from local storage
    await _instance!.getLoggedInUserFromLocal();
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