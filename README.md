



https://github.com/user-attachments/assets/f22426d1-f586-424d-a83d-ac820f3c6f55

# Medora – Healthcare Flutter App

A Flutter-based Android application built as part of the Inter-IIIT Hackathon, designed to act as the primary clinician-facing interface for a RAG-powered clinical decision support system.
The app focuses on low-latency processing of long, messy, and unstructured clinical notes and presents evidence-backed diagnostic summaries using a clean Material 3 healthcare UI.

## Features

RAG-Powered Diagnostic Summaries
Integrates with a Retrieval-Augmented Generation (RAG) backend to generate evidence-based differential diagnoses grounded in retrieved medical knowledge.

Low-Latency Inference
Optimized interaction from clinical note submission to diagnostic output, suitable for real-time clinical workflows.

Material 3 Design
Modern Flutter UI following Material 3 guidelines.

Healthcare Theme
Custom teal/blue color palette optimized for healthcare applications.

Clinical Note Handling
Designed to support long and unstructured clinical notes, including text derived from scanned images and PDFs via the backend OCR pipeline.

Reusable Components
Well-structured widget library for easy reuse and scalability.

Clean Architecture
Organized folder structure with clear separation of concerns.

Global Medical Disclaimer
Reusable medical disclaimer widget for app-wide use in AI-assisted healthcare contexts.

Dark Mode Support
Full dark theme support with healthcare-appropriate colors and contrast.

## Project Structure
```
lib/
├── main.dart                   # App entry point
├── theme/
│   └── app_theme.dart           # App-wide Material 3 theme configuration
├── screens/
│   └── home_screen.dart         # Primary screen scaffold
├── widgets/
│   ├── medical_disclaimer.dart  # Global medical disclaimer widget
│   └── health_card.dart         # Reusable UI component
├── models/
│   ├── health_record.dart       # Health record data model
│   └── appointment.dart         # Appointment / visit model
└── services/
    └── health_service.dart      # Service layer for app–backend interaction
```
## Getting Started
Prerequisites

Flutter SDK (3.0.0 or higher)

Dart SDK (3.0.0 or higher)

Android Studio or VS Code with Flutter extensions

## Installation

Clone the repository

Run flutter pub get to install dependencies

Run flutter run to start the app
