import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loading shimmer skeleton widget
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Full page loading shimmer for clinical summary
class ClinicalSummaryLoadingShimmer extends StatelessWidget {
  const ClinicalSummaryLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header shimmer
        LoadingShimmer(
          width: double.infinity,
          height: 60,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 20),
        
        // Section card shimmers
        ...List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(
                  width: 200,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                LoadingShimmer(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
