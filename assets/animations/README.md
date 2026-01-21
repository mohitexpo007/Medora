# Animation Assets Folder

Place your clinical animation video files (MP4 format) in this folder.

## Required Animation Files

### Organ-Specific Animations:
- `heart.mp4` - Heart/cardiac animations
- `brain.mp4` - Brain/neurological animations
- `lungs.mp4` - Lungs/respiratory animations
- `pancreas.mp4` - Pancreas/endocrine animations
- `kidneys.mp4` - Kidneys/renal animations
- `stomach.mp4` - Stomach/gastric animations
- `intestines.mp4` - Intestines/bowel animations
- `blood_vessels.mp4` - Blood vessels/vascular animations
- `nervous_system.mp4` - Nervous system animations

### Region-Based Pain Animations:
- `body_hand_red.mp4` - Hand/arm pain animations
- `body_leg_red.mp4` - Leg/foot pain animations

### Fallback Animation:
- `body_general_uncertain.mp4` - General/uncertain case animation

## File Format Requirements

- **Format**: MP4 (H.264 codec recommended for best compatibility)
- **Resolution**: 1080p or 720p recommended
- **Aspect Ratio**: 16:9 or 9:16 (portrait) works best
- **File Size**: Keep files optimized (< 10MB per file recommended)

## How It Works

The app automatically selects the appropriate animation based on:
1. Diagnosis keywords (e.g., "diabetes" → `pancreas.mp4`)
2. Summary text keywords (e.g., "heart" → `heart.mp4`)
3. Region-based pain keywords (e.g., "chest pain" → `body_chest_red.mp4`)
4. Fallback to `body_general_uncertain.mp4` if no match found

## Testing

After adding your video files:
1. Run `flutter pub get` to ensure dependencies are installed
2. Run `flutter run` to test the app
3. The animations will automatically play when viewing clinical summaries
