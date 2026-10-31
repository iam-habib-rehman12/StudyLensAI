# Firebase Setup

StudyLens reads Firebase client configuration from compile-time Dart defines.
No project-specific configuration, service-account credential, App Check debug
token, or password belongs in source control.

## 1. Create and register the Android app

1. Create a Firebase project.
2. Register an Android application with package name
   `com.studylens.studylens_ai`.
3. In Authentication, enable Email/Password. The verification and password
   reset flows use Firebase's email templates; customize the sender and copy in
   Firebase Console before the demo.
4. Create a Cloud Firestore database and publish `firestore.rules`. The rules
   allow authenticated students to create and read only their own validated
   profile, sessions, messages, quizzes, and results. All other paths are
   denied.
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

## 7. Release signing

Debug builds use the debug keystore automatically. Release builds require a
real keystore and fail with an explicit Gradle message while it is missing.

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Create the keystore (keep it outside source control):

```powershell
keytool -genkeypair -v -keystore android/keystore/studylens-release.jks `
  -alias studylens -keyalg RSA -keysize 2048 -validity 10000
```

3. Fill in `storePassword`, `keyAlias`, and `keyPassword` in
   `android/key.properties`.
4. Register the release signing certificate SHA-256 in Firebase Console for
   App Check Play Integrity.

`android/key.properties`, `*.jks`, and `*.keystore` are ignored by Git.

## 8. Firestore rules tests

The rules are exercised against the Firestore emulator with the Firebase Rules
Unit Testing SDK. Java 11+ is required for the emulator.

```powershell
npm ci
npm run test:rules
```

The first run downloads a ~130 MB Firestore emulator JAR. If the download
stalls and the CLI reports `An unexpected error has occurred`, the host is not
necessarily blocked; the single connection may just be very slow. Download the
JAR with a download manager or `curl`, verify its MD5, and place it in the
emulator cache:

```text
URL:  https://storage.googleapis.com/firebase-preview-drop/emulator/cloud-firestore-emulator-v1.22.0.jar
MD5:  5d74cc6bee9e18560d2eae2c6440fd13
Size: 136707194 bytes

%USERPROFILE%\.cache\firebase\emulators\cloud-firestore-emulator-v1.22.0.jar
```

Version, URL, size, and checksum for other versions are in
`node_modules/firebase-tools/lib/emulator/downloadableEmulatorInfo.json`.

## 9. Build gate

Run after configuration or SDK changes:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
