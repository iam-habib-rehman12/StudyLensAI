# Day 14 - Acceptance and Semester Demo

This checklist exercises the complete MVP path on an Android device with the
real Firebase project.

## Preconditions

- `flutter pub get`, `flutter analyze`, and `flutter test` pass.
- `npm ci && npm run test:rules` passes (Java 11+ for the emulator).
- `config/firebase.dev.json` contains the real project values.
- The App Check debug token for the test device is registered in Firebase
  Console, and Firebase AI Logic is enabled.
- Firestore rules from this repository are published.
- A release keystore is configured, or the local demo key described below is
  used for an internal build.

## Acceptance path

1. **Register / sign in**: create a fresh student account; confirm the profile
   and verification chip; sign out and back in.
2. **Password reset**: use Forgot password? and confirm the neutral confirmation.
3. **Text tutor**: ask a concept question, confirm streaming, a Markdown-rendered
   answer, and a follow-up that keeps context.
4. **Circuit image**: capture or select a circuit photo; try Simple and Detailed
   modes; ask a follow-up; confirm the image stays local.
5. **Lecture PDF**: choose a PDF up to 10 MB; run Summary, Important topics,
   Revision notes, and a custom question; confirm page limits are reported
   honestly.
6. **Quiz generation**: generate 5, 10, and 15-question quizzes at each
   difficulty; start a quiz, answer all questions, submit, review the score and
   XP, and retry a forced save failure.
7. **History and progress**: confirm the completed quiz and study sessions appear
   newest-first, and that questions, quizzes, sessions, accuracy, XP, and level
   update on Home, History, and Progress.
8. **Account deletion**: on a throwaway account, open Profile → Delete account,
   enter the password, and verify the Auth account and all `users/{uid}` data are
   gone.

## Security checks

- Run `npm run test:rules`: owner-only reads/writes and owner-only deletes.
- Sign in as a second account and confirm it cannot read the first account's
  profile, sessions, messages, quizzes, or results.
- Confirm App Check rejects an unregistered debug build.
- Confirm release builds fail with the signing guard when
  `android/key.properties` is missing.

## Release build

Use a real release keystore for distribution:

```powershell
flutter build apk --release
```

For an internal demo without store credentials, a locally generated demo key is
acceptable. It is ignored by Git and must never be used for a store submission:

```powershell
Copy-Item android/key.properties.example android/key.properties
keytool -genkeypair -v -keystore android/keystore/studylens-demo.jks `
  -alias studylens-demo -keyalg RSA -keysize 2048 -validity 10000 `
  -dname "CN=StudyLens Demo, OU=Demo, O=StudyLens, L=Demo, ST=Demo, C=US"
```

Fill in the matching passwords in `android/key.properties`, then build.

## Known constraints

- Device acceptance cannot run in CI; this checklist is the manual gate.
- Email verification is informative, not a hard access gate. The verified
  badge refreshes through **Profile → Refresh status**, which reloads the Auth
  user.
- Account deletion is client-side cleanup; a production deployment should move
  it to a server-side job for large histories.
- Profile aggregate fields remain derived from quiz results on the client.
