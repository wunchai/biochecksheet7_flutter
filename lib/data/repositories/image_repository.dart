// lib/data/repositories/image_repository.dart
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
import 'package:biochecksheet7_flutter/data/database/daos/image_dao.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart';
import 'package:biochecksheet7_flutter/data/network/image_api_service.dart'; // Import ImageApiService
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // For ImageUploadResult
import 'dart:typed_data'; // For Uint8List
import 'dart:convert'; // For base64Encode
import 'dart:io'; // For File
import 'package:drift/drift.dart' as drift;

class ImageRepository {
  final ImageDao _imageDao;
  final ImageApiService _imageApiService;

  ImageRepository({required AppDatabase appDatabase})
      : _imageDao = appDatabase.imageDao,
        _imageApiService = ImageApiService();

  // You can add other image-related methods here if needed,
  // such as getting images by problemId, deleting images etc.
  // Most of these are already in ImageDao and ImageViewModel.

  /// NEW: Uploads a single image to the server API.
  /// Takes the DbImage object and its raw bytes as Uint8List.
  /// Converts bytes to Base64 and calls ImageApiService.
  Future<ImageUploadResult> uploadImageToServer(
      DbImage image, Uint8List imageBytes) async {
    final String base64ImageData = base64Encode(imageBytes);
    return _imageApiService.uploadImage(image,
        base64ImageData: base64ImageData);
  }

  /// NEW: Gets images with syncStatus 0 (pending upload).
  /// This method now fetches ALL images with syncStatus 0, regardless of other IDs.
  Future<List<DbImage>> getImagesForUpload() async {
    // <<< CRUCIAL FIX: Removed filtering parameters
    // Query for images that have syncStatus = 0 using the new DAO method
    return await _imageDao
        .getImagesBySyncStatus(0); // <<< Call the new DAO method
  }

  /// NEW: Updates syncStatus of a DbImage record by its GUID.
  Future<bool> updateImageSyncStatusByGuid(
      String guid, int newSyncStatus) async {
    final existingImage =
        await _imageDao.getImageByGuid(guid); // Assume DAO has getImageByGuid
    if (existingImage == null) {
      print('Image with GUID $guid not found for sync status update.');
      return false;
    }
    return await _imageDao.updateImage(
      existingImage.copyWith(
        statusSync: drift.Value(newSyncStatus).value,
        lastSync: drift.Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  // TODO: Implement getImageByGuid in ImageDao.
  // TODO: You might need a helper to read file bytes for native images before uploading.
  // Image data (Uint8List) is retrieved using ImageProcessor, then saved locally.
  // For uploading, we need to read the saved file.
  Future<Uint8List?> getImageBytesFromPath(String? filepath) async {
    if (filepath == null || filepath.isEmpty) return null;
    try {
      final File file = File(filepath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error reading image file bytes from path: $e');
    }
    return null;
  }
}
