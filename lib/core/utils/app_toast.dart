import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  /// แสดงแจ้งเตือนแบบ Toast บริเวณกลางจอ
  /// (หากบน Windows ไม่รองรับ จะมี Fallback แสดงผลเป็น SnackBar แทนหากส่ง context มา)
  static void show(String message, {bool isError = false, BuildContext? context}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER, // กลางจอ
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    ).catchError((e) {
      // ป้องกันแอปค้าง (Crash) เมื่อรันบน Platform ที่ไม่รองรับ (เช่น Windows Desktop)
      debugPrint('Toast ไม่รองรับบน Platform นี้: $e');
      
      // Fallback: แสดงด้วย SnackBar แทนหากมีการส่ง context เข้ามา
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
            backgroundColor: isError ? Colors.red : Colors.black87,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    });
  }
}
