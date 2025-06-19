// lib/data/network/sync_status.dart
// นี่คือ Sealed class สำหรับผลลัพธ์ของการ Sync ข้อมูลทั่วไป (ไม่ใช่แค่ User)
sealed class SyncStatus {
  const SyncStatus();
}

// แสดงว่า Sync สำเร็จ
class SyncSuccess extends SyncStatus {
  const SyncSuccess();
}

// แสดงว่า Sync ล้มเหลวพร้อมข้อความผิดพลาด
class SyncFailed extends SyncStatus {
  const SyncFailed(this.errorMessage);
  final String errorMessage;
}

// แสดงว่า Sync มีข้อผิดพลาดทางเทคนิค (เช่น Network error, Parsing error)
class SyncError extends SyncStatus {
  const SyncError(this.exception);
  final Exception exception;
}