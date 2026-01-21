import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../utils/animation_selector.dart';
import '../widgets/clinical_animation_player.dart';

class ClinicalSummaryDetailScreen extends StatefulWidget {
  final String patientName;
  final DateTime date;
  final String diagnosis;
  final IconData affectedOrgan;
  final String summaryText;
  final List<String> diagnosisList;
  final String? animationAsset; // Optional animation asset from API

  const ClinicalSummaryDetailScreen({
    super.key,
    required this.patientName,
    required this.date,
    required this.diagnosis,
    required this.affectedOrgan,
    required this.summaryText,
    required this.diagnosisList,
    this.animationAsset, // Optional - if not provided, will be calculated
  });

  @override
  State<ClinicalSummaryDetailScreen> createState() =>
      _ClinicalSummaryDetailScreenState();
}

class _ClinicalSummaryDetailScreenState
    extends State<ClinicalSummaryDetailScreen> with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _cardController;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  final Map<int, bool> _expandedDiagnoses = {};

  // Get summary points from summary text (split by sentences)
  List<String> get summaryPoints {
    // Split by periods and filter out empty strings
    return widget.summaryText
        .split('.')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Convert diagnosis list to DiagnosisItem objects
  List<DiagnosisItem> get diagnoses {
    if (widget.diagnosisList.isEmpty) {
      return [
        DiagnosisItem(
          name: 'General Consultation',
          priority: 1,
          organ: Icons.help_outline,
          reasoning: [
            'No specific diagnosis identified',
            'Further evaluation recommended',
            'Monitor for symptom progression',
          ],
        ),
      ];
    }

    return widget.diagnosisList.asMap().entries.map((entry) {
      final index = entry.key;
      final diagnosisName = entry.value;
      
      // Get icon for this diagnosis
      final animationAsset = AnimationSelector.selectAnimationAsset(
        widget.summaryText,
        [diagnosisName],
      );
      final icon = AnimationSelector.getIconForAnimation(animationAsset);
      
      // Generate reasoning points based on the summary text and diagnosis
      final reasoning = _generateReasoning(diagnosisName, widget.summaryText);
      
      return DiagnosisItem(
        name: diagnosisName,
        priority: index + 1,
        organ: icon,
        reasoning: reasoning,
      );
    }).toList();
  }

  // Generate reasoning points from diagnosis and summary
  List<String> _generateReasoning(String diagnosis, String summary) {
    final lowerSummary = summary.toLowerCase();
    final lowerDiagnosis = diagnosis.toLowerCase();
    
    // Try to extract relevant points from the summary
    final sentences = summary.split('.').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    // Filter sentences that mention the diagnosis or related terms
    final relevantSentences = sentences.where((s) {
      final lowerS = s.toLowerCase();
      // Check if sentence mentions diagnosis keywords
      return lowerS.contains(lowerDiagnosis.split(' ').first) || 
             lowerS.contains(lowerDiagnosis.split(' ').last) ||
             _isRelatedToDiagnosis(lowerS, lowerDiagnosis);
    }).toList();
    
    if (relevantSentences.isNotEmpty) {
      // Use actual sentences from summary, limited to 3-4 points
      return relevantSentences.take(4).map((s) => s.trim()).toList();
    }
    
    // Fallback: generic reasoning
    return [
      'Clinical findings consistent with $diagnosis',
      'Symptoms align with diagnostic criteria',
      'Further investigation may be warranted',
    ];
  }

  bool _isRelatedToDiagnosis(String sentence, String diagnosis) {
    // Simple keyword matching for common medical terms
    final keywords = {
      'diabetes': ['hba1c', 'glycemic', 'glucose', 'insulin'],
      'hypertension': ['blood pressure', 'elevated', 'cardiac'],
      'stroke': ['weakness', 'speech', 'facial', 'sudden'],
      'copd': ['cough', 'breathlessness', 'respiratory', 'pulmonary'],
      'kidney': ['creatinine', 'renal', 'urine', 'kidney'],
      'gastritis': ['abdominal', 'nausea', 'gastric', 'stomach'],
      'ibs': ['abdominal', 'bowel', 'intestinal', 'cramps'],
      'vascular': ['blood flow', 'peripheral', 'vascular', 'pain'],
    };
    
    for (final entry in keywords.entries) {
      if (diagnosis.toLowerCase().contains(entry.key)) {
        return entry.value.any((keyword) => sentence.contains(keyword));
      }
    }
    
    return false;
  }

  // Extract key findings from summary (simplified - in production this would parse actual lab values)
  List<String> get keyFindings {
    final findings = <String>[];
    final lowerSummary = widget.summaryText.toLowerCase();
    
    // Look for common lab values and findings
    if (lowerSummary.contains('hba1c')) {
      findings.add('Elevated HbA1c levels detected');
    }
    if (lowerSummary.contains('blood pressure') || lowerSummary.contains('hypertension')) {
      findings.add('Elevated blood pressure readings');
    }
    if (lowerSummary.contains('creatinine')) {
      findings.add('Elevated serum creatinine');
    }
    if (lowerSummary.contains('oxygen saturation') || lowerSummary.contains('oxygen')) {
      findings.add('Reduced oxygen saturation');
    }
    if (lowerSummary.contains('fatigue')) {
      findings.add('Persistent fatigue reported');
    }
    
    // If no specific findings, add generic ones
    if (findings.isEmpty) {
      findings.add('Clinical symptoms present');
      findings.add('Requires clinical review');
    }
    
    return findings;
  }

  @override
  void initState() {
    super.initState();

    // Page load animation
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );

    // Card staggered animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pageController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightLavender,
              AppTheme.softBlue,
              AppTheme.lightPink,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _pageFade,
            child: SlideTransition(
              position: _pageSlide,
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Top Animation Section
                          _buildAnimationSection(),
                          const SizedBox(height: 24),
                          // Case Information
                          _buildCaseInfo(),
                          const SizedBox(height: 24),
                          // Summary Section
                          _buildSummarySection(),
                          const SizedBox(height: 20),
                          // Diagnosis Section
                          _buildDiagnosisSection(),
                          const SizedBox(height: 20),
                          // Key Findings Section
                          _buildKeyFindingsSection(),
                          const SizedBox(height: 24),
                          // Action Buttons
                          _buildActionButtons(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Clinical Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAnimationSection() {
    // Use animation asset from API if provided, otherwise calculate it
    final selectedAnimation = widget.animationAsset ??
        AnimationSelector.selectAnimationAsset(
          widget.summaryText,
          widget.diagnosisList,
        );

    print('🎬 ClinicalSummaryDetailScreen: Using animation: $selectedAnimation');
    print('🎬 ClinicalSummaryDetailScreen: API provided: ${widget.animationAsset ?? "none"}');
    print('🎬 ClinicalSummaryDetailScreen: Calculated: ${widget.animationAsset == null ? selectedAnimation : "N/A"}');

    return ClinicalAnimationPlayer(
      animationAsset: selectedAnimation,
      height: MediaQuery.of(context).size.height * 0.35,
    );
  }

  Widget _buildCaseInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.patientName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(widget.date),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.blueViolet.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: AppTheme.blueViolet,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI-Generated Summary (Reviewed)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.blueViolet,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return _buildGlassCard(
      title: 'Clinical Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: summaryPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: index < summaryPoints.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.blueViolet,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkGray,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiagnosisSection() {
    return _buildGlassCard(
      title: 'Likely Diagnoses',
      child: Column(
        children: diagnoses.asMap().entries.map((entry) {
          final index = entry.key;
          final diagnosis = entry.value;
          return _buildDiagnosisCard(diagnosis, index);
        }).toList(),
      ),
    );
  }

  Widget _buildDiagnosisCard(DiagnosisItem diagnosis, int index) {
    final isExpanded = _expandedDiagnoses[index] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: index < diagnoses.length - 1 ? 12 : 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedDiagnoses[index] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Priority badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6B9D),
                            Color(0xFF9C88FF),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${diagnosis.priority}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Organ icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getOrganColor(diagnosis.organ)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        diagnosis.organ,
                        color: _getOrganColor(diagnosis.organ),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Diagnosis name
                    Expanded(
                      child: Text(
                        diagnosis.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                    // Expand icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.white54),
                    const SizedBox(height: 12),
                    const Text(
                      'Clinical Reasoning:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...diagnosis.reasoning.map((point) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.blueViolet,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.darkGray,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyFindingsSection() {
    return _buildGlassCard(
      title: 'Key Clinical Findings',
      child: Column(
        children: keyFindings.asMap().entries.map((entry) {
          final index = entry.key;
          final finding = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(
                bottom: index < keyFindings.length - 1 ? 12 : 0,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: const Color(0xFFFF6B9D),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      finding,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.description,
            label: 'Raw Notes',
            onTap: () {
              // TODO: Navigate to raw notes
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.picture_as_pdf,
            label: 'Export PDF',
            onTap: () {
              // TODO: Export to PDF
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.feedback,
            label: 'Feedback',
            onTap: () {
              // TODO: Show feedback dialog
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.blueViolet, AppTheme.violet],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.blueViolet.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Color _getOrganColor(IconData icon) {
    if (icon == Icons.favorite) return Colors.red;
    if (icon == Icons.psychology) return AppTheme.blueViolet;
    if (icon == Icons.air) return Colors.blue;
    return AppTheme.blueViolet;
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
  }
}

class DiagnosisItem {
  final String name;
  final int priority;
  final IconData organ;
  final List<String> reasoning;

  DiagnosisItem({
    required this.name,
    required this.priority,
    required this.organ,
    required this.reasoning,
  });
}
