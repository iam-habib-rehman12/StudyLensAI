# StudyLens AI - 14-Day MVP Roadmap

This roadmap converts the Project Specification Document into small,
build-gated increments. Every day ends with `flutter analyze`, `flutter test`,
and an Android build check when native integration changes.

## Acceptance path

User -> Login -> Home -> Scan/upload learning material -> Ask StudyLens ->
Receive a contextual explanation -> Generate quiz -> Complete quiz -> Receive
score -> View saved progress.

## Daily plan

### Day 1 - Foundation (complete)

- Create the Android-first Flutter project.
- Establish feature-based folders and dependency direction.
- Establish centralized Flutter routing and Listenable-based controller state.
- Create centralized app, AI, error, color, and Material 3 theme configuration.
- Add a responsive StudyLens foundation screen and smoke test.
- Record the delivery plan and verify analyzer/test baselines.
- Repair the local Android NDK installation before closing the APK build gate.

### Day 2 - Firebase platform setup (complete)

- Add Firebase Core, Authentication, Firestore, and App Check packages.
- Add environment-safe Firebase initialization and configuration guidance.
- Enable App Check debug architecture for development.
- Define emulator-friendly service providers and bootstrap failure states.

### Day 3 - Authentication (complete)

- Implement auth service, repository, controller, and explicit auth states.
- Build splash/auth gate, login, registration, validation, and logout.
- Create the Firestore user record after successful registration.
- Test success, validation, wrong-password, and failure flows.

### Day 4 - Application shell and Home (complete)

- Build the five-tab Material 3 shell: Home, Study, History, Progress, Profile.
- Build the PSD Home dashboard and reusable action cards.
- Connect real authenticated user data; do not add mock persistence.
- Add loading, empty, and error surfaces used by later features.

### Day 5 - Firestore domain and persistence (complete)

- Add typed user, study session, message, quiz, and result models.
- Implement user-scoped Firestore paths and repository contracts.
- Add security rules and emulator-oriented repository tests.
- Keep Cloud Storage absent from the core dependency path.

### Day 6 - AI Tutor (complete)

- Add Firebase AI Logic behind an `AiService` and tutor repository.
- Centralize model settings, system behavior, and prompt templates.
- Build text chat, recent-context limits, streaming, and failure handling.
- Persist completed messages without exposing SDK calls to widgets.

### Day 7 - Camera and gallery intake (complete)

- Implement camera/gallery device services and Android permissions.
- Handle granted, denied, permanently denied, and unavailable states.
- Build capture, preview, retake, and local-only material lifecycle.

### Day 8 - Multimodal image learning (complete)

- Attach image bytes plus questions through the AI service.
- Add explanation-mode and prompt chips from the PSD.
- Preserve image context for safe follow-up questions.
- Add offline, empty, rate-limit, and AI failure tests.

### Day 9 - PDF intelligence (complete)

- Add local PDF selection, type/size validation, and document context.
- Implement summary, important topics, revision notes, and document Q&A.
- Keep PDF bytes ephemeral unless optional Storage is enabled later.
- Handle unsupported, malformed, oversized, and unreadable documents.

### Day 10 - Structured quiz generation (complete)

- Implement immutable quiz/question domain models.
- Define Firebase AI JSON schema and centralized quiz prompt.
- Validate question count, non-empty text, four options, correct index,
  explanations, and duplicate questions before presentation.
- Surface malformed-response errors with recovery actions.

### Day 11 - Quiz player and results (complete)

- Build quiz setup, question navigation, progress, and submission.
- Implement deterministic scoring and mistake review.
- Persist completed results and XP only after successful completion.
- Test navigation, score calculation, retry, and persistence failures.

### Day 12 - History and progress (complete)

- Build real Firestore-backed study history and quiz history.
- Calculate questions, quizzes, sessions, accuracy, XP, and level.
- Add useful loading, empty, offline, and error states.

### Day 13 - Reliability and visual polish (complete)

- Complete light/dark themes, responsive behavior, and accessibility.
- Prevent duplicate submissions and normalize user-facing exceptions.
- Add retry behavior, connectivity cues, and polished loading feedback.
- Run the complete unit/widget/integration test suite.

### Day 14 - Acceptance and semester demo (in progress)

- Exercise the full MVP acceptance path on Android.
- Test circuit-image, lecture-PDF, and generated-quiz demo scenarios.
- Verify Firestore security boundaries and App Check configuration.
- Produce a release APK and finalize setup/demo documentation.

Code, rules, release signing, and the acceptance checklist are complete. The
final on-device walkthrough remains a manual gate; see
[docs/ACCEPTANCE.md](ACCEPTANCE.md).

## Architecture rule

Dependencies flow inward as follows:

`presentation -> controller/provider -> repository -> service -> SDK/device API`

Widgets never call Firebase, Gemini, Firestore, camera, document picker, or
storage APIs directly. Optional Cloud Storage must remain replaceable and must
not be required for the MVP demo.
