/// Complete model for Clinical Report API response
/// Supports null-safe parsing with fallback defaults

class ClinicalReportModel {
  final String requestId;
  final String status;
  final String? timestamp;
  final ClinicalSummary? summary;
  final List<DifferentialDiagnosis> differentialDiagnoses;
  final int totalEvidenceRetrieved;
  final double? processingTimeSeconds;
  final int? tokenCount;
  final List<String> warningMessages;
  final List<RedFlag> redFlags;
  final List<String> missingInformation;
  final String? errorMessage;
  final String? originalText;

  ClinicalReportModel({
    required this.requestId,
    required this.status,
    this.timestamp,
    this.summary,
    required this.differentialDiagnoses,
    this.totalEvidenceRetrieved = 0,
    this.processingTimeSeconds,
    this.tokenCount,
    required this.warningMessages,
    required this.redFlags,
    required this.missingInformation,
    this.errorMessage,
    this.originalText,
  });

  factory ClinicalReportModel.fromJson(Map<String, dynamic> json) {
    return ClinicalReportModel(
      requestId: json['request_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      timestamp: json['timestamp'] as String?,
      summary: json['summary'] != null
          ? ClinicalSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      differentialDiagnoses: (json['differential_diagnoses'] as List<dynamic>?)
              ?.map((e) => DifferentialDiagnosis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalEvidenceRetrieved: json['total_evidence_retrieved'] as int? ?? 0,
      processingTimeSeconds: (json['processing_time_seconds'] as num?)?.toDouble(),
      tokenCount: json['token_count'] as int? ?? json['total_tokens'] as int?,
      warningMessages: (json['warning_messages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      redFlags: () {
        final redFlagsList = json['red_flags'] as List<dynamic>?;
        print('🔴 DEBUG: red_flags from JSON: $redFlagsList');
        print('🔴 DEBUG: red_flags type: ${redFlagsList.runtimeType}');
        print('🔴 DEBUG: red_flags length: ${redFlagsList?.length ?? 0}');
        
        if (redFlagsList == null || redFlagsList.isEmpty) {
          print('🔴 DEBUG: No red flags found in response');
          return <RedFlag>[];
        }
        
        final parsed = redFlagsList.map((e) {
          print('🔴 DEBUG: Parsing red flag item: $e (type: ${e.runtimeType})');
          // Support both string format (backward compatibility) and structured format
          if (e is String) {
            print('🔴 DEBUG: Red flag is String, creating RedFlag with flag=$e');
            return RedFlag(flag: e, severity: 'warning', keywords: []);
          } else if (e is Map<String, dynamic>) {
            print('🔴 DEBUG: Red flag is Map, parsing with fromJson');
            return RedFlag.fromJson(e);
          }
          print('🔴 DEBUG: Red flag is unknown type, converting to string');
          return RedFlag(flag: e.toString(), severity: 'warning', keywords: []);
        }).toList();
        
        print('🔴 DEBUG: Parsed ${parsed.length} red flags');
        return parsed;
      }(),
      missingInformation: (json['missing_information'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      errorMessage: json['error_message'] as String?,
      originalText: json['original_text'] as String?,
    );
  }
}

class ClinicalSummary {
  final String? chiefComplaint;
  final List<String> symptoms;
  final String? timeline;
  final String? clinicalFindings;
  final String summaryText;

  ClinicalSummary({
    this.chiefComplaint,
    required this.symptoms,
    this.timeline,
    this.clinicalFindings,
    required this.summaryText,
  });

  factory ClinicalSummary.fromJson(Map<String, dynamic> json) {
    return ClinicalSummary(
      chiefComplaint: json['chief_complaint'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timeline: json['timeline'] as String?,
      clinicalFindings: json['clinical_findings'] as String?,
      summaryText: json['summary_text'] as String? ?? '',
    );
  }
}

class DifferentialDiagnosis {
  final String diagnosis;
  final int priority;
  final String description;
  final String status;
  final String riskLevel;
  final List<String> patientJustification;
  final List<EvidenceCitation> supportingEvidence;
  final String reasoning;
  final ConfidenceScore confidence;
  final List<String> recommendedTests;
  final List<String> initialManagement;
  final String comparativeReasoning;

  DifferentialDiagnosis({
    required this.diagnosis,
    required this.priority,
    required this.description,
    required this.status,
    required this.riskLevel,
    required this.patientJustification,
    required this.supportingEvidence,
    required this.reasoning,
    required this.confidence,
    required this.recommendedTests,
    required this.initialManagement,
    required this.comparativeReasoning,
  });

  factory DifferentialDiagnosis.fromJson(Map<String, dynamic> json) {
    return DifferentialDiagnosis(
      diagnosis: json['diagnosis'] as String? ?? 'Unknown Diagnosis',
      priority: json['priority'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'clinically-plausible',
      riskLevel: json['risk_level'] as String? ?? 'Blue/Low',
      patientJustification: (json['patient_justification'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      supportingEvidence: (json['supporting_evidence'] as List<dynamic>?)
              ?.map((e) => EvidenceCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reasoning: json['reasoning'] as String? ?? '',
      confidence: json['confidence'] != null
          ? ConfidenceScore.fromJson(json['confidence'] as Map<String, dynamic>)
          : ConfidenceScore.empty(),
      recommendedTests: (json['recommended_tests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      initialManagement: (json['initial_management'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      comparativeReasoning: json['comparative_reasoning'] as String? ?? '',
    );
  }
}

class EvidenceCitation {
  final String chunkId;
  final String pmcid;
  final String textSnippet;
  final double? similarityScore;
  final String? citation;

  EvidenceCitation({
    required this.chunkId,
    required this.pmcid,
    required this.textSnippet,
    this.similarityScore,
    this.citation,
  });

  factory EvidenceCitation.fromJson(Map<String, dynamic> json) {
    return EvidenceCitation(
      chunkId: json['chunk_id'] as String? ?? '',
      pmcid: json['pmcid'] as String? ?? '',
      textSnippet: json['text_snippet'] as String? ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      citation: json['citation'] as String?,
    );
  }
}

class ConfidenceScore {
  final double overallConfidence;
  final double evidenceStrength;
  final double reasoningConsistency;
  final int citationCount;
  final double? uncertainty;
  final double? lowerBound;
  final double? upperBound;
  final List<String> uncertaintySources;

  ConfidenceScore({
    required this.overallConfidence,
    required this.evidenceStrength,
    required this.reasoningConsistency,
    required this.citationCount,
    this.uncertainty,
    this.lowerBound,
    this.upperBound,
    required this.uncertaintySources,
  });

  factory ConfidenceScore.fromJson(Map<String, dynamic> json) {
    return ConfidenceScore(
      overallConfidence: (json['overall_confidence'] as num?)?.toDouble() ?? 0.0,
      evidenceStrength: (json['evidence_strength'] as num?)?.toDouble() ?? 0.0,
      reasoningConsistency: (json['reasoning_consistency'] as num?)?.toDouble() ?? 0.0,
      citationCount: json['citation_count'] as int? ?? 0,
      uncertainty: (json['uncertainty'] as num?)?.toDouble(),
      lowerBound: (json['lower_bound'] as num?)?.toDouble(),
      upperBound: (json['upper_bound'] as num?)?.toDouble(),
      uncertaintySources: (json['uncertainty_sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory ConfidenceScore.empty() {
    return ConfidenceScore(
      overallConfidence: 0.0,
      evidenceStrength: 0.0,
      reasoningConsistency: 0.0,
      citationCount: 0,
      uncertaintySources: [],
    );
  }

  int get confidencePercent => (overallConfidence * 100).round();
}

class RedFlag {
  final String flag;
  final String severity; // "critical" or "warning"
  final List<String> keywords;

  RedFlag({
    required this.flag,
    required this.severity,
    required this.keywords,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      flag: json['flag'] as String? ?? '',
      severity: json['severity'] as String? ?? 'warning',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
