// lib/data/network/api_response_models.dart
import 'dart:convert';
/// Data class for API upload response for a single record.
/// Used when API returns a list of results for each uploaded item.
class UploadRecordResult {
  final int uid; // Local UID of the record
  final int result; // API result code (e.g., 3 for success, others for failure)
  final String? message; // Optional: API message for the record

  UploadRecordResult({required this.uid, required this.result, this.message});

  factory UploadRecordResult.fromJson(Map<String, dynamic> json) {
    return UploadRecordResult(
      uid: int.tryParse(json['uid']?.toString() ?? '0') ??
          0, // Ensure UID is parsed as int
      result: int.tryParse(json['result']?.toString() ?? '0') ??
          0, // Ensure result is parsed as int
      message: json['message']?.toString(), // Optional message from API
    );
  }
}

/// Response model for SyncMetadata API.
/// Represents an action/command received from the server.
class SyncMetadataResponse {
  final String? deviceId; // <<< NEW: Add deviceId (from API Response)
  final String actionId;
  final String actionType;
  final String? actionSql;
  final String? actionValue; // <<< NEW: Add actionValue (from API Response)

  SyncMetadataResponse({
    this.deviceId, // <<< Add to constructor
    required this.actionId,
    required this.actionType,
    this.actionSql,
    this.actionValue, // <<< Add to constructor
  });

  factory SyncMetadataResponse.fromJson(Map<String, dynamic> json) {
    return SyncMetadataResponse(
      deviceId: json['deviceId']
          ?.toString(), // <<< CRUCIAL FIX: Map deviceId (camelCase)
      actionId: json['actionId']?.toString() ??
          '', // <<< CRUCIAL FIX: Map actionId (camelCase)
      actionType: json['actionType']?.toString() ??
          '', // <<< CRUCIAL FIX: Map actionType (camelCase)
      actionSql: json['actionSql']
          ?.toString(), // <<< CRUCIAL FIX: Map actionSql (camelCase)
      actionValue: json['actionValue']
          ?.toString(), // <<< CRUCIAL FIX: Map actionValue (camelCase)
    );
  }
}

/// NEW: Response model for Image Upload API.
/// Assumed API returns { "Table": [ { "guid": "...", "result": 3, "message": "..." } ] }
class ImageUploadResult {
  final String guid; // GUID of the uploaded image (from API)
  final int result; // API result code (e.g., 3 for success, others for failure)
  final String? message; // Optional: API message

  ImageUploadResult({required this.guid, required this.result, this.message});

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageUploadResult(
      guid: json['guid']?.toString() ??
          '', // Assuming 'guid' key from API response
      result: int.tryParse(json['result']?.toString() ?? '0') ??
          0, // Assuming 'result' key from API response
      message: json['message']?.toString(), // Optional 'message' key
    );
  }
}

class CheckSheetMasterImageResponse {
  final int id;
  final int? machineId;
  final int? jobId;
  final int? tagId;
  // ไม่ต้องมี PATH เพราะเราจะ sync แยก
  final int? status;
  final String? createDate; // รับเป็น String ก่อน
  final String? createBy;
  final String? updatedAt;
  CheckSheetMasterImageResponse({
    required this.id,
    this.machineId,
    this.jobId,
    this.tagId,
    this.status,
    this.createDate,
    this.createBy,
    this.updatedAt,
  });

  factory CheckSheetMasterImageResponse.fromJson(Map<String, dynamic> json) {
    return CheckSheetMasterImageResponse(
      id: json['id'] as int,
      machineId: json['MachineId'] as int?,
      jobId: json['JobId'] as int?,
      tagId: json['TagId'] as int?,
      status: json['Status'] as int?,
      createDate: json['CreateDate'] as String?,
      createBy: json['CreateBy'] as String?,
      updatedAt: json['UpdatedAt'] as String?,
    );
  }
}

class CheckSheetDocumentImageResponse {
  final int id;
  final String? documentId;
  final String? machineId;
  final String? jobId;
  final String? tagId;
  final String? guid;
  final String? createDate;

  CheckSheetDocumentImageResponse({
    required this.id,
    this.documentId,
    this.machineId,
    this.jobId,
    this.tagId,
    this.guid,
    this.createDate,
  });

  factory CheckSheetDocumentImageResponse.fromJson(Map<String, dynamic> json) {
    return CheckSheetDocumentImageResponse(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      documentId: json['DocumentId']?.toString(),
      machineId: json['MachineId']?.toString(),
      jobId: json['JobId']?.toString(),
      tagId: json['TagId']?.toString(),
      guid: json['Guid']?.toString(),
      createDate: json['CreateDate']?.toString(),
    );
  }
}

class OpenCaseHistory {
  final String? date;
  final String? user;
  final int? status;
  final String? remark;

  OpenCaseHistory({
    this.date,
    this.user,
    this.status,
    this.remark,
  });

  factory OpenCaseHistory.fromJson(Map<String, dynamic> json) {
    return OpenCaseHistory(
      date: json['datetime']?.toString() ?? json['date']?.toString() ?? json['Date']?.toString(),
      user: json['userCode']?.toString() ?? json['user']?.toString() ?? json['User']?.toString(),
      status: json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? json['Status']?.toString() ?? ''),
      remark: json['remark']?.toString() ?? json['Remark']?.toString(),
    );
  }
}

/// Response model for Open Case (GET)
class OpenCaseGetResponse {
  final int? status;
  final String? remark;
  final List<OpenCaseHistory>? history;

  OpenCaseGetResponse({
    this.status,
    this.remark,
    this.history,
  });

