// lib/data/repositories/login_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/user_api_service.dart';
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart';
import 'package:biochecksheet7_flutter/data/models/login_result.dart';
import 'package:biochecksheet7_flutter/data/database/daos/user_dao.dart';
import 'package:biochecksheet7_flutter/data/network/sync_status.dart';
import 'package:drift/drift.dart';
import 'package:collection/collection.dart'; // <<< CRUCIAL FIX: Import collection for firstWhereOrNull
import 'package:biochecksheet7_flutter/data/utils/demo_seeder.dart'; // Import DemoSeeder

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
      throw Exception(
          "LoginRepository must be initialized after AppDatabase is ready.");
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

  /// Logs out the current user by clearing the in-memory user object
  /// and setting their local session status to inactive in the database.
  Future<void> logout() async {
    // CRUCIAL FIX: Capture userId BEFORE clearing _user
    final String? currentUserId =
        _user?.userId; // Get userId of the user currently logged in

    _user = null; // Clear the in-memory user session

    // Update the local user's session status to inactive in the database
    if (currentUserId != null) {
      // Only proceed if we had a userId
      final DbUser? dbUser = await _userDao
          .getUserByUserId(currentUserId); // Use the captured userId
      if (dbUser != null) {
        final bool updateSuccess = await _userDao.updateUser(
          // Check update success
          UsersCompanion(
            uid: Value(dbUser.uid),
            isLocalSessionActive: Value(false), // Set to false on logout
          ),
        );
        if (updateSuccess) {
          print(
              'LoginRepository: User $currentUserId local session set to inactive in DB.');
        } else {
          print(
              'LoginRepository: Failed to set user $currentUserId local session to inactive in DB.');
        }
      } else {
        print(
            'LoginRepository: User $currentUserId not found in DB for session update.');
      }
    } else {
      print(
          'LoginRepository: No user was active in memory to update local session status.');
    }
    print(
        'LoginRepository: User logged out. Local user data retained for offline use.');
  }

  /// Performs user login.
  /// On successful login, updates user's local session status to active in the database.
  Future<LoginResult> login(String username, String password) async {
    // --- DEMO MODE FOR PLAY STORE REVIEW ---
    if (username == 'demo' && password == 'demo1234') {
      try {
        print(
            'LoginRepository: Demo credentials detected. Seeding demo data...');
        // Access AppDatabase via the DAO
        final db = _userDao.attachedDatabase;
        final seeder = DemoSeeder(db);
        await seeder.seedDemoData();
        print('LoginRepository: Demo data seeded successfully.');
      } catch (e) {
        print('LoginRepository: Error seeding demo data: $e');
        // We continue execution; if seeding failed but user exists, login might still work.
      }
    }
    // ---------------------------------------

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
        // NEW: Update the local user's session status to active
        await _userDao.updateUser(
          UsersCompanion(
            uid: Value(localUser.uid),
            isLocalSessionActive:
                Value(true), // Set to true on successful login
          ),
        );
        print(
            'LoginRepository: User ${localUser.userId} local session set to active.');
        return LoginSuccess(_user!);
      } else {
        return const LoginFailed(
            "Invalid username or password. Please sync user data first.");
      }
    } catch (e) {
      return LoginError(Exception("Login repository error: $e"));
    }
  }

  /// Syncs user data from API to local database.
  /// After syncing, ensures the newly synced user's session is inactive by default,
  /// unless they explicitly log in.
  Future<SyncStatus> syncUsers() async {
    try {
      final List<LoggedInUser> syncedUsers = await _userApiService.syncUsers();

      // Before deleting all users, get current active session (if any)
      final DbUser? currentDbUser =
          _user != null ? await _userDao.getUserByUserId(_user!.userId) : null;
      final bool wasActive = currentDbUser?.isLocalSessionActive ?? false;

      await _userDao
          .deleteAllUsers(); // This is where all local users are cleared during a sync.

      final List<UsersCompanion> usersToInsert = syncedUsers.map((user) {
        // If this user was the active session before sync, keep them active.
        // Otherwise, new users or users not previously active are inactive by default.
        final bool isActiveAfterSync =
            (user.userId == currentDbUser?.userId && wasActive);

        return UsersCompanion(
          uid: Value.absent(),
          userId: Value(user.userId),
          password: Value(user.password),
          userCode: Value(user.userCode),
          status: Value(user.status!),
          userName: Value(user.displayName),
          position: Value(user.position),
          lastSync: Value(DateTime.now().toIso8601String()),
          isLocalSessionActive:
              Value(isActiveAfterSync), // Set session active status
        );
      }).toList();

      await _userDao.insertAllUsers(usersToInsert);
      return const SyncSuccess(message: 'ซิงค์ข้อมูลผู้ใช้สำเร็จ!');
    } on Exception catch (e) {
      print('Error syncing users: $e');
      return SyncError(exception: e, message: 'ข้อผิดพลาดในการซิงค์ผู้ใช้: $e');
    }
  }

  /// Gets the logged-in user from local database if their session is active.
  Future<LoggedInUser?> getLoggedInUserFromLocal() async {
    final users = await _userDao.getAllUsers();
    if (users.isNotEmpty) {
      // NEW: Only consider user logged in if isLocalSessionActive is true
      final activeLocalUser = users.firstWhereOrNull(
          (dbUser) => dbUser.isLocalSessionActive); // Assume first active user

      if (activeLocalUser != null) {
        _user = LoggedInUser(
          userId: activeLocalUser.userId ?? '',
          displayName: activeLocalUser.userName ?? '',
          userCode: activeLocalUser.userCode ?? '',
          password: activeLocalUser.password ?? '',
          position: activeLocalUser.position,
          status: activeLocalUser.status,
        );
        print(
            'LoginRepository: Found active local session for user: ${activeLocalUser.userId}');
        return _user;
      }
    }
    print('LoginRepository: No active local session found.');
    _user = null; // Ensure in-memory user is null if no active local session
    return null;
  }
}
