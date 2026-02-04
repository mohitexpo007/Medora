import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/clinical_report_model.dart';
import 'api_service.dart';

/// Service for storing and retrieving summaries locally
class SummaryStorageService {
  static const String _storageKey = 'stored_summaries';
  
  /// Save a summary to local storage
  static Future<void> saveSummary({
    required ClinicalReportModel report,
    required String patientName,
    String? patientId,
  }) async {
    // #region agent log
    try {
      final logData = {
        'location': 'summary_storage_service.dart:11',
        'message': 'saveSummary called',
        'data': {
          'patientName': patientName,
          'patientId': patientId,
          'hasReport': report != null,
          'reportId': report.requestId,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'save-check',
        'hypothesisId': 'A',
      };
      await http.post(
        Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      ).catchError((_) {});
    } catch (_) {}
    // #endregion
    try {
      final prefs = await SharedPreferences.getInstance();
      final summaries = await getAllSummaries();
      
      // #region agent log
      try {
        final logData = {
          'location': 'summary_storage_service.dart:35',
          'message': 'Existing summaries count before save',
          'data': {'count': summaries.length},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'save-check',
          'hypothesisId': 'A',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      // Extract diagnoses from differential diagnoses
      final diagnoses = report.differentialDiagnoses
          .map((d) => d.diagnosis)
          .toList();
      
      // Determine animation asset (will be calculated when loading)
      final summaryText = report.summary?.summaryText ?? '';
      
      // Create a summary item
      final summaryItem = {
        'summary_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'patient_name': patientName,
        'created_at': DateTime.now().toIso8601String(),
        'summary_text': summaryText,
        'diagnoses': diagnoses,
        'animation_asset': null, // Will be calculated when loading
        'report_data': _reportToJson(report), // Store full report data
      };
      
      summaries.add(summaryItem);
      
      // Save to preferences
      final jsonString = jsonEncode(summaries);
      await prefs.setString(_storageKey, jsonString);
      
      // #region agent log
      try {
        final logData = {
          'location': 'summary_storage_service.dart:70',
          'message': 'Summary saved successfully',
          'data': {
            'patientName': patientName,
            'summaryId': summaryItem['summary_id'],
            'totalSummaries': summaries.length,
            'summaryTextLength': summaryText.length,
            'diagnosesCount': diagnoses.length,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'save-check',
          'hypothesisId': 'A',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      print('✅ SummaryStorageService: Saved summary for $patientName');
    } catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'summary_storage_service.dart:95',
          'message': 'Error saving summary',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'save-check',
          'hypothesisId': 'A',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      print('❌ SummaryStorageService: Error saving summary: $e');
    }
  }
  
  /// Get all stored summaries
  static Future<List<Map<String, dynamic>>> getAllSummaries() async {
    // #region agent log
    try {
      final logData = {
        'location': 'summary_storage_service.dart:52',
        'message': 'getAllSummaries called',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'load-check',
        'hypothesisId': 'B',
      };
      await http.post(
        Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      ).catchError((_) {});
    } catch (_) {}
    // #endregion
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        // #region agent log
        try {
          final logData = {
            'location': 'summary_storage_service.dart:68',
            'message': 'No stored summaries found',
            'data': {'jsonString': null},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'load-check',
            'hypothesisId': 'B',
          };
          await http.post(
            Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(logData),
          ).catchError((_) {});
        } catch (_) {}
        // #endregion
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(jsonString);
      final summaries = decoded.cast<Map<String, dynamic>>();
      
      // #region agent log
      try {
        final logData = {
          'location': 'summary_storage_service.dart:85',
          'message': 'Loaded summaries from storage',
          'data': {
            'count': summaries.length,
            'summaryIds': summaries.map((s) => s['summary_id']).toList(),
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'load-check',
          'hypothesisId': 'B',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      return summaries;
    } catch (e) {
      // #region agent log
      try {
        final logData = {
          'location': 'summary_storage_service.dart:105',
          'message': 'Error loading summaries',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'load-check',
          'hypothesisId': 'B',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      print('❌ SummaryStorageService: Error loading summaries: $e');
      return [];
    }
  }
  
  /// Get summaries by date
  static Future<List<Map<String, dynamic>>> getSummariesByDate(DateTime date) async {
    try {
      final allSummaries = await getAllSummaries();
      final targetDate = DateTime(date.year, date.month, date.day);
      
      return allSummaries.where((summary) {
        final createdAt = DateTime.parse(summary['created_at'] as String);
        final summaryDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
        return summaryDate == targetDate;
      }).toList();
    } catch (e) {
      print('❌ SummaryStorageService: Error loading summaries by date: $e');
      return [];
    }
  }
  
  /// Convert stored summary to SummaryListItem
  static SummaryListItem toSummaryListItem(Map<String, dynamic> stored) {
    return SummaryListItem(
      summaryId: stored['summary_id'] as String? ?? '',
      patientName: stored['patient_name'] as String? ?? 'Unknown Patient',
      createdAt: stored['created_at'] != null
          ? DateTime.parse(stored['created_at'] as String)
          : DateTime.now(),
      summaryText: stored['summary_text'] as String? ?? '',
      animationAsset: stored['animation_asset'] as String?,
    );
  }
  
  /// Get summary by ID (returns full report data)
  static Future<Map<String, dynamic>?> getSummaryById(String summaryId) async {
    try {
      final allSummaries = await getAllSummaries();
      final summary = allSummaries.firstWhere(
        (s) => s['summary_id'] == summaryId,
        orElse: () => <String, dynamic>{},
      );
      
      if (summary.isEmpty) {
        return null;
      }
      
      // Return the stored report data
      return summary['report_data'] as Map<String, dynamic>?;
    } catch (e) {
      print('❌ SummaryStorageService: Error getting summary by ID: $e');
      return null;
    }
  }
  
  /// Clear all stored summaries
  static Future<void> clearAllSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('✅ SummaryStorageService: Cleared all summaries');
    } catch (e) {
      print('❌ SummaryStorageService: Error clearing summaries: $e');
    }
  }
  
  /// Convert ClinicalReportModel to JSON
  static Map<String, dynamic> _reportToJson(ClinicalReportModel report) {
    return {
      'request_id': report.requestId,
      'status': report.status,
      'timestamp': report.timestamp,
      'summary': report.summary != null ? {
        'chief_complaint': report.summary!.chiefComplaint,
        'symptoms': report.summary!.symptoms,
        'timeline': report.summary!.timeline,
        'clinical_findings': report.summary!.clinicalFindings,
        'summary_text': report.summary!.summaryText,
      } : null,
      'differential_diagnoses': report.differentialDiagnoses.map((d) => {
        'diagnosis': d.diagnosis,
        'priority': d.priority,
        'description': d.description,
        'status': d.status,
        'risk_level': d.riskLevel,
        'patient_justification': d.patientJustification,
        'supporting_evidence': d.supportingEvidence.map((e) => {
          'chunk_id': e.chunkId,
          'pmcid': e.pmcid,
          'text_snippet': e.textSnippet,
          'similarity_score': e.similarityScore,
          'citation': e.citation,
        }).toList(),
        'reasoning': d.reasoning,
        'confidence': {
          'overall_confidence': d.confidence.overallConfidence,
          'evidence_strength': d.confidence.evidenceStrength,
          'reasoning_consistency': d.confidence.reasoningConsistency,
          'citation_count': d.confidence.citationCount,
          'uncertainty': d.confidence.uncertainty,
          'lower_bound': d.confidence.lowerBound,
          'upper_bound': d.confidence.upperBound,
          'uncertainty_sources': d.confidence.uncertaintySources,
        },
        'recommended_tests': d.recommendedTests,
        'initial_management': d.initialManagement,
        'comparative_reasoning': d.comparativeReasoning,
      }).toList(),
      'total_evidence_retrieved': report.totalEvidenceRetrieved,
      'processing_time_seconds': report.processingTimeSeconds,
      'token_count': report.tokenCount,
      'warning_messages': report.warningMessages,
      'red_flags': report.redFlags.map((rf) => {
        'flag': rf.flag,
        'severity': rf.severity,
        'keywords': rf.keywords,
      }).toList(),
      'missing_information': report.missingInformation,
      'error_message': report.errorMessage,
      'original_text': report.originalText,
    };
  }
}
