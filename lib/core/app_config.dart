// lib/app_config.dart
import 'package:flutter/material.dart';

// Define your specific theme colors
const Color primaryThemeBlue = Color(0xFF3F51B5); // Indigo
const Color accentThemeAmber = Color(0xFFFFC107); // Amber
const Color scaffoldBackgroundLightGrey = Color(0xFFF5F5F5); // Light Grey
const Color darkText = Color(0xFF212121); // Dark grey for text
const Color lightText = Colors.white; // White for text on dark backgrounds

class AppConfig {
  // --- URL หลักของ API Server ---
  // แก้ไข URL นี้ให้เป็นที่อยู่ของ Server ของคุณ
  // ตัวอย่าง: 'http://192.168.1.100:8080' หรือ 'https://api.yourdomain.com'
  //static const String baseUrl = 'http://10.1.200.26/ServiceJson/Service4.svc';
  static const String baseUrl = 'http://10.1.200.26:94';
  // --- การตั้งค่าอื่นๆ (สามารถเพิ่มได้ในอนาคต) ---

  // ตัวอย่าง: ระยะเวลา timeout สำหรับการเชื่อมต่อ API (เป็นวินาที)
  // static const int connectTimeout = 30;

  // ตัวอย่าง: Key สำหรับบริการอื่นๆ
  // static const String mapApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
}
