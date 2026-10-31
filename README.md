# StudyLens AI

StudyLens AI is an Android-first Flutter application that helps university
students learn from typed questions, photographs, and PDFs using multimodal AI.

> See it. Understand it. Master it.

The project is being delivered incrementally over 14 build-gated days. See
[the 14-day roadmap](docs/14_DAY_ROADMAP.md) for scope and status.

## Highlights

- Multimodal AI tutor: typed questions, camera/gallery images, and PDFs through
  Firebase AI Logic, with streamed answers and bounded conversational context
- Schema-constrained quiz generation with strict domain validation and
  deterministic scoring with XP and mistake review
- Real Firestore persistence for conversations, quizzes, results, history, and
  derived progress metrics - no fake AI or mock study data
- Feature-based clean architecture: widgets never call Firebase, Gemini,
  Firestore, camera, or document APIs directly
- 42 test files (unit, widget, integration) plus Firestore security-rule tests,
  enforced as CI gates
- Explicit loading, empty, offline, error, and permission states with recovery
  actions, light/dark themes, and accessibility labels

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

Day 8 adds real multimodal image questions through Firebase AI Logic,
Simple/Normal/Detailed/Exam modes, PSD prompt chips, retry-safe contextual
follow-ups, and Firestore persistence of text conversations while image bytes
remain ephemeral. See [multimodal image learning](docs/IMAGE_ANALYSIS.md).

Day 9 adds validated local PDF selection, inline Gemini document analysis,
summary/topics/revision actions, contextual Q&A, and saved conversations. PDF
bytes remain ephemeral, so Cloud Storage is still optional. No fake AI or fake
persisted study data is used. See [PDF intelligence](docs/PDF_INTELLIGENCE.md).

Day 10 adds Firebase AI schema-constrained quiz generation from a topic or
study notes, strict JSON/domain validation, retry-safe Firestore saving, and a
validated quiz preview. See
[structured quiz generation](docs/QUIZ_GENERATION.md).

Day 11 adds the quiz player: question navigation, required-answer validation,
deterministic scoring with XP, result persistence, save retry without
duplication, and a per-question answer review. Each result stores its earned
XP. See [the quiz player](docs/QUIZ_PLAYER.md).

Day 12 wires real Firestore-backed study history and progress. Home, History,
and Progress share one live overview: sessions and completed quiz results are
listed newest-first, while questions, quizzes, accuracy, XP, level, and today's
metrics are derived from saved results. Loading, empty, offline, and error
states all have recovery actions. See
[history and progress](docs/HISTORY_AND_PROGRESS.md).

Day 13 adds reliability and polish: safe Markdown rendering for AI answers,
a lower 10 MB PDF ceiling, picker timeouts and interruption recovery, thumbnail
decoding, semantic labels, adaptive large-text layouts, and a large-text
regression test. See
[reliability and polish](docs/RELIABILITY_AND_POLISH.md).

Day 14 completes the account lifecycle: verification emails, password reset,
and password-confirmed account deletion with Firestore cleanup under
owner-only delete rules. It also adds the device acceptance checklist and
release-signing path. See
[account lifecycle](docs/ACCOUNT_LIFECYCLE.md) and
[acceptance](docs/ACCEPTANCE.md).

A dependency-free observability layer reports uncaught framework, platform, and
asynchronous errors through a pluggable `ErrorReporter`; the default logger
writes to the platform log and release builds show a safe fallback widget. See
[observability](docs/OBSERVABILITY.md).

For the complete AI-enabled app on a physical phone, including App Check debug
token registration and the demo release APK, see
[Android phone setup](docs/ANDROID_DEVICE_SETUP.md).

The analyzer, automated tests, Android debug APK build, and Firestore security
rules tests are configured as gates.

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

## Documentation

- [14-day roadmap](docs/14_DAY_ROADMAP.md) - scope, status, and acceptance path
- [Firebase setup](docs/FIREBASE_SETUP.md) - connect a Firebase project
- [Firestore schema](docs/FIRESTORE_SCHEMA.md) - persistent data shape
- [AI tutor](docs/AI_TUTOR.md) - prompts, streaming, and failure handling
- [Image intake](docs/IMAGE_INTAKE.md) and [image analysis](docs/IMAGE_ANALYSIS.md)
- [PDF intelligence](docs/PDF_INTELLIGENCE.md)
- [Quiz generation](docs/QUIZ_GENERATION.md) and [quiz player](docs/QUIZ_PLAYER.md)
- [History and progress](docs/HISTORY_AND_PROGRESS.md)
- [Reliability and polish](docs/RELIABILITY_AND_POLISH.md)

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

## License

Released under the [MIT License](LICENSE).
