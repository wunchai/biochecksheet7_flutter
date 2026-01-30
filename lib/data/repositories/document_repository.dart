// lib/data/repositories/document_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_dao.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/document_table.dart'; // For DbDocument
import 'package:drift/drift.dart' as drift;

// NEW: Import for DocumentRecordDao and DocumentRecordTable
import 'package:biochecksheet7_flutter/data/database/daos/document_record_dao.dart';
import 'package:biochecksheet7_flutter/data/database/daos/document_machine_dao.dart'; // <<< NEW
import 'package:biochecksheet7_flutter/data/database/daos/job_machine_dao.dart'; // <<< NEW
//import 'package:biochecksheet7_flutter/data/database/tables/document_record_table.dart';

/// Repository for managing document data.
/// This class abstracts data operations from UI/ViewModels.
class DocumentRepository {
  final DocumentDao _documentDao;
  final DocumentRecordDao _documentRecordDao;
  final DocumentMachineDao _documentMachineDao; // <<< NEW
  final JobMachineDao _jobMachineDao; // <<< NEW

  // TODO: หากมี DocumentApiService ก็เพิ่มที่นี่
  // final DocumentApiService _documentApiService;

  DocumentRepository({required AppDatabase appDatabase})
      : _documentDao = appDatabase.documentDao,
        _documentRecordDao = appDatabase.documentRecordDao,
        _documentMachineDao = appDatabase.documentMachineDao, // <<< NEW
        _jobMachineDao = appDatabase.jobMachineDao; // <<< NEW
  // _documentApiService = documentApiService ?? DocumentApiService(); // หากมี API
  // _documentApiService = documentApiService ?? DocumentApiService(); // หากมี API

  /// Equivalent to DbDocumentCode.initNewDocument
  Future<void> newDocument({
    required String documentName,
    required String jobId,
    required String userId,
    // TODO: เพิ่ม parameters อื่นๆ ที่จำเป็นสำหรับการสร้างเอกสารใหม่
  }) async {
    try {
      final newDocId =
          _generateUniqueDocumentId(jobId); // สร้าง Document ID ใหม่ (ตัวอย่าง)

      final newDocumentEntry = DocumentsCompanion(
        documentId: drift.Value(newDocId),
        documentName: drift.Value(documentName),
        jobId: drift.Value(jobId),
        userId: drift.Value(userId),
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: const drift.Value(0), // Default status for new document
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );

      await _documentDao.insertDocument(newDocumentEntry);

      // CRUCIAL: Copy JobMachines (Master) to DocumentMachines (Runtime)
      final jobMachines = await _jobMachineDao.getJobMachinesByJobId(jobId);
      if (jobMachines.isNotEmpty) {
        final runtimeMachines = jobMachines.map((master) {
          return DocumentMachinesCompanion(
            id: drift.Value(master.id),
            jobId: drift.Value(master.jobId!),
            documentId: drift.Value(newDocId), // New Document ID
            machineId: drift.Value(master.machineId!),
            machineName: drift.Value(master.machineName),
            machineType: drift.Value(master.machineType),
            description: drift.Value(master.description),
            specification: drift.Value(master.specification),
            status: drift.Value(master.status),
            uiType: drift.Value(master.uiType),
            createDate: drift.Value(master.createDate),
            createBy: drift.Value(master.createBy),
            lastSync: drift.Value(DateTime.now().toIso8601String()),
            // aggregation columns default to 0
          );
        }).toList();
        await _documentMachineDao.insertAllDocumentMachines(runtimeMachines);
        print(
            'Copied ${runtimeMachines.length} machines from Master to Runtime.');
      }

      // TODO: หากมี API สำหรับ Sync เอกสารใหม่ขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.uploadNewDocument(newDocumentEntry);

      print('New document created: $documentName (ID: $newDocId)');
    } catch (e) {
      print('Error creating new document: $e');
      throw Exception('Failed to create new document: $e');
    }
  }

