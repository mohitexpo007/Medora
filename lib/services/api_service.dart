import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/clinical_report_model.dart';
import 'summary_storage_service.dart';

/// Summary list item for history screen (stub)
class SummaryListItem {
  final String summaryId;
  final String patientName;
  final DateTime createdAt;
  final String summaryText;
  final String? animationAsset;

  SummaryListItem({
    required this.summaryId,
    required this.patientName,
    required this.createdAt,
    required this.summaryText,
    this.animationAsset,
  });

  factory SummaryListItem.fromJson(Map<String, dynamic> json) {
    return SummaryListItem(
      summaryId: json['summary_id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? 'Unknown Patient',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      summaryText: json['summary_text'] as String? ?? '',
      animationAsset: json['animation_asset'] as String?,
    );
  }
}

/// API Service for Clinical AI Backend
class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  // Use 127.0.0.1 for iOS simulator or physical devices on same network
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Duration timeout = Duration(seconds: 60);

  /// Analyze clinical note and generate summary
  /// 
  /// [noteText] - The clinical note text to analyze
  /// [patientId] - Optional patient identifier (defaults to "PT-0001")
  /// 
  /// Returns [ClinicalReportModel] on success
  /// Throws [Exception] on failure
  static Future<ClinicalReportModel> analyzeClinicalNote({
    required String noteText,
    String? patientId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/analyze');
    
    final requestBody = {
      'input_type': 'text',
      'content': noteText,
      'patient_id': patientId ?? 'PT-0001',
    };

    // Debug: Log request (masked content)
    final maskedContent = noteText.length > 50
        ? '${noteText.substring(0, 50)}... (${noteText.length} chars)'
        : noteText;
    print('📤 API Request: POST $url');
    print('📤 Request Body: {input_type: text, content: "$maskedContent", patient_id: ${requestBody['patient_id']}}');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      // Debug: Log response
      print('📥 Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Debug: Log red flags from API response
        final redFlagsRaw = jsonData['red_flags'];
        print('🔴 API DEBUG: Raw red_flags from API: $redFlagsRaw');
        print('🔴 API DEBUG: red_flags type: ${redFlagsRaw.runtimeType}');
        if (redFlagsRaw != null && redFlagsRaw is List) {
          print('🔴 API DEBUG: red_flags length: ${redFlagsRaw.length}');
          if (redFlagsRaw.isNotEmpty) {
            print('🔴 API DEBUG: First red flag: ${redFlagsRaw[0]}');
          }
        }
        
        return ClinicalReportModel.fromJson(jsonData);
      } else {
        final errorBody = response.body;
        throw Exception(
          'API Error ${response.statusCode}: ${errorBody.isNotEmpty ? errorBody : "Unknown error"}',
        );
      }
    } on http.ClientException catch (e) {
      print('❌ Network Error: $e');
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      print('❌ JSON Parse Error: $e');
      throw Exception('Invalid response format: ${e.message}');
    } catch (e) {
      print('❌ Unexpected Error: $e');
      rethrow;
    }
  }

