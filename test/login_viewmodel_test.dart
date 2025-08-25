// test/login_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart'; // สำหรับ flutter_test framework
import 'package:biochecksheet7_flutter/presentation/screens/login/login_viewmodel.dart'; // Import ViewModel ที่จะทดสอบ
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart'; // Import Repository ที่จะ Mock
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // Import AppDatabase (สำหรับ Mock)
import 'package:biochecksheet7_flutter/data/models/logged_in_user.dart'; // Import LoggedInUser (สำหรับ Mock)
import 'package:biochecksheet7_flutter/data/models/login_result.dart'; // Import LoginResult (สำหรับ Mock)
import 'package:biochecksheet7_flutter/data/network/sync_status.dart'; // Import SyncStatus (สำหรับ Mock)

// --- 1. สร้าง Mock LoginRepository ---
// นี่คือคลาสปลอมที่เลียนแบบพฤติกรรมของ LoginRepository ตัวจริง
// เราจะ Implement เฉพาะเมธอดที่ LoginViewModel อาจจะเรียกใช้ (แม้ว่า loginDataChanged จะไม่เรียก)
// แต่ถ้าเราจะทดสอบเมธอดอื่นใน ViewModel ที่เรียก Repository, เราก็ต้อง Mock เมธอดเหล่านั้นด้วย
class MockLoginRepository implements LoginRepository {
  // Mock properties and methods that LoginViewModel might access.
  // For loginDataChanged, most of these won't be called, but it's good practice.
  @override
  AppDatabase get appDatabase =>
      throw UnimplementedError('Not used in this test');
  @override
  bool get isLoggedIn => false; // Mock default state
  @override
  LoggedInUser? get loggedInUser => null; // Mock default state

  // Mock the methods that might be called, or throw if unexpectedly called.
  @override
  Future<LoginResult> login(String username, String password) =>
      throw UnimplementedError('Login method not mocked');
  @override
  Future<void> logout() => throw UnimplementedError('Logout method not mocked');
  @override
  Future<SyncStatus> syncUsers() =>
      throw UnimplementedError('SyncUsers method not mocked');
  @override
  Future<LoggedInUser?> getLoggedInUserFromLocal() =>
      throw UnimplementedError('getLoggedInUserFromLocal method not mocked');
}

void main() {
  // --- 2. จัดกลุ่ม Test Cases ด้วย group() ---
  group('LoginViewModel', () {
    // ประกาศตัวแปรที่จะใช้ใน Test Cases
    late LoginViewModel loginViewModel;
    late MockLoginRepository
        mockLoginRepository; // Instance ของ Mock Repository

    // setUp() จะทำงานก่อน Test Case แต่ละตัวใน group นี้
    setUp(() {
      // เตรียมสภาพแวดล้อมก่อนแต่ละ Test:
      // 1. สร้าง Instance ของ Mock Repository
      mockLoginRepository = MockLoginRepository();
      // 2. สร้าง Instance ของ ViewModel ที่จะทดสอบ โดยส่ง Mock Repository เข้าไป
      loginViewModel = LoginViewModel(loginRepository: mockLoginRepository);
    });

    // --- 3. เขียน Test Cases ด้วย test() ---

    test('loginDataChanged should update username and password correctly', () {
      // Arrange (เตรียมข้อมูล/สถานะเริ่มต้น)
      const String testUsername = 'testuser';
      const String testPassword = 'testpass';

      // Act (เรียกใช้ฟังก์ชันที่ต้องการทดสอบ)
      loginViewModel.loginDataChanged(testUsername, testPassword);

      // Assert (ตรวจสอบผลลัพธ์ที่คาดหวัง)
      expect(loginViewModel.loginFormState.username, testUsername);
      expect(loginViewModel.loginFormState.password, testPassword);
      // ตรวจสอบว่า isDataValid เป็น true เมื่อข้อมูลถูกต้อง (ตาม Logic ใน ViewModel)
      expect(loginViewModel.loginFormState.isDataValid, true);
      // ตรวจสอบว่าไม่มี Error
      expect(loginViewModel.loginFormState.usernameError, isNull);
      expect(loginViewModel.loginFormState.passwordError, isNull);
    });

    test('loginDataChanged should set usernameError if username is empty', () {
      // Arrange
      const String testPassword = 'testpass';

      // Act
      loginViewModel.loginDataChanged(
          '', testPassword); // ส่ง username เป็นค่าว่าง

      // Assert
      expect(loginViewModel.loginFormState.username, '');
      expect(loginViewModel.loginFormState.password, testPassword);
      // ตรวจสอบว่า usernameError ถูกตั้งค่า
      expect(loginViewModel.loginFormState.usernameError,
          'Username cannot be empty');
      expect(loginViewModel.loginFormState.isDataValid,
          false); // และ isDataValid เป็น false
      expect(loginViewModel.loginFormState.passwordError, isNull);
    });

    test('loginDataChanged should set passwordError if password is empty', () {
      // Arrange
      const String testUsername = 'testuser';

      // Act
      loginViewModel.loginDataChanged(
          testUsername, ''); // ส่ง password เป็นค่าว่าง

      // Assert
      expect(loginViewModel.loginFormState.username, testUsername);
      expect(loginViewModel.loginFormState.password, '');
      // ตรวจสอบว่า passwordError ถูกตั้งค่า
      expect(loginViewModel.loginFormState.passwordError,
          'Password cannot be empty');
      expect(loginViewModel.loginFormState.isDataValid,
          false); // และ isDataValid เป็น false
      expect(loginViewModel.loginFormState.usernameError, isNull);
    });

    test('loginDataChanged should set both errors if both are empty', () {
      // Act
      loginViewModel.loginDataChanged('', ''); // ส่งทั้งคู่เป็นค่าว่าง

      // Assert
      expect(loginViewModel.loginFormState.usernameError,
          'Username cannot be empty');
      expect(loginViewModel.loginFormState.passwordError,
          'Password cannot be empty');
      expect(loginViewModel.loginFormState.isDataValid, false);
    });
  });
}