  /// Equivalent to DbDocumentCode.initCopyDocument
  /// Equivalent to DbDocumentCode.initCopyDocument
  Future<void> copyDocument({
    required String originalDocumentId,
    required String newDocumentName,
    required String newJobId, // JobId ของเอกสารใหม่
    required String userId,
  }) async {
    try {
      final originalDoc = await _documentDao.getDocument(originalDocumentId);

      if (originalDoc == null) {
        throw Exception('Original document not found: $originalDocumentId');
      }

      final newDocId =
          _generateUniqueDocumentId(newJobId); // สร้าง Document ID ใหม่

      final copiedDocumentEntry = DocumentsCompanion(
        documentId: drift.Value(newDocId),
        documentName: drift.Value(newDocumentName),
        jobId: drift.Value(newJobId), // New jobId for the copied document
        userId: drift.Value(userId),
        createDate: drift.Value(DateTime.now().toIso8601String()),
        status: drift.Value(originalDoc.status), // Copy status from original
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      );

      await _documentDao.insertDocument(copiedDocumentEntry);

      // CRUCIAL: Copy JobMachines (Master) to populate DocumentMachines (Runtime) for the copied document
      // We copy from Master Data to ensure we have a clean set of machines structure.
      final jobMachines = await _jobMachineDao.getJobMachinesByJobId(newJobId);
      if (jobMachines.isNotEmpty) {
        final runtimeMachines = jobMachines.map((master) {
          return DocumentMachinesCompanion(
            id: drift.Value(master.id),
            jobId: drift.Value(master.jobId!),
            documentId: drift.Value(newDocId),
            machineId: drift.Value(master.machineId!),
            machineName: drift.Value(master.machineName),
            machineType: drift.Value(master.machineType),
            description: drift.Value(master.description),
            specification: drift.Value(master.specification),
            status: drift.Value(master.status),
            uiType: drift.Value(master.uiType),
            createDate: drift.Value(master.createDate),
            createBy: drift.Value(master.createBy),
            lastSync: drift.Value(DateTime.now().toIso8601String()),
          );
        }).toList();
        await _documentMachineDao.insertAllDocumentMachines(runtimeMachines);
      }

      // CRUCIAL ADDITION: Copy associated document records
      final originalRecords =
          await _documentRecordDao.getRecordsByDocumentId(originalDocumentId);
      if (originalRecords.isNotEmpty) {
        final List<DocumentRecordsCompanion> copiedRecords =
            originalRecords.map((record) {
          return DocumentRecordsCompanion(
            // Copy all fields from original record, but update documentId, jobId, userId, and timestamp
            documentId: drift.Value(newDocId), // New document ID
            machineId: drift.Value(record.machineId),
            jobId: drift.Value(newJobId), // New job ID
            tagId: drift.Value(record.tagId),
            tagName: drift.Value(record.tagName),
            tagType: drift.Value(record.tagType),
            tagGroupId: drift.Value(record.tagGroupId),
            tagGroupName: drift.Value(record.tagGroupName),
            tagSelectionValue: drift.Value(record.tagSelectionValue),
            description: drift.Value(record.description),
            specification: drift.Value(record.specification),
            specMin: drift.Value(record.specMin),
            specMax: drift.Value(record.specMax),
            unit: drift.Value(record.unit),
            queryStr: drift.Value(record.queryStr),
            value: drift.Value(record.value), // Copy existing value
            valueType: drift.Value(record.valueType),
            remark: drift.Value(record.remark), // Copy existing remark
            status: drift.Value(record.status),
            unReadable: drift.Value(record.unReadable),
            lastSync: drift.Value(
                DateTime.now().toIso8601String()), // New sync timestamp
          );
        }).toList();
        await _documentRecordDao.insertAllDocumentRecords(copiedRecords);
        print('Copied ${copiedRecords.length} records for new document.');
      }

      // TODO: หากมี API สำหรับ Sync เอกสารที่คัดลอกขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.uploadCopiedDocument(copiedDocumentEntry);

      print(
          'Document $originalDocumentId copied to $newDocumentName (ID: $newDocId)');
    } catch (e) {
      print('Error copying document: $e');
      throw Exception('Failed to copy document: $e');
    }
  }

