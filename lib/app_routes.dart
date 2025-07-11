// lib/app_routes.dart
import 'package:flutter/material.dart';

// Import all screens that are part of the navigation
import 'package:biochecksheet7_flutter/ui/login/login_screen.dart';
import 'package:biochecksheet7_flutter/ui/main_wrapper/main_wrapper_screen.dart';
import 'package:biochecksheet7_flutter/ui/home/home_screen.dart';
import 'package:biochecksheet7_flutter/ui/dashboard/dashboard_screen.dart';
import 'package:biochecksheet7_flutter/ui/notifications/notifications_screen.dart';
import 'package:biochecksheet7_flutter/ui/document/document_screen.dart';
import 'package:biochecksheet7_flutter/ui/documentmachine/document_machine_screen.dart';
import 'package:biochecksheet7_flutter/ui/documentrecord/document_record_screen.dart';
import 'package:biochecksheet7_flutter/ui/imagerecord/image_record_screen.dart';
import 'package:biochecksheet7_flutter/ui/problem/problem_screen.dart';
import 'package:biochecksheet7_flutter/ui/deviceinfo/device_info_screen.dart';
import 'package:biochecksheet7_flutter/ui/datasummary/data_summary_screen.dart'; // <<< NEW: Import Screen

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
