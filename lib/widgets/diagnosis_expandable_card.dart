import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clinical_report_model.dart';

/// Expandable card for differential diagnosis
class DiagnosisExpandableCard extends StatefulWidget {
  final DifferentialDiagnosis diagnosis;
  final int index;

  const DiagnosisExpandableCard({
    super.key,
    required this.diagnosis,
    required this.index,
  });

  @override
  State<DiagnosisExpandableCard> createState() =>
      _DiagnosisExpandableCardState();
}

class _DiagnosisExpandableCardState extends State<DiagnosisExpandableCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Color _getRiskColor(String riskLevel) {
    if (riskLevel.toLowerCase().contains('red') ||
        riskLevel.toLowerCase().contains('danger')) {
      return Colors.red;
    } else if (riskLevel.toLowerCase().contains('orange') ||
        riskLevel.toLowerCase().contains('warning')) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(widget.diagnosis.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Priority badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.blueViolet, AppTheme.violet],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '#${widget.diagnosis.priority}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Diagnosis name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.diagnosis.diagnosis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Confidence badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.softBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.diagnosis.confidence.confidencePercent}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.blueViolet,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Risk level badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: riskColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.diagnosis.riskLevel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: riskColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  RotationTransition(
                    turns: _expandAnimation,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Description
                  if (widget.diagnosis.description.isNotEmpty) ...[
                    _buildSectionTitle('Description'),
                    const SizedBox(height: 8),
                    Text(
                      widget.diagnosis.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Reasoning
                  if (widget.diagnosis.reasoning.isNotEmpty) ...[
                    _buildSectionTitle('Clinical Reasoning'),
                    const SizedBox(height: 8),
                    Text(
                      widget.diagnosis.reasoning,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkGray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Patient Justification
                  if (widget.diagnosis.patientJustification.isNotEmpty) ...[
                    _buildSectionTitle('Supporting Symptoms'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.diagnosis.patientJustification
                          .map((symptom) => Chip(
                                label: Text(symptom),
                                backgroundColor: AppTheme.lightLavender,
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkGray,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Confidence details
                  _buildSectionTitle('Confidence Metrics'),
                  const SizedBox(height: 8),
                  _buildConfidenceMetrics(widget.diagnosis.confidence),
                  const SizedBox(height: 16),
                  
                  // Recommended Tests
                  if (widget.diagnosis.recommendedTests.isNotEmpty) ...[
                    _buildSectionTitle('Recommended Tests'),
                    const SizedBox(height: 8),
                    ...widget.diagnosis.recommendedTests.map((test) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppTheme.blueViolet,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  test,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Initial Management
                  if (widget.diagnosis.initialManagement.isNotEmpty) ...[
                    _buildSectionTitle('Initial Management'),
                    const SizedBox(height: 8),
                    ...widget.diagnosis.initialManagement.map((action) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.medical_services_outlined,
                                size: 16,
                                color: AppTheme.violet,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  action,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Evidence
                  if (widget.diagnosis.supportingEvidence.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Supporting Evidence (${widget.diagnosis.supportingEvidence.length})',
                    ),
                    const SizedBox(height: 8),
                    ...widget.diagnosis.supportingEvidence
                        .take(3)
                        .map((evidence) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.softBlue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evidence.citation ?? evidence.pmcid,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.blueViolet,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    evidence.textSnippet,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.mediumGray,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkGray,
      ),
    );
  }

  Widget _buildConfidenceMetrics(ConfidenceScore confidence) {
    return Column(
      children: [
        _buildMetricRow(
          'Overall Confidence',
          '${confidence.confidencePercent}%',
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Evidence Strength',
          '${(confidence.evidenceStrength * 100).round()}%',
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Reasoning Consistency',
          '${(confidence.reasoningConsistency * 100).round()}%',
        ),
        if (confidence.uncertainty != null) ...[
          const SizedBox(height: 8),
          _buildMetricRow(
            'Uncertainty',
            '${(confidence.uncertainty! * 100).round()}%',
          ),
        ],
        if (confidence.citationCount > 0) ...[
          const SizedBox(height: 8),
          _buildMetricRow(
            'Citations',
            '${confidence.citationCount}',
          ),
        ],
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.mediumGray,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGray,
          ),
        ),
      ],
    );
  }
}
