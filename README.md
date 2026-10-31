# StudyLens AI

StudyLens AI is an Android-first Flutter application that helps university
students learn from typed questions, photographs, and PDFs using multimodal AI.

> See it. Understand it. Master it.

The project is being delivered incrementally over 14 build-gated days. See
[the 14-day roadmap](docs/14_DAY_ROADMAP.md) for scope and status.


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

Firestore security-rule tests require Node 20+ and Java 11+:

```sh
npm ci
npm run test:rules
```

To connect a Firebase project, follow [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).
Do not commit service-account keys or private server credentials to this client.
