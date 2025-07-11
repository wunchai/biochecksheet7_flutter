// lib/data/models/data_summary.dart

/// Model สำหรับเก็บข้อมูลสรุปสถานะการซิงค์และจำนวนข้อมูล.
class DataSummary {
  // Last Sync Timestamps for Master Data Tables
  final String? lastSyncUser;
  final String? lastSyncJob;
  final String? lastSyncJobMachine;
  final String? lastSyncJobTag;
  final String? lastSyncProblem;

  // DocumentRecord Summary
  final int pendingDocumentRecordsCount; // Status 2, SyncStatus 0
  final String? lastSyncPendingDocumentRecords; // Last sync for these records

  // REMOVED: pendingImageUploadCount and lastSyncPendingImageUpload
  // final int pendingImageUploadCount;
  // final String? lastSyncPendingImageUpload;

  // NEW: Image Summary - Divided by source type
  final int
      pendingDocumentImageUploadCount; // Images tied to DocumentRecords (problemId is null), status 2 or 3, syncStatus 0
  final String? lastSyncPendingDocumentImageUpload;

  final int
      pendingProblemImageUploadCount; // Images tied to Problems (problemId is not null), status 2 or 3, syncStatus 0
  final String? lastSyncPendingProblemImageUpload;

  DataSummary({
    this.lastSyncUser,
    this.lastSyncJob,
    this.lastSyncJobMachine,
    this.lastSyncJobTag,
    this.lastSyncProblem,
    this.pendingDocumentRecordsCount = 0,
    this.lastSyncPendingDocumentRecords,
    // this.pendingImageUploadCount = 0, // REMOVED
    // this.lastSyncPendingImageUpload, // REMOVED
    this.pendingDocumentImageUploadCount = 0, // NEW
    this.lastSyncPendingDocumentImageUpload, // NEW
    this.pendingProblemImageUploadCount = 0, // NEW
    this.lastSyncPendingProblemImageUpload, // NEW
  });

  // Helper method to format DateTime for display
  String _formatDateTime(String? iso8601String) {
    if (iso8601String == null || iso8601String.isEmpty) {
      return 'N/A';
    }
    try {
      final dateTime = DateTime.parse(iso8601String);
      // Format to dd/MM/yyyy HH:mm:ss
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}:'
          '${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Getters for formatted display
  String get formattedLastSyncUser => _formatDateTime(lastSyncUser);
  String get formattedLastSyncJob => _formatDateTime(lastSyncJob);
  String get formattedLastSyncJobMachine => _formatDateTime(lastSyncJobMachine);
  String get formattedLastSyncJobTag => _formatDateTime(lastSyncJobTag);
  String get formattedLastSyncProblem => _formatDateTime(lastSyncProblem);
  String get formattedLastSyncPendingDocumentRecords =>
      _formatDateTime(lastSyncPendingDocumentRecords);
  // String get formattedLastSyncPendingImageUpload => _formatDateTime(lastSyncPendingImageUpload); // REMOVED
  String get formattedLastSyncPendingDocumentImageUpload =>
      _formatDateTime(lastSyncPendingDocumentImageUpload); // NEW
  String get formattedLastSyncPendingProblemImageUpload =>
      _formatDateTime(lastSyncPendingProblemImageUpload); // NEW
}
