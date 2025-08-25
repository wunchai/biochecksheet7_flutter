// lib/data/network/image_api_service.dart
import 'dart:convert'; // For base64Encode, jsonEncode
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:biochecksheet7_flutter/data/database/app_database.dart';
//import 'package:biochecksheet7_flutter/data/database/tables/image_table.dart'; // For DbImage
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart'; // For ImageUploadResult

const String _baseUrl = "http://10.1.200.26/ServiceJson/Service4.svc";

class ImageApiService {
  /// Uploads a single image to the API.
  /// The image data should be passed as Base64 string.
  /// Returns ImageUploadResult from the API.
  Future<ImageUploadResult> uploadImage(DbImage image,
      {required String base64ImageData}) async {
    final uri = Uri.parse(
        "$_baseUrl/CheckSheet_Image_Upload"); // Assumed API Endpoint for image upload
    print("Uploading image to API: $uri");
    final headers = {"Content-Type": "application/json"};

    // Map DbImage fields to API's expected JSON format
    final Map<String, dynamic> imageJson = {
      "Guid":
          image.guid, // Assuming GUID is what API uses to identify the image
      "ImageIndex": image.imageIndex,
      "Picture": base64ImageData, // Base64 string of the image
      "ImageUri": image.imageUri, // Original URI/path (optional for API)
      "Filename": image.filename,
      "Filepath": image.filepath, // Original filepath (optional for API)
      "DocumentId": image.documentId,
      "JobId": image.jobId,
      "MachineId": image.machineId,
      "TagId": image.tagId,
      "ProblemId": image.problemId,
      "CreateDate": image.createDate,
      "Status": image.status,
      "LastSync": image.lastSync,
      "StatusSync": image.statusSync,
      // Add other fields from DbImage as required by your API
    };

    final body = jsonEncode({
      "ServiceName": "CheckSheet_Image_Upload",
      "Paremeter": jsonEncode(
          imageJson), // Parameter should be JSON string of the image object
    });
    print("Request body for image upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Image Upload API Response status: ${response.statusCode}");
      print("Image Upload API Response body: $decodedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
        // Assuming API returns a structure like {"Table":[{"guid":"...", "result":3}]}
        if (responseJson['Table'] != null &&
            responseJson['Table'] is List &&
            responseJson['Table'].isNotEmpty) {
          return ImageUploadResult.fromJson(responseJson['Table']
              [0]); // Assuming it returns a list with one result
        } else {
          throw Exception(
              "Image Upload API response format invalid (missing 'Table' key or empty).");
        }
      } else {
        throw Exception(
            "Image Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading image: ${e.message}");
      throw Exception("Network error uploading image: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading image: $e");
      throw Exception("An unexpected error occurred uploading image: $e");
    }
  }
}