  /// Upload clinical note (PDF / image) and get analysis.
  /// POST /api/analyze/upload, multipart: file, optional patient_id.
  /// Use [filePath] or [fileBytes] + [fileName]. Prefer path when available.
  static Future<Map<String, dynamic>> uploadClinicalNote({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    String? patientId,
  }) async {
    // #region agent log
    try {
      final logData = {
        'location': 'api_service.dart:121',
        'message': 'uploadClinicalNote called',
        'data': {
          'fileName': fileName,
          'hasFilePath': filePath != null && filePath.isNotEmpty,
          'hasFileBytes': fileBytes != null && fileBytes.isNotEmpty,
          'fileBytesLength': fileBytes?.length ?? 0,
          'patientId': patientId,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'upload-check',
        'hypothesisId': 'C',
      };
      await http.post(
        Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      ).catchError((_) {});
    } catch (_) {}
    // #endregion
    if ((filePath == null || filePath.isEmpty) &&
        (fileBytes == null || fileBytes.isEmpty)) {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:145',
          'message': 'No file path or bytes provided',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      throw Exception('Either filePath or fileBytes must be provided');
    }
    final url = Uri.parse('$baseUrl/api/analyze/upload');
    final request = http.MultipartRequest('POST', url);
    final String name = fileName.trim().isEmpty ? 'upload' : fileName;
    
    // #region agent log
    try {
      final logData = {
        'location': 'api_service.dart:165',
        'message': 'Creating multipart request',
        'data': {
          'url': url.toString(),
          'usingFilePath': filePath != null && filePath.isNotEmpty,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'upload-check',
        'hypothesisId': 'C',
      };
      await http.post(
        Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      ).catchError((_) {});
    } catch (_) {}
    // #endregion
    
    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: name),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes!, filename: name),
      );
    }
    if (patientId != null && patientId.isNotEmpty) {
      request.fields['patient_id'] = patientId;
    }
    try {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:190',
          'message': 'Sending upload request',
          'data': {'timeout': timeout.inSeconds},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      final stream = await request.send().timeout(timeout);
      final resp = await http.Response.fromStream(stream);
      
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:205',
          'message': 'Upload response received',
          'data': {
            'statusCode': resp.statusCode,
            'bodyLength': resp.body.length,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      if (resp.statusCode != 200) {
        // #region agent log
        try {
          final logData = {
            'location': 'api_service.dart:225',
            'message': 'Upload failed - non-200 status',
            'data': {
              'statusCode': resp.statusCode,
              'body': resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length),
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'upload-check',
            'hypothesisId': 'C',
          };
          await http.post(
            Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(logData),
          ).catchError((_) {});
        } catch (_) {}
        // #endregion
        throw Exception(
          'Upload failed ${resp.statusCode}: ${resp.body.isNotEmpty ? resp.body : "Unknown"}',
        );
      }
      final result = jsonDecode(resp.body) as Map<String, dynamic>;
      
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:245',
          'message': 'Upload successful',
          'data': {'resultKeys': result.keys.toList()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      return result;
    } on http.ClientException catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:263',
          'message': 'Network error in upload',
          'data': {'error': e.message},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:279',
          'message': 'Format error in upload response',
          'data': {'error': e.message},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      throw Exception('Invalid response: ${e.message}');
    } on TimeoutException catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:295',
          'message': 'Upload timeout',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      throw Exception('Upload timeout: ${e.message}');
    } catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:311',
          'message': 'Unexpected error in upload',
          'data': {'error': e.toString(), 'errorType': e.runtimeType.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      rethrow;
    }
  }

  /// Get all summaries from local storage
  static Future<List<SummaryListItem>> getAllSummaries({int limit = 100}) async {
    // #region agent log
    try {
      final logData = {
        'location': 'api_service.dart:163',
        'message': 'ApiService.getAllSummaries called',
        'data': {'limit': limit},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'load-check',
        'hypothesisId': 'C',
      };
      await http.post(
        Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      ).catchError((_) {});
    } catch (_) {}
    // #endregion
    try {
      final stored = await SummaryStorageService.getAllSummaries();
      
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:175',
          'message': 'Stored summaries retrieved',
          'data': {'count': stored.length},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'load-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      final items = stored
          .take(limit)
          .map((s) => SummaryStorageService.toSummaryListItem(s))
          .toList();
      
      // Sort by date (newest first)
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:190',
          'message': 'Returning SummaryListItems',
          'data': {'count': items.length},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'load-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      return items;
    } catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'api_service.dart:205',
          'message': 'Error loading summaries',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'load-check',
          'hypothesisId': 'C',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      print('❌ ApiService: Error loading summaries from storage: $e');
      // Fallback to empty list
      return [];
    }
  }

  /// Get summaries by date from local storage
  static Future<List<SummaryListItem>> getSummariesByDate(DateTime date) async {
    try {
      final stored = await SummaryStorageService.getSummariesByDate(date);
      return stored
          .map((s) => SummaryStorageService.toSummaryListItem(s))
          .toList();
    } catch (e) {
      print('❌ ApiService: Error loading summaries by date: $e');
      return [];
    }
  }

  /// Get summary by ID from local storage
  static Future<dynamic> getSummaryById(String summaryId) async {
    try {
      final reportData = await SummaryStorageService.getSummaryById(summaryId);
      if (reportData == null) {
        return _StubSummaryDetail(diagnoses: []);
      }
      
      // Convert to ClinicalReportModel and extract diagnoses from differentialDiagnoses
      final report = ClinicalReportModel.fromJson(reportData);
      final diagnoses = report.differentialDiagnoses
          .map((d) => d.diagnosis)
          .toList();
      return _StubSummaryDetail(diagnoses: diagnoses);
    } catch (e) {
      print('❌ ApiService: Error getting summary by ID: $e');
      return _StubSummaryDetail(diagnoses: []);
    }
  }
}

/// Stub class for summary detail
class _StubSummaryDetail {
  final List<String> diagnoses;
  
  _StubSummaryDetail({required this.diagnoses});
}
