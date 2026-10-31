import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'error_reporter.dart';

typedef ErrorHandlerRestore = void Function();

/// Installs framework and platform error handlers.
///
/// Returns a restore callback used by tests; application code can ignore it.
ErrorHandlerRestore installErrorHandlers(
  ErrorReporter reporter, {
  bool forwardToPrevious = true,
  bool useFriendlyWidget = true,
}) {
  final previousFlutterError = FlutterError.onError;
  final previousPlatformError = PlatformDispatcher.instance.onError;
  final previousErrorWidget = ErrorWidget.builder;

  FlutterError.onError = (details) {
    reporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      context:
          details.context?.toDescription() ??
          details.library ??
          'Flutter framework error',
    );
    if (forwardToPrevious) previousFlutterError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    reporter.report(
      error,
      stackTrace,
      context: 'Platform dispatcher error',
      fatal: true,
    );
    return true;
  };

  if (useFriendlyWidget && kReleaseMode) {
    ErrorWidget.builder = (details) => const FriendlyErrorWidget();
  }

  return () {
    FlutterError.onError = previousFlutterError;
    PlatformDispatcher.instance.onError = previousPlatformError;
    ErrorWidget.builder = previousErrorWidget;
  };
}

/// Safe fallback shown in release builds when a subtree fails to build.
class FriendlyErrorWidget extends StatelessWidget {
  const FriendlyErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFF7F7FC),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFF5356CF),
                ),
                SizedBox(height: 14),
                Text(
                  'Something went wrong in this part of StudyLens.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1C1B1F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Go back and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF5F5E66)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