  factory OpenCaseGetResponse.fromJson(Map<String, dynamic> json) {
    var historyList = json['Table'] as List?;
    List<OpenCaseHistory>? parsedHistory;
    
    int? currentStatus;
    String? currentRemark;

    if (historyList != null && historyList.isNotEmpty) {
      parsedHistory = historyList.map((e) => OpenCaseHistory.fromJson(e)).toList();
      
      // ดึงสถานะและหมายเหตุล่าสุดมาแสดงเป็นค่าเริ่มต้น
      final latest = parsedHistory.last;
      currentStatus = latest.status;
      currentRemark = latest.remark;
    }

    return OpenCaseGetResponse(
      status: currentStatus ?? (json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? json['Status']?.toString() ?? '')),
      remark: currentRemark ?? json['remark']?.toString() ?? json['Remark']?.toString(),
      history: parsedHistory,
    );
  }
}

class CalendarSummaryResponse {
  final String status;
  final List<CalendarDaySummary> data;

  CalendarSummaryResponse({required this.status, required this.data});

  factory CalendarSummaryResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List?;
    return CalendarSummaryResponse(
      status: json['status']?.toString() ?? 'unknown',
      data: dataList != null
          ? dataList.map((e) => CalendarDaySummary.fromJson(e)).toList()
          : [],
    );
  }
}

class CalendarDaySummary {
  final String date;
  final List<CalendarJobSummary> jobs;

  CalendarDaySummary({required this.date, required this.jobs});

  factory CalendarDaySummary.fromJson(Map<String, dynamic> json) {
    var jobsList = json['jobs'] as List?;
    return CalendarDaySummary(
      date: json['date']?.toString() ?? '',
      jobs: jobsList != null
          ? jobsList.map((e) => CalendarJobSummary.fromJson(e)).toList()
          : [],
    );
  }
}

class CalendarJobSummary {
  final String jobId;
  final String jobName;
  final int documentCount;
  final int abnormalStoppedCount;
  final int abnormalRunningCount;
  final String? status;

  CalendarJobSummary({
    required this.jobId,
    required this.jobName,
    required this.documentCount,
    this.abnormalStoppedCount = 0,
    this.abnormalRunningCount = 0,
    this.status,
  });

  factory CalendarJobSummary.fromJson(Map<String, dynamic> json) {
    return CalendarJobSummary(
      jobId: (json['jobId'] ?? json['JobId'])?.toString() ?? '',
      jobName: (json['jobName'] ?? json['JobName'])?.toString() ?? '',
      documentCount: (json['documentCount'] ?? json['DocumentCount']) is int
          ? (json['documentCount'] ?? json['DocumentCount'])
          : int.tryParse((json['documentCount'] ?? json['DocumentCount'])?.toString() ?? '0') ?? 0,
      abnormalStoppedCount: (json['abnormalStoppedCount'] ?? json['AbnormalStoppedCount']) is int
          ? (json['abnormalStoppedCount'] ?? json['AbnormalStoppedCount'])
          : int.tryParse((json['abnormalStoppedCount'] ?? json['AbnormalStoppedCount'])?.toString() ?? '0') ?? 0,
      abnormalRunningCount: (json['abnormalRunningCount'] ?? json['AbnormalRunningCount']) is int
          ? (json['abnormalRunningCount'] ?? json['AbnormalRunningCount'])
          : int.tryParse((json['abnormalRunningCount'] ?? json['AbnormalRunningCount'])?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? json['Status'])?.toString(),
    );
  }
}

class NotificationHistoryItem {
  final int id;
  final String? userId;
  final String? documentId;
  final String? jobId;
  final String? machineId;
  final String? targetScreen;
  final String? jobName;
  final bool? isSuccess;
  final String? errorMessage;
  final String? sendDate;

  NotificationHistoryItem({
    required this.id,
    this.userId,
    this.documentId,
    this.jobId,
    this.machineId,
    this.targetScreen,
    this.jobName,
    this.isSuccess,
    this.errorMessage,
    this.sendDate,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['UserId']?.toString(),
      documentId: json['DocumentId']?.toString(),
      jobId: json['JobId']?.toString(),
      machineId: json['MachineId']?.toString(),
      targetScreen: json['TargetScreen']?.toString(),
      jobName: json['JobName']?.toString(),
      isSuccess: json['IsSuccess'] as bool?,
      errorMessage: json['ErrorMessage']?.toString(),
      sendDate: json['SendDate']?.toString(),
    );
  }
}

class NotificationHistoryResponse {
  final String status;
  final int totalPages;
  final int totalRecordCount;
  final List<NotificationHistoryItem> history;

  NotificationHistoryResponse({
    required this.status,
    required this.totalPages,
    required this.totalRecordCount,
    required this.history,
  });

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) {
    List<NotificationHistoryItem> parsedHistory = [];
    if (json['History'] != null) {
      if (json['History'] is String) {
        try {
          final decoded = jsonDecode(json['History']) as List;
          parsedHistory = decoded.map((e) => NotificationHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        } catch (e) {
          // Failed to parse string
        }
      } else if (json['History'] is List) {
        parsedHistory = (json['History'] as List).map((e) => NotificationHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    
    return NotificationHistoryResponse(
      status: json['status']?.toString() ?? 'unknown',
      totalPages: json['TotalPages'] is int ? json['TotalPages'] : int.tryParse(json['TotalPages']?.toString() ?? '0') ?? 0,
      totalRecordCount: json['TotalRecordCount'] is int ? json['TotalRecordCount'] : int.tryParse(json['TotalRecordCount']?.toString() ?? '0') ?? 0,
      history: parsedHistory,
    );
  }
}
