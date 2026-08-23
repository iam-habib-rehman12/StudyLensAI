# Camera and Gallery Intake

Day 7 implements the local image acquisition workflow:

```text
Home or Study -> Scan & Learn -> camera/gallery -> preview -> retake/discard
```

Image-to-AI analysis is intentionally deferred to Day 8. Day 7 does not call
Gemini and does not persist an image remotely.

## Architecture

```text
ScanScreen
  -> ScanController
    -> ImageIntakeService
      -> DeviceImageIntakeService
        -> image_picker / permission_handler / Android
```

Widgets receive an in-memory `StudyImage`; they never call camera, gallery, or
permission plugins. The device service limits the selected image to 2400 pixels
on either side, uses a 12 MB validation limit, and reads the result into memory.
Closing the route disposes the controller and its image reference.

## Reliability behavior

- Camera permission is checked and requested before capture.
- Denied, permanently denied, unavailable, invalid, oversized, cancelled, and
  unexpected outcomes are represented explicitly.
- Permanent denial offers a path to Android app settings.
- Android interrupted-selection recovery uses `retrieveLostData()`.
- Cancelling a retake preserves the existing preview.
- Duplicate source requests are blocked while an operation is active.
- Gallery selection uses Android's picker and does not request broad storage
  access.
- Cloud Storage is not installed or required.

## Manual Android test

Run the app with the existing Firebase development configuration:

```powershell
flutter run --dart-define-from-file=config/firebase.dev.json
```

1. Sign in and tap **Scan & Learn** from Home.
2. Tap **Open camera**, allow Camera, photograph a clear page, and accept it.
3. Confirm the preview can be zoomed and displays its source and size.
4. Tap **Retake photo**, capture another image, and confirm it replaces the
   preview.
5. Discard it, choose an image from the gallery, and confirm the new preview.
6. In Android settings, deny Camera and verify the explanatory state.
7. Select **Don't ask again** if available and verify the **Settings** action.

Do not enable Cloud Storage for this test. Image analysis and contextual image
questions are the Day 8 milestone.
