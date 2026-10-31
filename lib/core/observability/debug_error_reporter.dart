import 'dart:developer';

import 'error_reporter.dart';

/// Local reporter used until a remote sink (Crashlytics, Sentry, etc.) is
/// configured. Errors are written to the platform log with their stack trace.
class DebugErrorReporter implements ErrorReporter {
  const DebugErrorReporter();

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    log(
      context ?? 'Unhandled StudyLens error',
      name: 'studylens.error',
      error: error,
      stackTrace: stackTrace,
      level: fatal ? 1200 : 1000,
    );
  }
}
