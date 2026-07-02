import 'dart:async'; // <<< NEW
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io'; // <<< NEW

/// Top-level function for handling background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
}

// Global instance of FCMService
final FCMService fcmService = FCMService._internal();

class FCMService {
  // Private constructor for singleton
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Stream controller to broadcast messages to ViewModels
  final _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  Future<void> initialize() async {
    // Firebase Messaging ไม่รองรับบน Windows และ Linux
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      print("FCM is not supported on Windows/Linux. Skipping initialization.");
      return;
    }

    // 1. Request permission
    await requestPermission();

    // 2. Get device token
    await getDeviceToken();

    // 3. Set up message listeners
    setupMessageHandlers();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String?> getDeviceToken() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return "dummy_token_for_windows"; // คืนค่าจำลองให้ Windows ไม่พัง
    }

    try {
      String? token = await _firebaseMessaging.getToken();
      print("========================================");
      print("FCM Device Token: $token");
      print("========================================");
      
      // TODO: Send this token to your local database/server
      return token;
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  void setupMessageHandlers() {
    // 1. App is in Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification?.title}');
        // Broadcast the message to listeners (e.g., NotificationsViewModel)
        _messageStreamController.add(message);
      }
    });

    // 2. App is in Background (and user tapped on the notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Broadcast to let ViewModel handle routing or adding to list
      _messageStreamController.add(message);
    });

    // 3. App is Terminated (and user tapped on the notification to open the app)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App launched from terminated state via notification');
        // Wait a bit for the app to initialize before broadcasting
        Future.delayed(const Duration(seconds: 2), () {
          _messageStreamController.add(message);
        });
      }
    });

    // Register the background handler (for when app is closed but receives a message)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Good practice to close stream when not needed, though a singleton usually lives forever
  void dispose() {
    _messageStreamController.close();
  }
}
