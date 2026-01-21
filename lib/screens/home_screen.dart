import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'clinical_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _glowController;
  late AnimationController _buttonController;
  late AnimationController _iconController;

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonScale;
  late List<Animation<double>> _iconFades;

  @override
  void initState() {
    super.initState();

    // Hero card animation
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    // Glow animation for AI body scan
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Button scale animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Icon staggered animations
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _iconFades = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _iconController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    // Start animations
    _heroController.forward();
    _iconController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _glowController.dispose();
    _buttonController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _onButtonTap() {
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    _showClinicalNoteInputDialog();
  }

  void _showClinicalNoteInputDialog() {
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.blueViolet, AppTheme.violet],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_information,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Enter Clinical Note',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppTheme.mediumGray,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: noteController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Paste or type the clinical note here...\n\nExample:\n58-year-old male presents with chest pain for 3 hours. Patient reports substernal pressure-like pain, 7/10 severity, radiating to left arm...',
                    hintStyle: TextStyle(
                      color: AppTheme.mediumGray.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.mediumGray.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.mediumGray.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.blueViolet,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final noteText = noteController.text.trim();
                        if (noteText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a clinical note'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClinicalSummaryScreen(
                              noteText: noteText,
                              patientId: 'PT-0001',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.blueViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Generate Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
          child: Column(
            children: [
              // Top Section
              _buildTopSection(),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Hero Card
                      SlideTransition(
                        position: _heroSlide,
                        child: FadeTransition(
                          opacity: _heroFade,
                          child: _buildHeroCard(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Quick Action Row
                      _buildQuickActionRow(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good evening, Doctor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI-powered clinical insights',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.blueViolet.withOpacity(0.8),
                  AppTheme.violet.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.blueViolet.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Body Scan Illustration
              _buildAIBodyScan(),
              const SizedBox(height: 24),
              const Text(
                'Generate Clinical Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyze clinical notes with explainable AI',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // CTA Button
              ScaleTransition(
                scale: _buttonScale,
                child: GestureDetector(
                  onTap: _onButtonTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.blueViolet, AppTheme.violet],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.blueViolet.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Start Analysis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIBodyScan() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: RadialGradient(
              center: Alignment.center,
              colors: [
                AppTheme.blueViolet.withOpacity(_glowAnimation.value * 0.3),
                AppTheme.violet.withOpacity(_glowAnimation.value * 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Placeholder body outline
              CustomPaint(
                size: const Size(120, 180),
                painter: BodyScanPainter(
                  glowIntensity: _glowAnimation.value,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickActionCard(
          icon: Icons.calendar_today,
          label: 'History',
          color: AppTheme.historyIcon,
          index: 0,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
        _buildQuickActionCard(
          icon: Icons.favorite,
          label: 'Diagnoses',
          color: AppTheme.diagnosesIcon,
          index: 1,
        ),
        _buildQuickActionCard(
          icon: Icons.description,
          label: 'Raw Notes',
          color: AppTheme.notesIcon,
          index: 2,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required int index,
    VoidCallback? onTap,
  }) {
    return FadeTransition(
      opacity: _iconFades[index],
      child: GestureDetector(
        onTap: onTap ?? () {
          // TODO: Navigate to respective screens
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: (MediaQuery.of(context).size.width - 60) / 3,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkGray,
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

  Widget _buildBottomNavigation() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'Home', true),
                  _buildNavItem(Icons.history, 'History', false),
                  _buildNavItem(Icons.add_circle_outline, 'New Summary', false, onTap: () {
                    _showClinicalNoteInputDialog();
                  }),
                  _buildNavItem(Icons.person_outline, 'Profile', false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (label == 'History') {
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
            color: isActive ? AppTheme.blueViolet : AppTheme.mediumGray,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.blueViolet : AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class BodyScanPainter extends CustomPainter {
  final double glowIntensity;

  BodyScanPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw body outline (simplified human silhouette)
    final paint = Paint()
      ..color = AppTheme.blueViolet.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Head
    canvas.drawCircle(
      Offset(centerX, centerY - size.height * 0.35),
      size.width * 0.15,
      paint,
    );

    // Body
    final bodyPath = Path()
      ..moveTo(centerX, centerY - size.height * 0.2)
      ..lineTo(centerX - size.width * 0.12, centerY + size.height * 0.15)
      ..lineTo(centerX - size.width * 0.08, centerY + size.height * 0.25)
      ..lineTo(centerX, centerY + size.height * 0.2)
      ..lineTo(centerX + size.width * 0.08, centerY + size.height * 0.25)
      ..lineTo(centerX + size.width * 0.12, centerY + size.height * 0.15)
      ..close();

    canvas.drawPath(bodyPath, paint);

    // Arms
    canvas.drawLine(
      Offset(centerX - size.width * 0.12, centerY - size.height * 0.1),
      Offset(centerX - size.width * 0.25, centerY + size.height * 0.1),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + size.width * 0.12, centerY - size.height * 0.1),
      Offset(centerX + size.width * 0.25, centerY + size.height * 0.1),
      paint,
    );

    // Legs
    canvas.drawLine(
      Offset(centerX - size.width * 0.08, centerY + size.height * 0.25),
      Offset(centerX - size.width * 0.1, centerY + size.height * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + size.width * 0.08, centerY + size.height * 0.25),
      Offset(centerX + size.width * 0.1, centerY + size.height * 0.4),
      paint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = AppTheme.violet.withOpacity(glowIntensity * 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.4,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(BodyScanPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}
