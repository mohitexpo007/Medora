import 'package:flutter/material.dart';
import 'dart:ui';

/// Reusable glassmorphism container widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double blurStrength;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurStrength = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 20.0;
    final bgColor = backgroundColor ?? Colors.white.withOpacity(0.25);
    final border = borderColor ?? Colors.white.withOpacity(0.6);
    final width = borderWidth ?? 1.5;
    final shadows = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: border,
              width: width,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}
