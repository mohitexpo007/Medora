import 'package:flutter/material.dart';

/// Utility class for selecting appropriate animation assets based on
/// clinical summary text and diagnoses.
class AnimationSelector {
  // Animation asset paths
  static const String heart = 'assets/animations/organs/heart.mp4';
  static const String brain = 'assets/animations/organs/brain.mp4';
  static const String lungs = 'assets/animations/organs/lungs.mp4';
  static const String pancreas = 'assets/animations/organs/pancreas.mp4';
  static const String kidneys = 'assets/animations/organs/kidneys.mp4';
  static const String stomach = 'assets/animations/organs/stomach.mp4';
  static const String intestines = 'assets/animations/organs/intestines.mp4';
  static const String bloodVessels = 'assets/animations/organs/blood_vessels.mp4';
  static const String nervousSystem = 'assets/animations/nervous_system.mp4';
  static const String bodyHandRed = 'assets/animations/regions/body_hand_red.mp4';
  static const String bodyLegRed = 'assets/animations/regions/body_leg_red.mp4';
  static const String bodyGeneralUncertain = 'assets/animations/fallback/body_general_uncertain.mp4';

  /// Organ-based keyword mappings (Priority 1)
  static final Map<String, String> _organKeywords = {
    // Heart
    'heart': heart,
    'cardiac': heart,
    'myocardial': heart,
    'hypertension': heart,
    'cardiovascular': heart,
    'arrhythmia': heart,
    'coronary': heart,
    
    // Brain / Neuro
    'stroke': brain,
    'brain': brain,
    'seizure': brain,
    'neurological': brain,
    'cerebral': brain,
    'neurologic': brain,
    'epilepsy': brain,
    'migraine': brain,
    
    // Lungs / Respiratory
    'lung': lungs,
    'pneumonia': lungs,
    'copd': lungs,
    'asthma': lungs,
    'respiratory': lungs,
    'pulmonary': lungs,
    'bronchitis': lungs,
    'emphysema': lungs,
    
    // Endocrine / Diabetes (Pancreas)
    'diabetes': pancreas,
    'hba1c': pancreas,
    'insulin': pancreas,
    'glycemic': pancreas,
    'pancreas': pancreas,
    'diabetic': pancreas,
    'glucose': pancreas,
    'hyperglycemia': pancreas,
    
    // Kidneys
    'kidney': kidneys,
    'renal': kidneys,
    'creatinine': kidneys,
    'nephritis': kidneys,
    'nephropathy': kidneys,
    'dialysis': kidneys,
    
    // Stomach
    'stomach': stomach,
    'gastritis': stomach,
    'gastric': stomach,
    'ulcer': stomach,
    'peptic': stomach,
    
    // Intestines
    'intestine': intestines,
    'bowel': intestines,
    'colitis': intestines,
    'crohn': intestines,
    'ibs': intestines,
    'irritable bowel': intestines,
    
    // Blood Vessels
    'vascular': bloodVessels,
    'clot': bloodVessels,
    'thrombosis': bloodVessels,
    'thrombus': bloodVessels,
    'embolism': bloodVessels,
    'dvt': bloodVessels,
    'deep vein thrombosis': bloodVessels,
    
    // Nervous System (system-level)
    'nervous system': nervousSystem,
    'neuropathy': nervousSystem,
    'peripheral neuropathy': nervousSystem,
  };

  /// Region-based pain keywords (Priority 2 - only if no organ detected)
  static final Map<String, String> _regionKeywords = {
    'hand pain': bodyHandRed,
    'wrist pain': bodyHandRed,
    'finger pain': bodyHandRed,
    'arm pain': bodyHandRed,
    
    'leg pain': bodyLegRed,
    'knee pain': bodyLegRed,
    'ankle pain': bodyLegRed,
    'foot pain': bodyLegRed,
    'thigh pain': bodyLegRed,
  };

