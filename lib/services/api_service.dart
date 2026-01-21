import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinical_report_model.dart';

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

  /// Get all summaries (stub - returns empty list)
  /// TODO: Implement when backend supports this endpoint
  static Future<List<SummaryListItem>> getAllSummaries({int limit = 100}) async {
    // Stub implementation - returns empty list
    return [];
  }

  /// Get summaries by date (stub - returns empty list)
  /// TODO: Implement when backend supports this endpoint
  static Future<List<SummaryListItem>> getSummariesByDate(DateTime date) async {
    // Stub implementation - returns empty list
    return [];
  }

  /// Get summary by ID (stub - returns object with diagnoses)
  /// TODO: Implement when backend supports this endpoint
  static Future<dynamic> getSummaryById(String summaryId) async {
    // Stub implementation - returns object with empty diagnoses list
    return _StubSummaryDetail(diagnoses: []);
  }
}

/// Stub class for summary detail
class _StubSummaryDetail {
  final List<String> diagnoses;
  
  _StubSummaryDetail({required this.diagnoses});
}
