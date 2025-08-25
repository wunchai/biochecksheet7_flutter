// lib/app_routes.dart
import 'package:flutter/material.dart';

// Import all screens that are part of the navigation
import 'package:biochecksheet7_flutter/presentation/screens/login/login_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/main_wrapper/main_wrapper_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/home/home_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/dashboard/dashboard_screen.dart';
//import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document/document_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentmachine/document_machine_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/documentrecord/document_record_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/imagerecord/image_record_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/problem/problem_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/deviceinfo/device_info_screen.dart';
import 'package:biochecksheet7_flutter/presentation/screens/datasummary/data_summary_screen.dart'; // <<< NEW: Import Screen
import 'package:biochecksheet7_flutter/presentation/screens/amchecksheet/am_checksheet_screen.dart'; // <<< เพิ่ม Import

// Define all application routes
Map<String, WidgetBuilder> appRoutes() {
  return {
    '/login': (context) => const LoginScreen(),
    '/main_wrapper': (context) => const MainWrapperScreen(),
    '/home': (context) => const HomeScreen(title: 'Home Screen'),
    '/dashboard': (context) => const DashboardScreen(title: 'Dashboard Screen'),
    //'/notifications': (context) => const NotificationsScreen(title: 'Notifications Screen'),
    '/document': (context) => const DocumentScreen(title: 'Document Screen'),
    '/document_machine': (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return DocumentMachineScreen(
        title: args?['title'] ?? 'Machines',
        jobId: args?['jobId'] ?? '',
        documentId: args?['documentId'] ?? '',
      );
    },
    '/document_record': (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return DocumentRecordScreen(
        title: args?['title'] ?? 'Document Record',
        documentId: args?['documentId'] ?? '',
        machineId: args?['machineId'] ?? '',
        jobId: args?['jobId'] ?? '',
      );
    },
    '/am_checksheet': (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AMChecksheetScreen(
        title: args?['title'] ?? 'AM Checksheet',
        documentId: args?['documentId'] ?? '',
        machineId: args?['machineId'] ?? '',
        jobId: args?['jobId'] ?? '',
      );
    },
    '/image_record': (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ImageRecordScreen(
        title: args?['title'] ?? 'Image Records',
        documentId: args?['documentId'] ?? '',
        machineId: args?['machineId'] ?? '',
        jobId: args?['jobId'] ?? '',
        tagId: args?['tagId'] ?? '',
        problemId: args?['problemId']?.toString(),
        isReadOnly: args?['isReadOnly'] ?? false,
      );
    },
    '/problem': (context) => const ProblemScreen(title: 'Problem List'),
    '/device_info': (context) => const DeviceInfoScreen(title: 'ข้อมูลอุปกรณ์'),
    '/notifications': (context) => const DataSummaryScreen(
        title: 'สรุปข้อมูล'), // <<< CHANGED: Notifications to DataSummary
    '/data_summary': (context) => const DataSummaryScreen(
        title: 'สรุปข้อมูล'), // <<< NEW: Add explicit route
  };
}
