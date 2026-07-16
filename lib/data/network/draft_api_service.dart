// lib/data/network/draft_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:biochecksheet7_flutter/core/app_config.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

class DraftApiService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<void> uploadDraftJobs(List<DbDraftJob> jobs) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTJOB_SYNC");
    print("Uploading draft jobs to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords = jobs.map((record) {
      return {
        "uid": record.uid,
        "jobName": record.jobName,
        "location": record.location,
        "machineName": record.machineName,
        "documentId": record.documentId,
        "status": record.status,
        "createDate": record.createDate,
        "updatedAt": record.updatedAt,
        "recordVersion": record.recordVersion,
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username": "000000" // Assuming username parameter is still required
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DRAFTJOB_SYNC",
      "Paremeter":
          jsonEncode(parameterObject) // Typo 'Paremeter' matches API convention
    });

    print("Request body for draft job upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Draft Job Upload API Response status: ${response.statusCode}");
      print("Draft Job Upload API Response body: $decodedBody");

      if (response.statusCode != 200) {
        throw Exception(
            "Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading draft jobs: ${e.message}");
      throw Exception("Network error uploading draft jobs: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading draft jobs: $e");
      throw Exception("An unexpected error occurred uploading draft jobs: $e");
    }
  }

  Future<void> uploadDraftMachines(List<DbDraftMachine> machines,
      {int? recordVersion}) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTMACHINE_SYNC");
    print("Uploading draft machines to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords = machines.map((record) {
      return {
        "uid": record.uid,
        "draftJobId": record.draftJobId,
        "machineId": record.machineId,
        "machineName": record.machineName,
        "machineType": record.machineType,
        "machineCode": record.machineCode,
        if (recordVersion != null) "recordVersion": recordVersion,
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username": "000000"
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DRAFTMACHINE_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });

    print("Request body for draft machine upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Draft Machine Upload API Response status: ${response.statusCode}");
      print("Draft Machine Upload API Response body: $decodedBody");

      if (response.statusCode != 200) {
        throw Exception(
            "Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading draft machines: ${e.message}");
      throw Exception("Network error uploading draft machines: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading draft machines: $e");
      throw Exception(
          "An unexpected error occurred uploading draft machines: $e");
    }
  }

  Future<void> uploadDraftTags(List<DbDraftTag> tags,
      {int? recordVersion}) async {
    final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTTAG_SYNC");
    print("Uploading draft tags to API: $uri");
    final headers = {"Content-Type": "application/json"};

    final List<Map<String, dynamic>> jsonRecords = tags.map((record) {
      return {
        "uid": record.uid,
        "draftJobId": record.draftJobId,
        "draftMachineId": record.draftMachineId,
        "tagGroupId": record.tagGroupId,
        "tagGroupName": record.tagGroupName,
        "tagName": record.tagName,
        "tagType": record.tagType,
        "tagSelectionValue": record.tagSelectionValue,
        "specMin": record.specMin,
        "specMax": record.specMax,
        "unit": record.unit,
        "description": record.description,
        "machineCode": record.machineCode,
        if (recordVersion != null) "recordVersion": recordVersion,
      };
    }).toList();

    final Map<String, dynamic> parameterObject = {
      "record": jsonEncode(jsonRecords),
      "username": "000000"
    };

    final body = jsonEncode({
      "ServiceName": "CHECKSHEET_DRAFTTAG_SYNC",
      "Paremeter": jsonEncode(parameterObject)
    });

    print("Request body for draft tag upload: $body");

    try {
      final response = await http.post(uri, headers: headers, body: body);
      final String decodedBody = utf8.decode(response.bodyBytes);
      print("Draft Tag Upload API Response status: ${response.statusCode}");
      print("Draft Tag Upload API Response body: $decodedBody");

      if (response.statusCode != 200) {
        throw Exception(
            "Upload API failed: Status code ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("Network error uploading draft tags: ${e.message}");
      throw Exception("Network error uploading draft tags: ${e.message}");
    } catch (e) {
      print("An unexpected error occurred uploading draft tags: $e");
      throw Exception("An unexpected error occurred uploading draft tags: $e");
    }
  }

  Future<List<DbDraftJob>> downloadDraftJobs() async {
    List<DbDraftJob> allJobs = [];
    int pageIndex = 1;
    const int pageSize = 20;
    bool hasMoreData = true;

    while (hasMoreData) {
      final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTJOB_PAGED_SYNC");
      final body = jsonEncode({
        'userId': '000000',
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
      });

      try {
        final response = await http.post(uri,
            headers: {'Content-Type': 'application/json'}, body: body);
        final String decodedBody = utf8.decode(response.bodyBytes);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
          if (responseJson['Jobs'] != null) {
            final decodedJobs = jsonDecode(responseJson['Jobs']);
            if (decodedJobs is List) {
              if (decodedJobs.isEmpty) {
                hasMoreData = false;
                break;
              }

              final List<DbDraftJob> syncedJobs = decodedJobs.map((jobData) {
                return DbDraftJob(
                  uid: jobData['Uid']?.toString() ?? '',
                  jobName: jobData['JobName'] ?? '',
                  location: jobData['Location'] ?? '',
                  machineName: jobData['MachineName'],
                  documentId: jobData['DocumentId'],
                  status: jobData['Status'] ?? 0,
                  createDate: jobData['CreateDate'] ?? '',
                  updatedAt: jobData['UpdatedAt'],
                  recordVersion: jobData['RecordVersion'] ?? 1,
                );
              }).toList();

              allJobs.addAll(syncedJobs);
              if (syncedJobs.length < pageSize) {
                hasMoreData = false;
              } else {
                pageIndex++;
              }
            } else {
              hasMoreData = false;
            }
          } else {
            hasMoreData = false;
          }
        } else {
          print("Error downloading jobs: Status code ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("Error downloading draft jobs: $e");
        hasMoreData = false;
      }
    }
    return allJobs;
  }

  Future<List<DbDraftMachine>> downloadDraftMachines() async {
    List<DbDraftMachine> allMachines = [];
    int pageIndex = 1;
    const int pageSize = 20;
    bool hasMoreData = true;

    while (hasMoreData) {
      final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTMACHINE_PAGED_SYNC");
      final body = jsonEncode({
        'userId': '000000',
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
      });

      try {
        final response = await http.post(uri,
            headers: {'Content-Type': 'application/json'}, body: body);
        final String decodedBody = utf8.decode(response.bodyBytes);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
          if (responseJson['Jobs'] != null) {
            final decodedMachines = jsonDecode(responseJson['Jobs']);
            if (decodedMachines is List) {
              if (decodedMachines.isEmpty) {
                hasMoreData = false;
                break;
              }

              final List<DbDraftMachine> syncedMachines =
                  decodedMachines.map((machineData) {
                return DbDraftMachine(
                  uid: machineData['Uid']?.toString() ?? '',
                  draftJobId: machineData['DraftJobId']?.toString() ?? '',
                  machineId: machineData['MachineId']?.toString(),
                  machineName: machineData['MachineName'],
                  machineType: machineData['MachineType'],
                  machineCode: machineData['MachineCode'],
                );
              }).toList();

              allMachines.addAll(syncedMachines);
              if (syncedMachines.length < pageSize) {
                hasMoreData = false;
              } else {
                pageIndex++;
              }
            } else {
              hasMoreData = false;
            }
          } else {
            hasMoreData = false;
          }
        } else {
          hasMoreData = false;
        }
      } catch (e) {
        print("Error downloading draft machines: $e");
        hasMoreData = false;
      }
    }
    return allMachines;
  }

  Future<List<DbDraftTag>> downloadDraftTags() async {
    List<DbDraftTag> allTags = [];
    int pageIndex = 1;
    const int pageSize = 20;
    bool hasMoreData = true;

    while (hasMoreData) {
      final uri = Uri.parse("$_baseUrl/CHECKSHEET_DRAFTTAG_PAGED_SYNC");
      final body = jsonEncode({
        'userId': '000000',
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
      });

      try {
        final response = await http.post(uri,
            headers: {'Content-Type': 'application/json'}, body: body);
        final String decodedBody = utf8.decode(response.bodyBytes);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(decodedBody);
          if (responseJson['Jobs'] != null) {
            final decodedTags = jsonDecode(responseJson['Jobs']);
            if (decodedTags is List) {
              if (decodedTags.isEmpty) {
                hasMoreData = false;
                break;
              }

              final List<DbDraftTag> syncedTags = decodedTags.map((tagData) {
                return DbDraftTag(
                  uid: tagData['Uid']?.toString() ?? '',
                  draftJobId: tagData['DraftJobId']?.toString() ?? '',
                  draftMachineId: tagData['DraftMachineId']?.toString() ?? '',
                  tagGroupId: tagData['TagGroupId']?.toString(),
                  tagGroupName: tagData['TagGroupName'],
                  tagName: tagData['TagName'],
                  tagType: tagData['TagType'],
                  tagSelectionValue: tagData['TagSelectionValue'],
                  specMin: tagData['SpecMin'],
                  specMax: tagData['SpecMax'],
                  unit: tagData['Unit'],
                  description: tagData['Description'],
                  machineCode: tagData['MachineCode'],
                );
              }).toList();

              allTags.addAll(syncedTags);
              if (syncedTags.length < pageSize) {
                hasMoreData = false;
              } else {
                pageIndex++;
              }
            } else {
              hasMoreData = false;
            }
          } else {
            hasMoreData = false;
          }
        } else {
          hasMoreData = false;
        }
      } catch (e) {
        print("Error downloading draft tags: $e");
        hasMoreData = false;
      }
    }
    return allTags;
  }
}
