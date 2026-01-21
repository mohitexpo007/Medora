import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clinical_report_model.dart';
import '../services/api_service.dart';
import '../widgets/summary_section_card.dart';
import '../widgets/diagnosis_expandable_card.dart';
import '../widgets/loading_shimmer.dart';

/// Clinical Summary Screen - Displays AI-generated clinical report
class ClinicalSummaryScreen extends StatefulWidget {
  final String noteText;
  final String? patientId;

  const ClinicalSummaryScreen({
    super.key,
    required this.noteText,
    this.patientId,
  });

  @override
  State<ClinicalSummaryScreen> createState() => _ClinicalSummaryScreenState();
}

class _ClinicalSummaryScreenState extends State<ClinicalSummaryScreen>
    with SingleTickerProviderStateMixin {
  ClinicalReportModel? _report;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRetrying = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _fetchSummary();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await ApiService.analyzeClinicalNote(
        noteText: widget.noteText,
        patientId: widget.patientId,
      );

      setState(() {
        _report = report;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
    });
    await _fetchSummary();
    setState(() {
      _isRetrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Clinical Summary'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ClinicalSummaryLoadingShimmer();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_report == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return _buildSuccessState();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isRetrying ? null : _retry,
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final report = _report!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(report),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Patient Presentation
                if (report.summary != null) ...[
                  _buildPatientPresentation(report.summary!),
                  const SizedBox(height: 20),
                ],

                // Conditions Under Consideration
                if (report.differentialDiagnoses.isNotEmpty) ...[
                  _buildConditionsSection(report.differentialDiagnoses),
                  const SizedBox(height: 20),
                ],

                // Immediate Actions (from red flags)
                if (report.redFlags.isNotEmpty) ...[
                  _buildImmediateActions(report.redFlags),
                  const SizedBox(height: 20),
                ],

                // Additional Data Needed
                if (report.missingInformation.isNotEmpty) ...[
                  _buildAdditionalDataNeeded(report.missingInformation),
                  const SizedBox(height: 20),
                ],

                // System Disclosure
                _buildSystemDisclosure(report),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ClinicalReportModel report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.blueViolet, AppTheme.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Clinical AI Analysis',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (report.status == 'completed')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.patientId != null) ...[
            _buildHeaderItem(
              Icons.person,
              'Patient ID',
              widget.patientId!,
            ),
            const SizedBox(height: 8),
          ],
          if (report.requestId.isNotEmpty) ...[
            _buildHeaderItem(
              Icons.tag,
              'Request ID',
              report.requestId,
            ),
            const SizedBox(height: 8),
          ],
          if (report.processingTimeSeconds != null)
            _buildHeaderItem(
              Icons.timer_outlined,
              'Processing Time',
              '${report.processingTimeSeconds!.toStringAsFixed(1)}s',
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientPresentation(ClinicalSummary summary) {
    return SummarySectionCard(
      title: 'Patient Presentation',
      icon: Icons.person_outline,
      iconColor: AppTheme.blueViolet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinical Presentation
          if (summary.summaryText.isNotEmpty) ...[
            _buildSubsectionTitle('Clinical Presentation'),
            const SizedBox(height: 8),
            Text(
              summary.summaryText,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timeline
          if (summary.timeline != null && summary.timeline!.isNotEmpty) ...[
            _buildSubsectionTitle('Timeline'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.timeline!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Key Features (Symptoms)
          if (summary.symptoms.isNotEmpty) ...[
            _buildSubsectionTitle('Key Features'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.symptoms.map((symptom) {
                return Chip(
                  label: Text(symptom),
                  backgroundColor: AppTheme.lightLavender,
                  avatar: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.blueViolet,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Clinical Findings
          if (summary.clinicalFindings != null &&
              summary.clinicalFindings!.isNotEmpty) ...[
            _buildSubsectionTitle('Clinical Findings'),
            const SizedBox(height: 8),
            Text(
              summary.clinicalFindings!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionsSection(List<DifferentialDiagnosis> diagnoses) {
    return SummarySectionCard(
      title: 'Conditions Under Consideration',
      icon: Icons.medical_services,
      iconColor: AppTheme.violet,
      child: Column(
        children: diagnoses
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final diagnosis = entry.value;
              return DiagnosisExpandableCard(
                diagnosis: diagnosis,
                index: index,
              );
            })
            .toList(),
      ),
    );
  }

  Widget _buildImmediateActions(List<String> redFlags) {
    return SummarySectionCard(
      title: 'Immediate Actions',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red,
      child: Column(
        children: redFlags.map((flag) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red[200]!,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.priority_high,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    flag,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdditionalDataNeeded(List<String> missingInfo) {
    return SummarySectionCard(
      title: 'Additional Data Needed',
      icon: Icons.info_outline,
      iconColor: Colors.orange,
      child: Column(
        children: missingInfo.map((info) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemDisclosure(ClinicalReportModel report) {
    return SummarySectionCard(
      title: 'System Information',
      icon: Icons.info,
      iconColor: AppTheme.mediumGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.totalEvidenceRetrieved > 0) ...[
            _buildInfoRow(
              'Evidence Sources',
              '${report.totalEvidenceRetrieved} chunks retrieved',
            ),
            const SizedBox(height: 12),
          ],
          if (report.warningMessages.isNotEmpty) ...[
            _buildInfoRow(
              'Warnings',
              report.warningMessages.join(', '),
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            'Status',
            report.status,
          ),
          const SizedBox(height: 16),
          const Text(
            'This analysis is generated by AI and should be reviewed by a qualified healthcare professional.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGray,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkGray,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mediumGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