  /// Equivalent to DbDocumentCode.deleteDocument
  Future<void> deleteDocument({
    required int uid, // Use local uid for deletion
    required String
        documentId, // Use documentId for server sync and record deletion
    // TODO: job ID อาจจำเป็นสำหรับการอัปเดต UI หรือ server
  }) async {
    try {
      final docToDelete = await _documentDao.getDocument(documentId);
      if (docToDelete == null) {
        throw Exception('Document not found for deletion: $documentId');
      }

      await _documentDao.deleteDocument(docToDelete); // Delete main document

      // CRUCIAL ADDITION: Delete associated document records
      await _documentRecordDao.deleteAllRecordsByDocumentId(documentId);
      print('Deleted all associated records for document $documentId.');

      // TODO: หากมี API สำหรับ Sync การลบเอกสารขึ้น Server, ให้เรียกใช้ที่นี่
      // await _documentApiService.deleteDocumentOnServer(documentId);

      print('Document deleted: $documentId');
    } catch (e) {
      print('Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Validates and closes the document (Job).
  ///
  /// Validation Logic:
  /// 1. Iterates through all machines in the document.
  /// 2. If a machine is "touched" (savedTags > 0), it must be fully completed.
  ///    - A machine is considered complete if its derived aggregate status is 2 (Saved), 3 (Posted), or 4 (Synced).
  ///    - If a machine is partially done (In Progress, status 1), validation fails.
  /// 3. "Untouched" machines (savedTags == 0) are skipped and do not block closing.
  ///
  /// Returns `null` if successful, or an error message `String` if validation fails.
  Future<String?> closeDocument(String documentId) async {
    try {
      // 1. Fetch all machines for this document
      final machines =
          await _documentMachineDao.getDocumentMachineList(documentId);

      if (machines.isEmpty) {
        return "ไม่พบข้อมูลเครื่องจักรสำหรับเอกสารนี้";
      }

      // 2. Validate each machine
      for (final machine in machines) {
        final int savedTags = machine.savedTags;
        final int totalTags = machine.totalTags;
        final int aggStatus = machine.aggregateStatus;

        // Condition A: Untouched Machine -> Skip
        if (savedTags == 0) {
          continue;
        }

        // Condition B: Touched Machine -> MUST be completed
        // Aggregate Status: 1=In Progress, 2=Saved, 3=Posted, 4=Synced
        // We require at least status 2 (Saved all) to consider it "Done" locally.
        // Or strictly check if savedTags == totalTags
        if (savedTags < totalTags) {
          return "เครื่องจักร '${machine.machineName}' ยังตรวจเช็คไม่ครบ ($savedTags/$totalTags รายการ)";
        }

        // Double check with aggregate status (redundant but safe)
        if (aggStatus < 2) {
          return "กรุณาบันทึกข้อมูลเครื่องจักร '${machine.machineName}' ให้ครบถ้วน";
        }
      }

      // NEW: Requirement - At least one machine must be fully "Posted" (postedTags == totalTags)
      // This ensures the job isn't closed without any real work being finalized.
      bool hasAtLeastOnePostedMachine =
          machines.any((m) => m.totalTags > 0 && m.postedTags == m.totalTags);

      if (!hasAtLeastOnePostedMachine) {
        return "ไม่สามารถปิดงานได้: ต้องมีเครื่องจักรที่บันทึกข้อมูลและกดส่ง (Post) ครบถ้วนอย่างน้อย 1 รายการ";
      }

      // 3. If all validation passes, update Document status to Closed (e.g., 2)
      // Assuming 2 = Closed/Completed in DbDocument
      final doc = await _documentDao.getDocument(documentId);
      if (doc != null) {
        await _documentDao.updateDocument(doc.copyWith(
            status: 2,
            lastSync: drift.Value(DateTime.now().toIso8601String())));
        print('Document $documentId closed successfully.');
        return null; // Success
      } else {
        return "ไม่พบเอกสารต้นฉบับ";
      }
    } catch (e) {
      print('Error closing document: $e');
      return "เกิดข้อผิดพลาดในการปิดงาน: $e";
    }
  }

  /// NEW: Retrieve a document by its ID.
  Future<DbDocument?> getDocument(String documentId) {
    return _documentDao.getDocument(documentId);
  }

  // Helper function to generate a unique document ID (example, adjust as needed)
  String _generateUniqueDocumentId(String jobId) {
    return '${jobId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
