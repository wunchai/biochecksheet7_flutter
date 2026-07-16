import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/network/job_api_service.dart';
import 'package:biochecksheet7_flutter/data/models/job_responsible_model.dart';
import 'package:biochecksheet7_flutter/data/repositories/login_repository.dart';

class JobResponsibleViewModel extends ChangeNotifier {
  final JobApiService _jobApiService = JobApiService();
  final AppDatabase _db;
  final LoginRepository _loginRepo = LoginRepository();
  final String jobId;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  
  List<JobResponsibleModel> responsibleUsers = [];

  JobResponsibleViewModel(this._db, this.jobId) {
    fetchResponsibleUsers();
  }

  Future<void> fetchResponsibleUsers() async {
    isLoading = true;
    notifyListeners();
    
    try {
      final currentUserId = _loginRepo.loggedInUser?.userId ?? '';
      final List<Map<String, dynamic>> rawData = await _jobApiService.getJobResponsible(jobId, currentUserId);
      
      List<JobResponsibleModel> users = rawData.map((e) => JobResponsibleModel.fromJson(e)).toList();
      
      // Map local names
      for (var user in users) {
        final dbUser = await _db.userDao.getUser(user.userId);
        if (dbUser != null) {
          user.userName = dbUser.userName;
        }
      }
      
      responsibleUsers = users;
    } catch (e) {
      errorMessage = "เกิดข้อผิดพลาดในการโหลดข้อมูล: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setJobResponsible(String userId) async {
    if (userId.trim().isEmpty) {
      errorMessage = "กรุณากรอก User ID";
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      // Validate that the user exists in the local database
      final foundUser = await _db.userDao.getUser(userId.trim());
      if (foundUser == null || foundUser.userId == null) {
        errorMessage = "ไม่พบ User ID นี้ในระบบ";
        isLoading = false;
        notifyListeners();
        return;
      }

      // If user is found, proceed to set responsible
      final result = await _jobApiService.setJobResponsible(jobId, foundUser.userId!);
      if (result == '1') {
        successMessage = "เพิ่มผู้รับผิดชอบสำเร็จ: ${foundUser.userName ?? userId}";
        // Reload list after success
        await fetchResponsibleUsers();
      } else if (result == '3') {
        errorMessage = "มีชื่อผู้ใช้นี้อยู่แล้ว";
      } else {
        errorMessage = "เกิดข้อผิดพลาด (รหัส: $result)";
      }
    } catch (e) {
      errorMessage = "เกิดข้อผิดพลาดในการเพิ่ม: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