  /// Selects the appropriate animation asset based on summary text and diagnoses.
  /// 
  /// Priority order:
  /// 1. Check diagnosis list for organ-based keywords
  /// 2. Check summary text for organ-based keywords
  /// 3. Check for region-based pain keywords
  /// 4. Return fallback animation
  static String selectAnimationAsset(
    String summaryText,
    List<String> diagnosisList,
  ) {
    // Normalize all text to lowercase for matching
    final normalizedSummary = summaryText.toLowerCase();
    final normalizedDiagnoses = diagnosisList.map((d) => d.toLowerCase()).toList();

    // Priority 1: Check diagnosis list for organ-based keywords
    for (final diagnosis in normalizedDiagnoses) {
      for (final entry in _organKeywords.entries) {
        if (diagnosis.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // Priority 2: Check summary text for organ-based keywords
    for (final entry in _organKeywords.entries) {
      if (normalizedSummary.contains(entry.key)) {
        return entry.value;
      }
    }

    // Priority 3: Check for region-based pain (only if no organ detected)
    for (final entry in _regionKeywords.entries) {
      if (normalizedSummary.contains(entry.key) || 
          normalizedDiagnoses.any((d) => d.contains(entry.key))) {
        return entry.value;
      }
    }
    
    // Priority 3a: Check for hand/leg with pain context (more flexible matching)
    if (_hasHandPain(normalizedSummary)) {
      return bodyHandRed;
    }
    if (_hasLegPain(normalizedSummary)) {
      return bodyLegRed;
    }

    // Priority 3b: Map abdominal/chest pain to organ-based or fallback
    if (normalizedSummary.contains('abdominal pain') || 
        normalizedSummary.contains('stomach pain') ||
        normalizedSummary.contains('belly pain') ||
        normalizedDiagnoses.any((d) => d.contains('abdominal') || d.contains('stomach pain'))) {
      // Try to map to stomach or intestines, otherwise fallback
      if (normalizedSummary.contains('stomach') || normalizedSummary.contains('gastric')) {
        return stomach;
      }
      if (normalizedSummary.contains('intestine') || normalizedSummary.contains('bowel')) {
        return intestines;
      }
      return bodyGeneralUncertain;
    }
    
    if (normalizedSummary.contains('chest pain') || 
        normalizedSummary.contains('chest discomfort') ||
        normalizedSummary.contains('thoracic pain') ||
        normalizedDiagnoses.any((d) => d.contains('chest'))) {
      // Try to map to heart/lungs, otherwise fallback
      if (normalizedSummary.contains('heart') || normalizedSummary.contains('cardiac')) {
        return heart;
      }
      if (normalizedSummary.contains('lung') || normalizedSummary.contains('respiratory')) {
        return lungs;
      }
      return bodyGeneralUncertain;
    }

    // Priority 4: Fallback
    return bodyGeneralUncertain;
  }

  /// Check if summary indicates hand pain
  static bool _hasHandPain(String normalizedSummary) {
    // Check for common hand pain patterns
    final handPatterns = ['hand', 'wrist', 'finger', 'arm'];
    final painIndicators = ['pain', 'stiffness', 'discomfort', 'ache', 'sore', 'tenderness'];
    
    for (final handPattern in handPatterns) {
      if (normalizedSummary.contains(handPattern)) {
        // Check for patterns like "pain in the hand", "hand pain", "stiffness in hand", etc.
        if (normalizedSummary.contains('in the $handPattern') ||
            normalizedSummary.contains('in $handPattern') ||
            normalizedSummary.contains('$handPattern pain') ||
            normalizedSummary.contains('pain in $handPattern')) {
          return true;
        }
        
        // Check for pain indicators with hand context
        for (final painIndicator in painIndicators) {
          if (normalizedSummary.contains('$painIndicator in $handPattern') ||
              (normalizedSummary.contains('$painIndicator and') && normalizedSummary.contains('in $handPattern'))) {
            return true;
          }
        }
        
        // Check for localized pain with hand mentioned
        if (normalizedSummary.contains('localized') && normalizedSummary.contains(handPattern)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if summary indicates leg pain
  static bool _hasLegPain(String normalizedSummary) {
    // Check for common leg pain patterns
    final legPatterns = ['leg', 'knee', 'ankle', 'foot', 'thigh', 'lower limb'];
    final painIndicators = ['pain', 'heaviness', 'discomfort', 'ache', 'sore', 'tenderness'];
    
    for (final legPattern in legPatterns) {
      if (normalizedSummary.contains(legPattern)) {
        // Check for patterns like "pain in the leg", "leg pain", "heaviness in leg", etc.
        if (normalizedSummary.contains('in the $legPattern') ||
            normalizedSummary.contains('in $legPattern') ||
            normalizedSummary.contains('$legPattern pain') ||
            normalizedSummary.contains('pain in $legPattern')) {
          return true;
        }
        
        // Check for pain indicators with leg context
        for (final painIndicator in painIndicators) {
          if (normalizedSummary.contains('$painIndicator in $legPattern') ||
              (normalizedSummary.contains('$painIndicator and') && normalizedSummary.contains('in $legPattern'))) {
            return true;
          }
        }
        
        // Check for localized pain with leg mentioned
        if (normalizedSummary.contains('localized') && normalizedSummary.contains(legPattern)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Gets the icon data for the selected animation (for UI display)
  static IconData getIconForAnimation(String assetPath) {
    if (assetPath == heart) return Icons.favorite;
    if (assetPath == brain) return Icons.psychology;
    if (assetPath == lungs) return Icons.air;
    if (assetPath == pancreas) return Icons.circle;
    if (assetPath == kidneys) return Icons.water_drop;
    if (assetPath == stomach) return Icons.restaurant;
    if (assetPath == intestines) return Icons.alt_route;
    if (assetPath == bloodVessels) return Icons.bloodtype;
    if (assetPath == nervousSystem) return Icons.psychology;
    return Icons.help_outline;
  }
}
