import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'clinical_summary_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _starsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _starsController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _onAnalyzeTap() {
    _showClinicalNoteInputDialog();
  }

  void _showClinicalNoteInputDialog() {
    final TextEditingController noteController = TextEditingController();
    final navigatorContext = context;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            // Blurred background overlay - covers entire screen
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            // Dialog content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
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
                              'Enter Clinical Note',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Text area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: noteController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste or type the clinical note here...',
                              hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.4),
                                fontSize: 14,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OR UPLOAD separator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR UPLOAD',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Upload buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildUploadButton(
                              icon: Icons.image,
                              label: 'Image',
                              iconColor: const Color(0xFF10B981),
                              onTap: () => _pickAndUpload(dialogContext, navigatorContext, isPdf: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildUploadButton(
                              icon: Icons.picture_as_pdf,
                              label: 'PDF',
                              iconColor: const Color(0xFF00D4FF),
                              onTap: () => _pickAndUpload(dialogContext, navigatorContext, isPdf: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF0F172A),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D4FF), Color(0xFF10B981)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    final noteText = noteController.text.trim();
                                    if (noteText.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter a clinical note or upload a file'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                    Navigator.push(
                                      navigatorContext,
                                      MaterialPageRoute(
                                        builder: (context) => ClinicalSummaryScreen(
                                          noteText: noteText,
                                          patientId: 'PT-0001',
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Generate\nSummary',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Stack(
                                          children: [
                                            const Icon(
                                              Icons.auto_awesome,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Icon(
                                                Icons.auto_awesome,
                                                color: Colors.white.withOpacity(0.6),
                                                size: 8,
                                              ),
                                            ),
                                            Positioned(
                                              left: -2,
                                              bottom: -2,
                                              child: Icon(
                                                Icons.auto_awesome,
                                                color: Colors.white.withOpacity(0.6),
                                                size: 8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Animated star background
          AnimatedBuilder(
            animation: _starsController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarsPainter(_starsController.value),
                size: Size.infinite,
              );
            },
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Badge
                        _buildBadge(),
                        const SizedBox(height: 24),
                        // Title
                        _buildTitle(),
                        const SizedBox(height: 16),
                        // Description
                        _buildDescription(),
                        const SizedBox(height: 32),
                        // Cards
                        _buildCards(),
                        const SizedBox(height: 24),
                        // Compliance badges
                        _buildComplianceBadges(),
                        const SizedBox(height: 32),
                        // Generate Summary button
                        _buildGenerateButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: null, // Removed bottom navigation
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Medora',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Right icons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.white,
                onPressed: () {},
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D4FF),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF00D4FF),
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 14,
            color: Color(0xFF00D4FF),
          ),
          const SizedBox(width: 8),
          const Text(
            'ADVANCED AI CO-PILOT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00D4FF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.auto_awesome,
            size: 14,
            color: Color(0xFF00D4FF),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        children: [
          TextSpan(
            text: 'The AI Co-Pilot for\n',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Diagnostic Certainty.',
            style: TextStyle(color: Color(0xFF00D4FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Elevating clinical outcomes with real-time medical evidence synthesis and patient data analysis.',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white70,
        height: 1.5,
      ),
    );
  }

  Widget _buildCards() {
    return Column(
      children: [
        _buildCard(
          icon: Icons.description,
          iconColor: const Color(0xFF00D4FF),
          title: 'Analyze Patient Note',
          description: 'Extract clinical facts & insights',
          onTap: _onAnalyzeTap,
          index: 0,
        ),
        const SizedBox(height: 16),
        _buildCard(
          icon: Icons.history,
          iconColor: const Color(0xFF00E5CC),
          title: 'History',
          description: 'Recent diagnoses and reviews',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
          index: 1,
        ),
        const SizedBox(height: 16),
        _buildCard(
          icon: Icons.assessment,
          iconColor: const Color(0xFFFFB84D),
          title: 'Risk Assessment',
          description: 'Predictive health analytics',
          onTap: () {},
          index: 2,
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceBadges() {
    return Row(
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 16,
              color: Color(0xFF10B981),
            ),
            const SizedBox(width: 6),
            Text(
              'HIPAA COMPLIANT',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            const Icon(
              Icons.lock,
              size: 16,
              color: Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              'SOC 2 TYPE II',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onAnalyzeTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Generate Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withOpacity(0.6),
                        size: 8,
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withOpacity(0.6),
                        size: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
              _buildNavItem(Icons.folder, 'Cases', false),
              _buildNavItem(Icons.search, 'Search', false),
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
        if (label == 'Cases') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
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

  Future<void> _pickAndUpload(
    BuildContext dialogContext,
    BuildContext navigatorContext, {
    required bool isPdf,
  }) async {
    // #region agent log
    try {
      final logData = {
        'location': 'home_screen.dart:894',
        'message': '_pickAndUpload called',
        'data': {'isPdf': isPdf},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'upload-check',
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
      final result = await FilePicker.platform.pickFiles(
        type: isPdf ? FileType.custom : FileType.image,
        allowedExtensions: isPdf ? ['pdf'] : null,
        withData: true,
      );
      
      // #region agent log
      try {
        final logData = {
          'location': 'home_screen.dart:910',
          'message': 'FilePicker result',
          'data': {
            'resultIsNull': result == null,
            'filesCount': result?.files.length ?? 0,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'A',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final path = f.path;
      final bytes = f.bytes;
      final usePath = path != null && path.isNotEmpty;
      final useBytes = bytes != null && bytes.isNotEmpty;
      
      // #region agent log
      try {
        final logData = {
          'location': 'home_screen.dart:925',
          'message': 'File data extracted',
          'data': {
            'fileName': f.name,
            'hasPath': path != null,
            'pathLength': path?.length ?? 0,
            'hasBytes': bytes != null,
            'bytesLength': bytes?.length ?? 0,
            'usePath': usePath,
            'useBytes': useBytes,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'A',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      if (!usePath && !useBytes) {
        // #region agent log
        try {
          final logData = {
            'location': 'home_screen.dart:945',
            'message': 'File read failed - no path or bytes',
            'data': {},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'upload-check',
            'hypothesisId': 'B',
          };
          await http.post(
            Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(logData),
          ).catchError((_) {});
        } catch (_) {}
        // #endregion
        if (!mounted) return;
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          const SnackBar(
            content: Text('Could not read file. Try a different file.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final fileName = (f.name.trim().isEmpty) ? 'upload' : f.name;
      if (!mounted) return;
      
      // Show uploading message before closing dialog
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        const SnackBar(content: Text('Uploading & analyzing…')),
      );
      
      // #region agent log
      try {
        final logData = {
          'location': 'home_screen.dart:965',
          'message': 'Calling ApiService.uploadClinicalNote',
          'data': {
            'fileName': fileName,
            'usePath': usePath,
            'useBytes': useBytes,
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
      
      // Close dialog before async operation to avoid context issues
      if (mounted && Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
      
      final json = await ApiService.uploadClinicalNote(
        filePath: usePath ? path : null,
        fileBytes: useBytes ? bytes : null,
        fileName: fileName,
        patientId: 'PT-0001',
      );
      
      // #region agent log
      try {
        final logData = {
          'location': 'home_screen.dart:978',
          'message': 'ApiService.uploadClinicalNote completed',
          'data': {
            'hasJson': json != null,
            'jsonKeys': json?.keys.toList() ?? [],
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
      
      if (!mounted) return;
      
      // Navigate to summary screen
      Navigator.push(
        navigatorContext,
        MaterialPageRoute(
          builder: (_) => ClinicalSummaryScreen(
            initialReport: json,
            patientId: 'PT-0001',
          ),
        ),
      );
      
      // Show success message after navigation
      if (mounted) {
        // Use a post-frame callback to ensure context is valid
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              ScaffoldMessenger.of(navigatorContext).showSnackBar(
                const SnackBar(content: Text('Analysis complete'), backgroundColor: Colors.green),
              );
            } catch (_) {
              // Ignore if context is invalid
            }
          }
        });
      }
    } catch (e, stackTrace) {
      // #region agent log
      try {
        final logData = {
          'location': 'home_screen.dart:1000',
          'message': 'Exception in _pickAndUpload',
          'data': {
            'error': e.toString(),
            'errorType': e.runtimeType.toString(),
            'stackTrace': stackTrace.toString(),
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'upload-check',
          'hypothesisId': 'D',
        };
        await http.post(
          Uri.parse('http://127.0.0.1:7242/ingest/e7c7bc3b-02cf-4cf7-86b7-7d0c5029d869'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(logData),
        ).catchError((_) {});
      } catch (_) {}
      // #endregion
      
      // Close dialog if still open
      if (mounted && Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
      
      if (!mounted) return;
      
      final msg = e.toString().contains('LateInitializationError')
          ? 'App state error. Please try again.'
          : 'Upload failed: $e';
      
      // Use post-frame callback to safely show error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            ScaffoldMessenger.of(navigatorContext).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          } catch (_) {
            // Ignore if context is invalid - error already logged
          }
        }
      });
    }
  }
}

class _UploadRow extends StatelessWidget {
  final VoidCallback onUploadImage;
  final VoidCallback onUploadPdf;

  const _UploadRow({
    required this.onUploadImage,
    required this.onUploadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onUploadImage,
            icon: const Icon(Icons.image, size: 18),
            label: const Text('Image'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onUploadPdf,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for animated stars background
class StarsPainter extends CustomPainter {
  final double animationValue;

  StarsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 50; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final radius = 1 + random.nextDouble() * 2;
      final opacity = 0.3 + (math.sin(animationValue * 2 * math.pi + i) + 1) / 2 * 0.4;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
