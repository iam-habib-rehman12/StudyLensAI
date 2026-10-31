# Android Phone Setup

This is the reliable path to run the complete app, including AI features, on a
physical Android phone without publishing to the Play Store.

## Choose the APK

All APKs are in `build/app/outputs/flutter-apk/` and were built with
`config/firebase.dev.json`.

| APK | Use |
| --- | --- |
| `studylens-demo-release.apk` | **Recommended for phone testing.** Release build with the App Check debug provider. |
| `app-debug.apk` | Debug build; also uses the App Check debug provider, but larger. |
| `studylens-play-release.apk` | Play Integrity build for production; requires a real keystore, registered SHA-256, and Play distribution. |

The demo release APK is signed with the local demo key. It is for testing only;
do not publish it.

## 1. Enable Firebase services

In Firebase Console for the project used by `config/firebase.dev.json`:

- **Authentication** → Sign-in method → enable **Email/Password**.
- **Firestore Database** → create the database if needed.
- **AI Services** → **AI Logic** → Get started with the **Gemini Developer API**.
- **App Check** → register the Android app with Play Integrity (production) and
  add the debug token from step 3 below.

Publish the repository rules in Firestore → Rules, or:

```powershell
firebase deploy --only firestore:rules
```

## 2. Install the APK

### Option A — Wireless debugging (no cable, Android 11+)

1. Connect the phone and computer to the **same Wi-Fi network** (not a guest
   network). Turn off VPNs.
2. On the phone: Settings → About phone → tap **Build number** 7 times.
3. Settings → System → Developer options → enable **Wireless debugging**.
4. Tap **Pair device with pairing code**. Note the `IP:port` and 6-digit code.
5. On the computer, use the full adb path if `adb` is not on PATH:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb pair 192.168.1.23:37105 123456
```

6. After pairing, go back to the **Wireless debugging** screen and note the
   **IP address & Port** (this port differs from the pairing port).
7. Connect and install:

```powershell
& $adb connect 192.168.1.23:41234
& $adb devices
& $adb install -r "build\app\outputs\flutter-apk\studylens-demo-release.apk"
```

If Windows prompts, allow adb on **Private** networks. If `adb devices` shows
`offline`, `& $adb disconnect`, toggle Wireless debugging, and connect again.
Re-check the current port after every toggle or reboot.

### Option B — USB debugging

Enable USB debugging, connect the cable, then:

```powershell
adb devices
adb install -r build\app\outputs\flutter-apk\studylens-demo-release.apk
```

### Option C — Manual install

Copy the APK to the phone via Google Drive, email, or a file-sharing app. Open
it in Files and allow “Install unknown apps” for that file manager. This works
without adb and is the fallback for Android 10 or older.

Package name: `com.studylens.studylens_ai`.

The demo release APK signing fingerprint is:

```text
SHA-256: 234c5534f2b2b0c9b74052eb2cdcc3dcb3f6b3f7d7ecc6c689ad2cbfb41d2557
```

Add it in Firebase Console → **Project settings** → **Your apps** → Android app
→ **Add fingerprint**. This matters if the project's Android API key has app or
SHA restrictions; it also makes the demo build recognizable to Firebase.

If an older debug/release build is installed and the signature differs:

```powershell
adb uninstall com.studylens.studylens_ai
adb install -r build\app\outputs\flutter-apk\studylens-demo-release.apk
```

## 3. Get the App Check debug token

The prebuilt demo APK is compiled with a **preset** App Check debug token, so
you do not need logcat. Use the token supplied with the build handoff and
register it in step 4.

If you rebuild a demo APK without a preset token, the phone generates one.
Capture it over adb:

```powershell
adb logcat -c
adb logcat | Select-String -Pattern "DebugAppCheckProvider|debug token|App Check"
```

The token is a UUID. If it is not shown, clear app data and relaunch:

```powershell
adb shell pm clear com.studylens.studylens_ai
```

You can also watch Logcat in Android Studio with the `DebugAppCheckProvider`
filter.

To build with your own preset token:

```powershell
flutter build apk --release `
  --dart-define-from-file=config/firebase.dev.json `
  --dart-define=APP_CHECK_DEBUG=true `
  --dart-define=APP_CHECK_DEBUG_TOKEN=your-uuid-here
```

## 4. Register the debug token

Firebase Console → **App Check** → **Apps** → the Android app →
**Manage debug tokens** → **Add debug token**.

Give it a name such as “Habib phone” and paste the UUID. Keep the token private.

Without this step, Firebase AI Logic can reject AI requests even though the app
itself starts.

The prebuilt demo APK uses a fixed preset token, so reinstalling it does not
change the token. A build without a preset token generates a per-installation
token; uninstalling or clearing app data then creates a new one that must be
registered again.

If the token does not appear in logcat, enable the provider tag and relaunch:

```powershell
adb shell setprop log.tag.DebugAppCheckProvider VERBOSE
adb logcat -c
adb logcat | Select-String -Pattern "DebugAppCheckProvider|debug token"
```

## 5. Restart and verify

Force-stop and reopen the app, then:

1. Create an account or sign in.
2. Open **Ask StudyLens** and ask a question.
3. Open **Scan & Learn**, allow camera access, and analyze an image.
4. Open **Ask PDF**, select a PDF up to 10 MB, and run a summary.
5. Generate a quiz, complete it, and confirm History/Progress update.
6. Optional: verify your email and use **Profile → Refresh status**.

## Phone requirements

- Android 7.0 or newer with Google Play services and internet access.
- Automatic date and time enabled (Firebase Auth tokens require a correct clock).
- The project used by the APK is `studylens-9d952` (from
  `config/firebase.dev.json`). Configure that same project in Firebase Console.
- Camera permission for live capture; gallery uses the system picker.
- JPEG/PNG/WebP images up to 12 MB.
- PDFs up to 10 MB.
- Cloud Storage is not required.

## Production release

Use a real keystore (not the demo key), register its SHA-256 fingerprint in
Firebase Project settings, and build without the demo App Check flag:

```powershell
flutter build apk --release --dart-define-from-file=config/firebase.dev.json
```

That build uses Play Integrity. For reliable AI on a production build, distribute
through Play internal testing or production and wait for the Play Integrity
registration to propagate.

Never ship a build with `--dart-define=APP_CHECK_DEBUG=true`: the debug provider
can be spoofed and is intended only for local/device testing.

## Troubleshooting

**“Firebase configuration required”** — the APK was built without
`--dart-define-from-file=config/firebase.dev.json`. Use the provided APKs.

**“StudyLens could not connect to Firebase”** — check internet and project
settings. App Check failures are now non-fatal; the underlying bootstrap error is
logged:

```powershell
adb logcat | Select-String -Pattern "studylens.bootstrap"
```

**AI request rejected / permission denied** — the debug token is not registered,
AI Logic is not enabled, or App Check enforcement is still propagating. Register
the token and relaunch.

**Firestore permission denied** — publish `firestore.rules` to the same project
used by the APK.

**Install fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`** — uninstall the
previous package first; debug and demo-release APKs use different signatures.
