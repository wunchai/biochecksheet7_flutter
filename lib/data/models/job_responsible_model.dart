// lib/data/models/job_responsible_model.dart

class JobResponsibleModel {
  final int id;
  final int jobId;
  final String userId;
  final int status;
  final String createDate;
  final String createBy;
  
  // Extra fields for UI display that we will populate locally
  String? userName;

  JobResponsibleModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.status,
    required this.createDate,
    required this.createBy,
    this.userName,
  });

  factory JobResponsibleModel.fromJson(Map<String, dynamic> json) {
    return JobResponsibleModel(
      id: json['id'] as int? ?? 0,
      jobId: json['jobId'] as int? ?? 0,
      userId: json['userId']?.toString() ?? '',
      status: json['status'] as int? ?? 0,
      createDate: json['createDate']?.toString() ?? '',
      createBy: json['createBy']?.toString() ?? '',
    );
  }
}
