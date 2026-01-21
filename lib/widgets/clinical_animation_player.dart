import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import '../utils/animation_selector.dart';
import '../theme/app_theme.dart';

/// Widget that plays clinical animation videos with smooth transitions.
class ClinicalAnimationPlayer extends StatefulWidget {
  final String animationAsset;
  final double? height;
  final BoxFit fit;

  const ClinicalAnimationPlayer({
    super.key,
    required this.animationAsset,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<ClinicalAnimationPlayer> createState() =>
      _ClinicalAnimationPlayerState();
}

class _ClinicalAnimationPlayerState extends State<ClinicalAnimationPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  String? _currentAsset;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadVideo(widget.animationAsset);
  }

  @override
  void didUpdateWidget(ClinicalAnimationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationAsset != widget.animationAsset) {
      _loadVideo(widget.animationAsset);
    }
  }

  Future<void> _loadVideo(String assetPath) async {
    // Fade out current video
    if (_currentAsset != null && _currentAsset != assetPath) {
      await _fadeController.reverse();
    }

    // Dispose old controller
    await _controller?.dispose();

    // Load new video
    try {
      _controller = VideoPlayerController.asset(assetPath);
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(0.0); // Mute audio
      _controller!.play();

      setState(() {
        _isInitialized = true;
        _currentAsset = assetPath;
      });

      // Fade in new video
      _fadeController.forward();
    } catch (e) {
      // If video fails to load, show placeholder
      setState(() {
        _isInitialized = false;
        _currentAsset = assetPath;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? MediaQuery.of(context).size.height * 0.35;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _isInitialized && _controller != null
                ? _buildVideoPlayer()
                : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        // Label showing affected system
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Affected system: ${_getSystemName(_currentAsset!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkGray,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AnimationSelector.getIconForAnimation(_currentAsset ?? ''),
            size: 64,
            color: AppTheme.blueViolet.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Animation: ${_getAnimationLabel(_currentAsset ?? '')}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '(Video asset not found)',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getAnimationLabel(String assetPath) {
    final fileName = assetPath.split('/').last.replaceAll('.mp4', '');
    return fileName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getSystemName(String assetPath) {
    final fileName = assetPath.split('/').last.replaceAll('.mp4', '');
    
    // Map animation files to system names
    if (fileName.contains('heart')) return 'Cardiovascular';
    if (fileName.contains('brain')) return 'Neurological';
    if (fileName.contains('lungs')) return 'Respiratory';
    if (fileName.contains('pancreas')) return 'Endocrine';
    if (fileName.contains('kidneys')) return 'Renal';
    if (fileName.contains('stomach')) return 'Gastrointestinal';
    if (fileName.contains('intestines')) return 'Gastrointestinal';
    if (fileName.contains('blood_vessels')) return 'Vascular';
    if (fileName.contains('nervous_system')) return 'Nervous System';
    if (fileName.contains('hand')) return 'Musculoskeletal';
    if (fileName.contains('leg')) return 'Musculoskeletal';
    
    return 'General';
  }
}
