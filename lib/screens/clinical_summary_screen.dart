import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clinical_report_model.dart';
import '../services/api_service.dart';
import '../services/summary_storage_service.dart';
import '../widgets/summary_section_card.dart';
import '../widgets/diagnosis_expandable_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/medora_loader.dart';
import '../widgets/animated_tab_row.dart';
import '../widgets/expandable_tab_bar.dart';
import '../widgets/clinical_header_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/clinical_animation_player.dart';
import '../utils/animation_selector.dart';
import '../services/gemini_video_selector.dart';
import 'home_screen.dart';

/// Clinical Summary Screen - Displays AI-generated clinical report
class ClinicalSummaryScreen extends StatefulWidget {
  /// Text input (paste/type). Use when generating from note.
  final String? noteText;
  /// Pre-fetched report from upload. Use when generating from PDF/image.
  final Map<String, dynamic>? initialReport;
  final String? patientId;
  final String? patientName;
  final String? patientAge;
  final String? mrn;

  const ClinicalSummaryScreen({
    super.key,
    this.noteText,
    this.initialReport,
    this.patientId,
    this.patientName,
    this.patientAge,
    this.mrn,
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
  int _selectedTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showOriginalText = false;
  List<String> _consoleLogs = [];

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
    if (widget.initialReport != null) {
      try {
        _report = ClinicalReportModel.fromJson(widget.initialReport!);
        
        // Save summary to local storage (fire and forget)
        SummaryStorageService.saveSummary(
          report: _report!,
          patientName: widget.patientName ?? 'Unknown Patient',
          patientId: widget.patientId,
        ).catchError((e) {
          print('❌ Error saving initial report: $e');
        });
      } catch (_) {
        _errorMessage = 'Invalid report data';
      }
      _isLoading = false;
      _animationController.forward();
    } else if (widget.noteText != null && widget.noteText!.trim().isNotEmpty) {
      _fetchSummary();
    } else {
      _isLoading = false;
      _errorMessage = 'No input provided';
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    final text = widget.noteText?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _consoleLogs = ['> Initializing clinical pipeline...'];
    });

    // Simulate processing stages with real log messages
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _consoleLogs = [
            '> Initializing clinical pipeline...',
            '> Extracting clinical entities from note...',
          ];
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _consoleLogs = [
            '> Initializing clinical pipeline...',
            '> Extracting clinical entities from note...',
            '> Analyzing symptom patterns and vitals...',
          ];
        });
      }
    });

    try {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _consoleLogs = [
              '> Extracting clinical entities from note...',
              '> Analyzing symptom patterns and vitals...',
              '> Generating differential diagnosis with RAG...',
            ];
          });
        }
      });

      final report = await ApiService.analyzeClinicalNote(
        noteText: text,
        patientId: widget.patientId,
      );

      if (!mounted) return;
      
      // Debug: Log red flags
      print('🔴 DEBUG: ========== RED FLAGS DEBUG ==========');
      print('🔴 DEBUG: Report received, red flags count: ${report.redFlags.length}');
      print('🔴 DEBUG: Report red flags list: ${report.redFlags}');
      if (report.redFlags.isNotEmpty) {
        print('🔴 DEBUG: First red flag: ${report.redFlags[0].flag}');
        print('🔴 DEBUG: First red flag severity: ${report.redFlags[0].severity}');
        print('🔴 DEBUG: First red flag keywords: ${report.redFlags[0].keywords}');
      } else {
        print('🔴 DEBUG: WARNING - No red flags in report!');
      }
      print('🔴 DEBUG: =====================================');
      
      if (mounted) {
        setState(() {
          _consoleLogs = [
            '> Analyzing symptom patterns and vitals...',
            '> Generating differential diagnosis with RAG...',
            '> ✅ Analysis complete. Generating summary...',
          ];
        });
      }

      setState(() {
        _report = report;
        _isLoading = false;
      });
      
      // Save summary to local storage
      await SummaryStorageService.saveSummary(
        report: report,
        patientName: widget.patientName ?? 'Unknown Patient',
        patientId: widget.patientId,
      );
      
      _animationController.forward();
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _retry() async {
    if (widget.noteText == null || widget.noteText!.trim().isEmpty) return;
    setState(() {
      _isRetrying = true;
    });
    await _fetchSummary();
    if (!mounted) return;
    setState(() {
      _isRetrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: null, // Removed bottom navigation
    );
  }
  
  Widget _buildFloatingActionButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _showOriginalText ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: 0.7 + (value * 0.3),
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showOriginalText = !_showOriginalText;
                });
                if (_showOriginalText) {
                  _showOriginalTextDialog();
                }
              },
              backgroundColor: AppTheme.violet.withOpacity(0.9),
              icon: Icon(
                _showOriginalText ? Icons.close : Icons.description,
                color: Colors.white,
              ),
              label: Text(
                _showOriginalText ? 'Close' : 'Original Text',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showOriginalTextDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.9),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.violet,
                        AppTheme.violet.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Original Extracted Text',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _showOriginalText = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _report?.originalText ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkGray,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() {
        _showOriginalText = false;
      });
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: MedoraLoader(
          statusMessage: 'Extracting clinical entities',
          subStatusMessage: 'Checking interactions • Assessing risk scores',
          consoleLogs: _consoleLogs,
        ),
      );
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
      child: Column(
        children: [
          // Header
          _buildDarkHeader(report),
          
          // Tabs
          _buildDarkTabs(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTabContent(report),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDarkHeader(ClinicalReportModel report) {
    // Extract patient name from widget or use "--"
    String patientName = widget.patientName ?? '--';
    
    // Format time taken from backend
    String timeTaken = '--';
    if (report.processingTimeSeconds != null) {
      final seconds = report.processingTimeSeconds!;
      if (seconds < 60) {
        timeTaken = '${seconds.toStringAsFixed(1)}s';
      } else {
        final minutes = (seconds / 60).floor();
        final remainingSeconds = (seconds % 60).floor();
        timeTaken = '${minutes}m ${remainingSeconds}s';
      }
    }
    
    final complaint = report.summary?.timeline ?? report.summary?.chiefComplaint ?? '--';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button and Logo/Title Row
          Row(
            children: [
              // Back Button - Top Left
              Material(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false, // Remove all previous routes
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'GenAI Clinical Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Medora tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Medora-v2.4 (RAG)',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF00D4FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Patient Info Columns - Full width with Expanded
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PATIENT',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIME TAKEN',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeTaken,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPLAINT',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDarkTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ExpandableTabBar(
        tabs: const [
          ExpandableTabItem(
            label: 'Summary',
            icon: Icons.description,
          ),
          ExpandableTabItem(
            label: 'Differential Dx',
            icon: Icons.medical_services,
          ),
          ExpandableTabItem(
            label: 'Symptom Analysis',
            icon: Icons.analytics,
          ),
          ExpandableTabItem(
            label: 'RAG Evidence',
            icon: Icons.search,
          ),
        ],
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }
  
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.folder, 'Patients', false),
              _buildNavItem(Icons.chat_bubble_outline, 'AI Chat', false),
              _buildNavItem(Icons.settings, 'Settings', false),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF00D4FF) : Colors.white54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? const Color(0xFF00D4FF) : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ClinicalReportModel report) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildClinicalSummaryTab(report);
      case 1:
        return _buildDifferentialDiagnosisTab(report);
      case 2:
        return _buildSymptomAnalysisTab(report);
      case 3:
        return _buildRAGEvidenceTab(report);
      default:
        return _buildClinicalSummaryTab(report);
    }
  }

  Widget _buildHeader(ClinicalReportModel report) {
    // Use provided patient info, or try to extract from patientId
    String? patientName = widget.patientName;
    String? patientAge = widget.patientAge;
    
    // If not provided, try to parse from patientId
    if (patientName == null && patientAge == null && widget.patientId != null) {
      final patientIdStr = widget.patientId!;
      // Try to parse common formats
      if (patientIdStr.contains('yo')) {
        // Format like "58yo Male" or "John Doe, 58yo"
        final parts = patientIdStr.split(',');
        if (parts.length > 1) {
          patientName = parts[0].trim();
          final ageMatch = RegExp(r'(\d+)yo').firstMatch(parts[1]);
          if (ageMatch != null) {
            patientAge = '${ageMatch.group(1)}yo';
          }
        } else {
          final ageMatch = RegExp(r'(\d+)yo\s*(\w+)').firstMatch(patientIdStr);
          if (ageMatch != null) {
            patientAge = '${ageMatch.group(1)}yo';
            patientName = ageMatch.group(2);
          }
        }
      }
    }

    return ClinicalHeaderCard(
      report: report,
      patientName: patientName,
      patientAge: patientAge,
      patientId: widget.patientId,
      mrn: widget.mrn ?? widget.patientId,
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

  // Tab Content Builders
  Widget _buildClinicalSummaryTab(ClinicalReportModel report) {
    return _buildAIGeneratedSummaryCard(report);
  }

  Widget _buildAIGeneratedSummaryCard(ClinicalReportModel report) {
    final summaryText = report.summary?.summaryText ?? '';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with sparkle icons
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF00D4FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Generated Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF00D4FF),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (summaryText.isNotEmpty) ...[
            // Clinical Presentation
            _buildDarkSubsection(
              'Clinical Presentation',
              summaryText,
            ),
            const SizedBox(height: 20),
            
            // Key Features
            if (report.summary?.symptoms.isNotEmpty ?? false) ...[
              _buildDarkSubsection(
                'Key Features',
                report.summary!.symptoms.map((s) => '• $s').join('\n'),
              ),
              const SizedBox(height: 20),
            ],
            
            // Assessment
            if (report.summary?.clinicalFindings != null && report.summary!.clinicalFindings!.isNotEmpty) ...[
              _buildDarkSubsection(
                'Assessment',
                report.summary!.clinicalFindings!,
              ),
              const SizedBox(height: 20),
            ],
          ] else
            const Text(
              'No summary available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          
          // Original Text Button
          if (_report?.originalText != null && _report!.originalText!.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showOriginalText = !_showOriginalText;
                });
                if (_showOriginalText) {
                  _showOriginalTextDialog();
                }
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Original Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Red Flags Section
          if (report.redFlags.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildRedFlagsSection(report.redFlags),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDarkSubsection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskStratificationCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Risk Stratification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // HEART Score
          _buildRiskScoreCard(
            'HEART Score',
            '7',
            '/10',
            'HIGH',
            Colors.red,
            'Risk of MACE: 50-65%',
          ),
          const SizedBox(height: 12),
          // TIMI Risk
          _buildRiskScoreCard(
            'TIMI Risk',
            '4',
            '/7',
            'INTERMEDIATE',
            Colors.orange,
            '14-day events: 20%',
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(
    String title,
    String score,
    String max,
    String badge,
    Color badgeColor,
    String description,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: Colors.white.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              Text(
                ' $max',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferentialDiagnosisTab(ClinicalReportModel report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.differentialDiagnoses.isNotEmpty) ...[
            _buildConditionsSection(report.differentialDiagnoses),
            const SizedBox(height: 20),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No differential diagnoses available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSymptomAnalysisTab(ClinicalReportModel report) {
    // Get summary text and diagnoses for animation selection
    // PRIORITIZE SUMMARY TEXT - this is the main input for video selection
    final summaryText = report.summary?.summaryText ?? '';
    final diagnoses = report.differentialDiagnoses
        .map((d) => d.diagnosis)
        .toList();
    
    // Debug: Log what we're sending to video selector
    print('🎥 VIDEO SELECTOR: Summary text length: ${summaryText.length}');
    print('🎥 VIDEO SELECTOR: Summary preview: ${summaryText.length > 100 ? summaryText.substring(0, 100) + "..." : summaryText}');
    print('🎥 VIDEO SELECTOR: Diagnoses count: ${diagnoses.length}');
    if (diagnoses.isNotEmpty) {
      print('🎥 VIDEO SELECTOR: First diagnosis: ${diagnoses[0]}');
    }
    
    // Use Gemini AI to select video based on SUMMARY (primary) and diagnoses (context)
    // Summary text is the PRIMARY input for video selection
    final animationAssetFuture = GeminiVideoSelector.selectVideoWithAI(
      differentialDiagnoses: diagnoses,
      summaryText: summaryText,  // PRIMARY INPUT - summary text
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player - Automatically selected using AI based on symptoms/diagnosis
          FutureBuilder<String>(
            future: animationAssetFuture,
            builder: (context, snapshot) {
              // Show loading or fallback while waiting
              final assetPath = snapshot.hasData 
                  ? snapshot.data! 
                  : AnimationSelector.bodyGeneralUncertain;
              
              return ClinicalAnimationPlayer(
                animationAsset: assetPath,
                height: MediaQuery.of(context).size.height * 0.4,
              );
            },
          ),
          const SizedBox(height: 20),

          if (report.summary != null && report.summary!.symptoms.isNotEmpty) ...[
            SummarySectionCard(
              title: 'Symptoms',
              icon: Icons.medical_services,
              iconColor: AppTheme.violet,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.summary!.symptoms.map((symptom) {
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
            ),
            const SizedBox(height: 20),
          ],

          if (report.summary != null && report.summary!.clinicalFindings != null &&
              report.summary!.clinicalFindings!.isNotEmpty) ...[
            SummarySectionCard(
              title: 'Clinical Findings',
              icon: Icons.find_in_page,
              iconColor: Colors.orange,
              child: Text(
                report.summary!.clinicalFindings!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if ((report.summary == null || 
               (report.summary!.symptoms.isEmpty && 
                report.summary!.summaryText.isEmpty))) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No symptom analysis available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRAGEvidenceTab(ClinicalReportModel report) {
    // Collect all evidence from differential diagnoses
    final allEvidence = <EvidenceCitation>[];
    for (final diagnosis in report.differentialDiagnoses) {
      allEvidence.addAll(diagnosis.supportingEvidence);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allEvidence.isNotEmpty) ...[
            SummarySectionCard(
              title: 'RAG Evidence',
              icon: Icons.library_books,
              iconColor: AppTheme.blueViolet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Evidence Retrieved: ${report.totalEvidenceRetrieved}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...allEvidence.asMap().entries.map((entry) {
                    final index = entry.key;
                    final evidence = entry.value;
                    return _buildEvidenceCard(evidence, index);
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No RAG evidence available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceCitation evidence, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: index < 10 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightLavender.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.blueViolet.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blueViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PMCID: ${evidence.pmcid}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.blueViolet,
                  ),
                ),
              ),
              if (evidence.similarityScore != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(evidence.similarityScore! * 100).toStringAsFixed(1)}% match',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            evidence.textSnippet,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.darkGray,
              height: 1.5,
            ),
          ),
          if (evidence.citation != null && evidence.citation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Citation: ${evidence.citation}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mediumGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRedFlagsSection(List<RedFlag> redFlags) {
    if (redFlags.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'CRITICAL RED FLAGS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...redFlags.map((flag) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        flag.flag,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExtractedVitals(ClinicalReportModel report) {
    // Extract vitals from summary text (simplified - in production this would parse actual values)
    final summaryText = report.summary?.summaryText.toLowerCase() ?? '';
    
    String? bloodPressure;
    String? heartRate;
    String? spo2;
    String? temp;

    // Simple extraction - in production this would be more sophisticated
    final bpMatch = RegExp(r'(\d{2,3})/(\d{2,3})\s*(?:mmhg|bp|blood\s*pressure)').firstMatch(summaryText);
    if (bpMatch != null) {
      bloodPressure = '${bpMatch.group(1)}/${bpMatch.group(2)} mmHg';
    }

    final hrMatch = RegExp(r'(\d{2,3})\s*(?:bpm|heart\s*rate|hr)').firstMatch(summaryText);
    if (hrMatch != null) {
      heartRate = '${hrMatch.group(1)} bpm';
    }

    final spo2Match = RegExp(r'(\d{2,3})%\s*(?:spo2|oxygen|sat)').firstMatch(summaryText);
    if (spo2Match != null) {
      spo2 = '${spo2Match.group(1)}%';
    }

    final tempMatch = RegExp(r'(\d{2}\.\d)\s*(?:°c|celsius|temp|temperature)').firstMatch(summaryText);
    if (tempMatch != null) {
      temp = '${tempMatch.group(1)} °C';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.blue[300],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'EXTRACTED VITALS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Stack on very small screens
                  return Column(
                    children: [
                      _buildVitalPill('BLOOD PRESSURE', bloodPressure ?? 'N/A', Icons.favorite, Colors.red),
                      const SizedBox(height: 12),
                      _buildVitalPill('HEART RATE', heartRate ?? 'N/A', Icons.favorite, Colors.pink),
                      const SizedBox(height: 12),
                      _buildVitalPill('SPO2', spo2 ?? 'N/A', Icons.air, Colors.green),
                      const SizedBox(height: 12),
                      _buildVitalPill('TEMP', temp ?? 'N/A', Icons.thermostat, Colors.lightGreen),
                    ],
                  );
                }
                // Row on larger screens
                return Row(
                  children: [
                    Expanded(
                      child: _buildVitalPill('BLOOD PRESSURE', bloodPressure ?? 'N/A', Icons.favorite, Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVitalPill('HEART RATE', heartRate ?? 'N/A', Icons.favorite, Colors.pink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVitalPill('SPO2', spo2 ?? 'N/A', Icons.air, Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVitalPill('TEMP', temp ?? 'N/A', Icons.thermostat, Colors.lightGreen),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalPill(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: Colors.white.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mediumGray,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
