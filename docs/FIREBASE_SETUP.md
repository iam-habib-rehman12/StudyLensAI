# Firebase Setup

StudyLens reads Firebase client configuration from compile-time Dart defines.
No project-specific configuration, service-account credential, App Check debug
token, or password belongs in source control.

## 1. Create and register the Android app

1. Create a Firebase project.
2. Register an Android application with package name
   `com.studylens.studylens_ai`.
3. In Authentication, enable Email/Password. Authentication UI is scheduled
   for Day 3.
4. Create a Cloud Firestore database. The repository allows authenticated
   students to create/read only their own validated user profile. Feature
   subcollections remain closed until their persistence milestone.
5. In App Check, register the Android application with Play Integrity. Do not
   manually enforce Authentication or Firestore during initial setup. Firebase
   AI Logic onboarding may enforce App Check for its own API, so register the
   development phone's debug token before testing AI.

Cloud Storage is not required. Leave `FIREBASE_STORAGE_BUCKET` empty if the
project does not use Storage.

## 2. Create a local configuration file

Copy `config/firebase.example.json` to `config/firebase.dev.json` and replace
the required values using Firebase Console > Project settings > General.
Local `firebase.*.json` files are ignored by Git except for the example.

Required values:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`

Optional values:

- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_AUTH_DOMAIN`

These are Firebase client identifiers, not server credentials. Never place a
service-account JSON file or private server key in the Flutter application.

## 3. Run the application

```powershell
flutter run --dart-define-from-file=config/firebase.dev.json
```

Without the required values, StudyLens intentionally displays a Firebase setup
screen instead of attempting partially configured Firebase requests.

## 4. App Check

- Debug builds use `AndroidDebugProvider`.
- Profile/release builds use `AndroidPlayIntegrityProvider`.
- On the first debug run, copy the App Check debug token from Logcat into
  Firebase Console > App Check > Manage debug tokens.
- Never commit or distribute the debug token.
- Enable enforcement only after monitoring confirms legitimate traffic is
  receiving valid tokens.

## 5. Enable Firebase AI Logic

1. Open Firebase Console > AI Services > AI Logic.
2. Select **Get started**.
3. Choose the **Gemini Developer API** provider for the semester MVP.
4. Complete the guided API setup.
5. Confirm the Android App Check debug token is registered for the development
   phone. AI Logic setup enforces App Check for new projects, so an unregistered
   debug build will be rejected even if Authentication and Firestore work.

StudyLens uses the official `firebase_ai` Flutter plugin and does not store a
separate Gemini API key. The model, limits, and system behavior are centralized
in `lib/core/config/ai_config.dart` and `lib/core/config/ai_prompts.dart`.

After setup, allow several minutes for newly enabled APIs to propagate. Run the
app, sign in, open **Ask StudyLens**, and submit a simple course question.

## 6. Optional local emulators

Set these values in the local configuration file:

```json
{
  "USE_FIREBASE_EMULATORS": true,
  "FIREBASE_EMULATOR_HOST": "10.0.2.2"
}
```

`10.0.2.2` reaches the host machine from the standard Android emulator. Use the
development computer's LAN address for a physical device. StudyLens routes Auth
to port `9099` and Firestore to port `8080` when emulator mode is enabled.

## 7. Build gate

Run after configuration or SDK changes:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
