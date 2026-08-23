# StudyLens AI

StudyLens AI is an Android-first Flutter application that helps university
students learn from typed questions, photographs, and PDFs using multimodal AI.

> See it. Understand it. Master it.

The project is being delivered incrementally over 14 build-gated days. See
[the 14-day roadmap](docs/14_DAY_ROADMAP.md) for scope and status.

## Current status

Days 1-4 establish the Material 3 foundation, environment-safe Firebase and
App Check bootstrap, email/password authentication, and the responsive
five-tab authenticated application shell.

Day 5 adds validated student profile, study session, message, quiz, and result
models; user-scoped Firestore paths; repository contracts and implementations;
central timestamp/error translation; security rules; and repository tests. See
[the Firestore schema](docs/FIRESTORE_SCHEMA.md) for the persistent data shape.

Day 6 adds the real Firebase AI Logic tutor with centralized prompts/model
configuration, bounded conversational context, streamed answers, completed
message persistence, retry-safe failure handling, and Home/Study navigation.
See [AI Tutor setup and behavior](docs/AI_TUTOR.md).

Day 7 adds Android camera and gallery intake behind device-service and
controller boundaries, explicit permission and unavailable states,
interrupted-picker recovery, in-memory preview, retake, and discard. Images
remain local and Cloud Storage is still not required. See
[camera and gallery intake](docs/IMAGE_INTAKE.md).

The analyzer, automated tests, and Android debug APK build gates are passing.

Multimodal image learning is scheduled for Day 8. No fake AI or persisted study
data is used.

## Architecture

```text
lib/
  app.dart
  main.dart
  core/
    config/       App and AI configuration
    errors/       User-safe application failures
    routing/      Central route definitions
    theme/        Material 3 color and component themes
  features/
    <feature>/
      presentation/
      application/
      domain/
      data/
  shared/
    widgets/
```

Dependency direction:

```text
UI -> Controller/Provider -> Repository -> Service -> Firebase/Gemini/Device
```

UI widgets must not invoke Firebase, Gemini, Firestore, camera, document, or
storage APIs directly.

## Run

Requirements:

- Flutter SDK compatible with Dart `^3.12.2`
- Android SDK/toolchain

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

To connect a Firebase project, follow [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).
Do not commit service-account keys or private server credentials to this client.
