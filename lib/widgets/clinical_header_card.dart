import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../models/clinical_report_model.dart';
import '../widgets/glass_container.dart';

/// Header card widget matching the design from the image
/// Shows GenAI Clinical Analysis with metadata and patient info
class ClinicalHeaderCard extends StatefulWidget {
  final ClinicalReportModel report;
  final String? patientName;
  final String? patientAge;
  final String? patientId;
  final String? mrn;

  const ClinicalHeaderCard({
    super.key,
    required this.report,
    this.patientName,
    this.patientAge,
    this.patientId,
    this.mrn,
  });

  @override
  State<ClinicalHeaderCard> createState() => _ClinicalHeaderCardState();
}

class _ClinicalHeaderCardState extends State<ClinicalHeaderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Left side: Icon, Title, Tags
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with light blue background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3E5FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                const Text(
                  'GenAI Clinical Analysis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 6),
                // Tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTag(
                      'Medora-v2.4 (RAG)',
                      Colors.grey[200]!,
                      AppTheme.mediumGray,
                    ),
                    if (widget.report.tokenCount != null)
                      _buildTag(
                        '${widget.report.tokenCount} tokens',
                        const Color(0xFFFFB6C1).withOpacity(0.3),
                        const Color(0xFF8B4A6B),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            width: 1,
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.3),
          ),
          // Right side: Patient Info Columns
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // PATIENT column
                Expanded(
                  child: _buildInfoColumn(
                    label: 'PATIENT',
                    child: Text(
                      _formatPatientInfo(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withOpacity(0.3),
                ),
                // MRN column
                Expanded(
                  child: _buildInfoColumn(
                    label: 'MRN',
                    child: Text(
                      widget.mrn ?? widget.patientId ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withOpacity(0.3),
                ),
                // COMPLAINT column
                Expanded(
                  child: _buildInfoColumn(
                    label: 'COMPLAINT',
                    child: Text(
                      _formatComplaint(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _formatComplaint() {
    final complaint = widget.report.summary?.chiefComplaint ?? 'Not specified';
    final timeline = widget.report.summary?.timeline;
    
    if (timeline != null && timeline.isNotEmpty) {
      // Extract duration from timeline if available
      final durationMatch = RegExp(r'(\d+)\s*(h|hour|hr|hours|d|day|days|m|min|minutes)').firstMatch(timeline.toLowerCase());
      if (durationMatch != null) {
        final duration = durationMatch.group(1);
        final unit = durationMatch.group(2);
        String durationStr = '$duration$unit';
        if (unit == 'h' || unit == 'hour' || unit == 'hr' || unit == 'hours') {
          durationStr = '${duration}h';
        } else if (unit == 'd' || unit == 'day' || unit == 'days') {
          durationStr = '${duration}d';
        } else if (unit == 'm' || unit == 'min' || unit == 'minutes') {
          durationStr = '${duration}m';
        }
        return '$complaint - $durationStr duration';
      }
      return complaint;
    }
    return complaint;
  }

  Widget _buildTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTagWithIcon(
    String text,
    Color backgroundColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  String _formatPatientInfo() {
    if (widget.patientName != null && widget.patientAge != null) {
      return '${widget.patientAge} ${widget.patientName}';
    } else if (widget.patientName != null) {
      return widget.patientName!;
    } else if (widget.patientAge != null) {
      return widget.patientAge!;
    } else {
      return 'Unknown Patient';
    }
  }

}
