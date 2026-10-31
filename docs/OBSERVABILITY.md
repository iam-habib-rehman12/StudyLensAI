# Observability

StudyLens installs global error handlers before starting the app:

- `FlutterError.onError` reports framework/build errors and still forwards to
  the default handler for debug diagnostics.
- `PlatformDispatcher.instance.onError` reports uncaught platform errors.
- `runZonedGuarded` reports uncaught asynchronous errors.
- Release builds replace the red error widget with a safe, user-facing fallback.

## Reporter seam

`ErrorReporter` is the boundary between the app and a remote sink.
`DebugErrorReporter` writes to `dart:developer` under `studylens.error` with the
stack trace and a fatal flag.

To add Crashlytics or Sentry, implement `ErrorReporter` and pass it to
`installErrorHandlers` in `main.dart`; no feature code needs to change.

```text
Flutter framework error ─┐
Platform dispatcher error ├─> ErrorReporter ─> local log / Crashlytics / Sentry
Uncaught zone error ──────┘
```

## Privacy

The reporter receives the error object, stack trace, and a short context label.
Feature-level user-safe messages are not re-reported, avoiding duplicate noise.
Do not attach user content, prompts, PDFs, or image bytes to reports.

## Current limitations

- No remote sink is configured yet; `DebugErrorReporter` is the default.
- Enabling Crashlytics requires the Google Services/Crashlytics Gradle setup and
  a Firebase app configuration.
- The friendly fallback is release-only so debug builds keep the red error
  screen.
