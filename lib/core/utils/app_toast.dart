import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  /// แสดงแจ้งเตือนแบบ Toast บริเวณกลางจอ
  static void show(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER, // กลางจอ
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
