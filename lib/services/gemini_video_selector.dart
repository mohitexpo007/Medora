import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/animation_selector.dart';

/// Service that uses Gemini AI to intelligently select video based on differential diagnosis
class GeminiVideoSelector {
  // Available video options for Gemini to choose from
  static const List<String> availableVideos = [
    'brain',
    'lungs',
    'pancreas',
    'kidneys',
    'stomach',
    'intestines',
    'blood_vessels',
    'nervous_system',
    'body_hand_red',
    'body_leg_red',
    'body_general_uncertain',
  ];

  /// Maps video names to asset paths
  static String _getAssetPath(String videoName) {
    switch (videoName.toLowerCase()) {
      case 'brain':
        return AnimationSelector.brain;
      case 'lungs':
        return AnimationSelector.lungs;
      case 'pancreas':
        return AnimationSelector.pancreas;
      case 'kidneys':
        return AnimationSelector.kidneys;
      case 'stomach':
        return AnimationSelector.stomach;
      case 'intestines':
        return AnimationSelector.intestines;
      case 'blood_vessels':
      case 'bloodvessels':
      case 'cardiovascular':
      case 'heart':
        return AnimationSelector.bloodVessels;
      case 'nervous_system':
      case 'nervoussystem':
        return AnimationSelector.nervousSystem;
      case 'body_hand_red':
      case 'hand':
        return AnimationSelector.bodyHandRed;
      case 'body_leg_red':
      case 'leg':
        return AnimationSelector.bodyLegRed;
      case 'body_general_uncertain':
      case 'general':
      case 'uncertain':
      default:
        return AnimationSelector.bodyGeneralUncertain;
    }
  }

  /// Uses Gemini AI to select the most appropriate video based on clinical summary
  /// 
  /// [differentialDiagnoses] - List of differential diagnoses (for context)
  /// [summaryText] - PRIMARY: Clinical summary text - this is the main input for video selection
  /// [apiKey] - Gemini API key (optional, can be set via environment or config)
  /// 
  /// Returns the asset path for the selected video, or fallback if AI selection fails
  static Future<String> selectVideoWithAI({
    required List<String> differentialDiagnoses,
    String summaryText = '',
    String? apiKey,
  }) async {
    // Fallback to keyword-based selection if no summary provided
    if (summaryText.isEmpty && differentialDiagnoses.isEmpty) {
      return AnimationSelector.bodyGeneralUncertain;
    }
    
    // Prioritize summary text - if available, use it as primary input
    // If summary is empty, fall back to diagnoses

    try {
      // Use Gemini API to analyze and select video
      final selectedVideo = await _callGeminiAPI(
        differentialDiagnoses: differentialDiagnoses,
        summaryText: summaryText,
        apiKey: apiKey,
      );

      if (selectedVideo != null) {
        return _getAssetPath(selectedVideo);
      }
    } catch (e) {
      // If AI selection fails, fall back to keyword-based selection
      print('Gemini video selection failed: $e');
    }

    // Fallback to keyword-based selection (prioritize summary text)
    // Pass summary first, then diagnoses
    return AnimationSelector.selectAnimationAsset(
      summaryText.isNotEmpty ? summaryText : '',
      differentialDiagnoses,
    );
  }

  /// Calls Gemini API to get video selection
  static Future<String?> _callGeminiAPI({
    required List<String> differentialDiagnoses,
    String summaryText = '',
    String? apiKey,
  }) async {
    // Get API key from parameter, environment, or use a default
    final geminiApiKey = apiKey ?? 
        const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    if (geminiApiKey.isEmpty) {
      // If no API key, skip AI selection and use fallback
      return null;
    }

    // Prepare the prompt - PRIORITIZE SUMMARY TEXT
    final diagnosesText = differentialDiagnoses.isNotEmpty 
        ? differentialDiagnoses.join(', ') 
        : 'None provided';
    
    // Use full summary text (up to 1000 chars for better context)
    final summaryForAnalysis = summaryText.isNotEmpty 
        ? summaryText.substring(0, summaryText.length > 1000 ? 1000 : summaryText.length)
        : '';
    
    final prompt = '''
You are a medical AI assistant specialized in selecting the most appropriate organ/body system animation video based on clinical presentation.

PRIMARY INPUT - CLINICAL SUMMARY (ANALYZE THIS CAREFULLY):
${summaryForAnalysis.isNotEmpty ? summaryForAnalysis : 'No summary provided'}

SECONDARY CONTEXT - Differential Diagnoses:
${diagnosesText}

YOUR TASK:
Analyze the CLINICAL SUMMARY above to identify:
1. The PRIMARY affected organ/system
2. The MAIN clinical presentation
3. The DOMINANT symptom pattern

CRITICAL RULES FOR VIDEO SELECTION:
1. **Cardiac/Heart (blood_vessels)**: 
   - Exertional pain (worse on exertion), chest pain, ACS, NSTEMI, STEMI, angina, MI
   - Fluctuating vitals with chest/exertional pain
   - Cardiac concerns, coronary issues, arrhythmia
   
2. **Respiratory/Lungs (lungs)**:
   - Respiratory distress, dyspnea, pneumonia, COPD, asthma
   - Breathing difficulties, oxygen issues, pulmonary concerns
   
3. **Neurological/Brain (brain)**:
   - Stroke, seizure, migraine, epilepsy, brain disorders
   - Neurological deficits, altered mental status
   
4. **Other organs**: Match to specific organ mentioned in summary (pancreas, kidneys, stomach, intestines)

5. **Uncertain (body_general_uncertain)**: 
   - Only use if no clear organ/system can be identified from the summary

SELECTION PRIORITY:
1. Analyze the CLINICAL SUMMARY first - what is the main presentation?
2. What organ/system is primarily affected based on the symptoms described?
3. Use differential diagnoses only as supporting context
4. If summary mentions multiple systems, choose the PRIMARY/MOST SIGNIFICANT one

Available video options:
- brain: Neurological conditions (stroke, seizure, migraine, epilepsy, brain disorders)
- lungs: Respiratory conditions (pneumonia, COPD, asthma, bronchitis, respiratory distress, dyspnea)
- pancreas: Endocrine/diabetes (diabetes, insulin, glucose, glycemic issues)
- kidneys: Renal conditions (kidney disease, renal failure, nephritis, dialysis)
- stomach: Gastric conditions (gastritis, gastric ulcer, peptic ulcer)
- intestines: Bowel conditions (colitis, Crohn's, IBS, irritable bowel)
- blood_vessels: Cardiovascular conditions (heart, cardiac, ACS, NSTEMI, STEMI, angina, MI, exertional pain, chest pain)
- nervous_system: Peripheral nervous system (neuropathy, peripheral neuropathy)
- body_hand_red: Hand/wrist/arm pain or conditions
- body_leg_red: Leg/knee/ankle/foot pain or conditions
- body_general_uncertain: General/uncertain cases when no specific match

Respond with ONLY the video name (e.g., "brain", "lungs", "blood_vessels", etc.) from the list above. Do not include any explanation or additional text.
''';

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final candidates = jsonResponse['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) {
              // Extract the video name (clean up any extra text)
              final videoName = text.trim().toLowerCase()
                  .replaceAll(RegExp(r'[^a-z_0-9]'), '')
                  .replaceAll(' ', '_');
              
              // Validate it's one of our available videos
              for (final availableVideo in availableVideos) {
                if (videoName.contains(availableVideo) || 
                    availableVideo.contains(videoName)) {
                  return availableVideo;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
    }

    return null;
  }
}
