import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Medora Animated Loader - Replicates React loading effect
class MedoraLoader extends StatefulWidget {
  final String? statusMessage;
  final String? subStatusMessage;
  final List<String>? consoleLogs; // Real console log messages

  const MedoraLoader({
    super.key,
    this.statusMessage,
    this.subStatusMessage,
    this.consoleLogs,
  });

  @override
  State<MedoraLoader> createState() => _MedoraLoaderState();
}

class _MedoraLoaderState extends State<MedoraLoader>
    with TickerProviderStateMixin {
  late AnimationController _outerRingController;
  late AnimationController _innerRingController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;
  late AnimationController _fadeController;
  late AnimationController _logoRotationController;
  late AnimationController _consoleLogController;

  @override
  void initState() {
    super.initState();

    // Outer ring: Slow spinner (3s)
    _outerRingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Inner ring: Fast reverse spinner (1.5s)
    _innerRingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Center icon: Bounce animation (2s)
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Outer glow: Pulse animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Sparkle: Ping animation (2s)
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();

    // Console log animation: Update when logs change
    _consoleLogController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(MedoraLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when new logs arrive
    if (widget.consoleLogs != null && 
        widget.consoleLogs != oldWidget.consoleLogs &&
        widget.consoleLogs!.isNotEmpty) {
      _consoleLogController.forward(from: 0.0).then((_) {
        _consoleLogController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _outerRingController.dispose();
    _innerRingController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    _fadeController.dispose();
    _consoleLogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1628), // Same dark background as home screen
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // 1. The Animated Icon
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow (Static Ambience) - Pulse
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withOpacity(
                              0.2 * (0.5 + 0.5 * _glowController.value),
                            ),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Ring 1: Slow Spinner (Outer Data Layer)
                RotationTransition(
                  turns: _outerRingController,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF4FACFE).withOpacity(0.8),
                          width: 4,
                        ),
                        right: BorderSide(
                          color: const Color(0xFF00F2FE).withOpacity(0.8),
                          width: 4,
                        ),
                        left: BorderSide(
                          color: const Color(0xFF4FACFE).withOpacity(0.3),
                          width: 4,
                        ),
                        bottom: BorderSide(
                          color: Colors.transparent,
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),

                // Ring 2: Fast Reverse Spinner (Inner Processing Layer)
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: -1).animate(
                    CurvedAnimation(
                      parent: _innerRingController,
                      curve: Curves.linear,
                    ),
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF00F2FE),
                          width: 4,
                        ),
                        left: BorderSide(
                          color: const Color(0xFF4FACFE),
                          width: 4,
                        ),
                        top: BorderSide(
                          color: Colors.transparent,
                          width: 4,
                        ),
                        right: BorderSide(
                          color: Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),

                // Center: The AI Core (Custom Icon) - Bounce only (no rotation)
                AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    final bounceValue = _bounceController.value;
                    final offset = math.sin(bounceValue * math.pi) * 8;
                    return Transform.translate(
                      offset: Offset(0, -offset),
                      child: Container(
                        width: 150, // Larger size
                        height: 150, // Larger size
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F2FE).withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Logo image
                            ClipOval(
                              child: Image.asset(
                                'assets/animations/WhatsApp Image 2026-01-24 at 6.29.19 PM (1).jpeg',
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback if image not found
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00F2FE),
                                          Color(0xFF4FACFE),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.medical_services,
                                      color: Colors.white,
                                      size: 75,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Radial gradient overlay (darker at edges)
                            ClipOval(
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Tiny Sparkle Decoration - Ping
                Positioned(
                  top: -4,
                  right: -4,
                  child: AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      final pingValue = _sparkleController.value;
                      final scale = 1.0 + (pingValue * 0.3);
                      final opacity = 1.0 - pingValue;
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF4FACFE),
                              size: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 2. Text Feedback
          Column(
            children: [
              // Main title with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF64748B), // slate-700
                    Color(0xFF0F172A), // slate-900
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Medora is analyzing...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Animated Status Steps
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.5 + (0.5 * _glowController.value),
                        child: Text(
                          widget.statusMessage ?? 'Extracting clinical entities',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4FACFE),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subStatusMessage ??
                        'Checking interactions • Assessing risk scores',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 3. Console Log Display (3 lines with animation)
          _buildConsoleLog(),
        ],
      ),
      ),
    );
  }

  Widget _buildConsoleLog() {
    // Use real console logs if provided, otherwise show default messages
    final logs = widget.consoleLogs ?? [
      '> Initializing clinical pipeline...',
      '> Processing clinical entities...',
      '> Analyzing symptom patterns...',
    ];

    // Show only the last 3 lines
    final displayLogs = logs.length > 3 ? logs.sublist(logs.length - 3) : logs;

    return AnimatedBuilder(
      animation: _consoleLogController,
      builder: (context, child) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00F2FE).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Console header
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Medora AI Console',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Display last 3 log lines
              ...displayLogs.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            log,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: const Color(0xFF00F2FE),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  )),
              // Blinking cursor on last line
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _glowController.value,
                    child: Container(
                      width: 8,
                      height: 14,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F2FE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
