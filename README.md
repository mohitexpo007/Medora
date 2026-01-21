# Medora - Healthcare Flutter App

A modern Flutter Android application built with Material 3 design, featuring a healthcare theme with teal/blue colors.

## Features

- **Material 3 Design**: Modern, beautiful UI following Material 3 guidelines
- **Healthcare Theme**: Custom teal/blue color scheme optimized for healthcare applications
- **Reusable Components**: Well-structured widget library for easy reuse
- **Clean Architecture**: Organized folder structure with separation of concerns
- **Global Medical Disclaimer**: Reusable medical disclaimer widget for app-wide use
- **Dark Mode Support**: Full dark theme support with healthcare-appropriate colors

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # App-wide theme configuration
├── screens/
│   └── home_screen.dart     # Home screen example
├── widgets/
│   ├── medical_disclaimer.dart  # Global medical disclaimer widget
│   └── health_card.dart         # Reusable health card widget
├── models/
│   ├── health_record.dart   # Health record model
│   └── appointment.dart     # Appointment model
└── services/
    └── health_service.dart  # Health service for data operations
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Usage

### Theme Configuration

The app theme is configured in `lib/theme/app_theme.dart`. You can customize:
- Primary colors (teal/blue healthcare theme)
- Card styles
- Button styles
- Input decoration styles
- Dark mode support

### Medical Disclaimer Widget

Use the `MedicalDisclaimer` widget anywhere in your app:

```dart
MedicalDisclaimer()  // Full disclaimer
MedicalDisclaimer(isCompact: true)  // Compact version
MedicalDisclaimer(customMessage: "Your custom message")  // Custom message
```

### Adding New Screens

1. Create a new file in `lib/screens/`
2. Import the theme and widgets as needed
3. Use the Material 3 components from the theme

### Adding New Widgets

1. Create reusable widgets in `lib/widgets/`
2. Follow the existing widget patterns
3. Use theme colors and styles for consistency

## Dependencies

- `flutter`: Flutter SDK
- `cupertino_icons`: iOS-style icons

## License

This project is created for healthcare application development.
