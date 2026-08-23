# AI Tutor

Day 6 implements the first real StudyLens learning workflow:

```text
Authenticated student -> Ask StudyLens -> save question -> stream explanation
-> save completed answer -> continue with recent context
```

## Architecture

```text
TutorScreen
  -> TutorController
    -> TutorRepository
      -> AiService -> Firebase AI Logic / Gemini
      -> StudySessionRepository -> Firestore
      -> StudyMessageRepository -> Firestore
```

Widgets never access Firebase or Gemini SDKs. Firebase-specific content and
error types are translated inside `FirebaseAiService` and the document database
service.

## Reliability behavior

- Questions are trimmed, length-limited, and persisted before an AI request.
- Only the most recent complete conversation turns are sent as context.
- Streamed text is visible immediately but is persisted only after completion.
- Empty or blocked responses are rejected instead of saved.
- Duplicate submissions are disabled while saving or streaming.
- Retrying an AI failure does not persist the student question twice.
- Retrying a Firestore failure does not make a second Gemini request.
- Offline, permission/App Check, quota, configuration, safety, malformed, and
  unknown failures use separate user-safe messages.
- Prompts and model configuration are centralized.

## Firebase Console requirement

Enable **AI Services > AI Logic** using the Gemini Developer API provider. New
AI Logic onboarding enforces App Check for the service, so register the debug
token printed by the Android debug build before testing on a physical phone.

The current stable semester configuration uses `gemini-2.5-flash`. Change the
model only in `AiConfig` after verifying availability and rerunning the full
quality gate.

## Manual test

```powershell
flutter run --dart-define-from-file=config/firebase.dev.json
```

1. Sign in and open **Ask StudyLens AI** from Home or **AI Tutor** from Study.
2. Ask: `Explain photosynthesis step by step.`
3. Confirm text appears progressively and the composer is disabled while busy.
4. Ask a follow-up such as `Why is chlorophyll important in that process?`
5. Confirm Firestore contains one session and alternating student/assistant
   messages below `users/{uid}/sessions/{sessionId}/messages`.
6. Disable connectivity and confirm a retryable, user-safe error appears.
