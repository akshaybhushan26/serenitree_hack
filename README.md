# SereniTree 🌳

A comprehensive mental health and medication management application built with Flutter, designed to provide a holistic approach to mental wellness.

## Features 🌟

- **Authentication System**: Secure user authentication and data privacy
- **Medication Management**:
  - Track medications and dosages
  - Set reminders
  - Scan medication labels using ML Kit
  - Drug interaction checker
- **Mood Tracking**:
  - Daily mood logging
  - Visual mood trends with graphs
  - Historical mood data analysis
- **Therapy Features**:
  - Guided meditation sessions
  - Nature-based relaxation backgrounds
  - Audio therapy sessions
- **AI-Powered Chatbot**: Supportive conversations and guidance
- **Camera Integration**: Scan medications and prescriptions

## Tech Stack 🛠️

### Core
- **Framework**: Flutter (SDK >=3.2.3)
- **State Management**: Provider
- **Local Storage**: Hive Database
- **API Communication**: HTTP package

### Key Dependencies
- **ML & Vision**:
  - `google_mlkit_text_recognition`: Text recognition from images
  - `camera`: Camera functionality
  - `image_picker`: Image selection

- **UI/UX**:
  - `fl_chart`: Beautiful charts for mood tracking
  - `flutter_animate`: Smooth animations
  - `animations`: Material Design animations

- **Audio**:
  - `just_audio`: Audio playback
  - `audio_session`: Audio session management

### Development Tools
- `build_runner`: Code generation
- `json_serializable`: JSON serialization
- `hive_generator`: Hive database model generation

## Platform Support 📱

- iOS
- Android
- Web
- macOS
- Windows
- Linux

## Getting Started 🚀

1. Ensure you have Flutter installed (>=3.2.3)
2. Clone the repository
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run code generation:
   ```bash
   flutter pub run build_runner build
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Architecture 🏗️

The project follows a clean architecture pattern with:
- `lib/screens`: UI screens
- `lib/widgets`: Reusable widgets
- `lib/providers`: State management
- `lib/models`: Data models
- `lib/services`: Business logic and external services
- `lib/data`: Local data management

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.
