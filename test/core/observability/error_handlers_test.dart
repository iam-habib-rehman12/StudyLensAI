import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/observability/error_handlers.dart';
import 'package:studylens_ai/core/observability/error_reporter.dart';

void main() {
  test('forwards framework and platform errors to the reporter', () {
    final reporter = _FakeReporter();
    final restore = installErrorHandlers(
      reporter,
      forwardToPrevious: false,
      useFriendlyWidget: false,
    );
    addTearDown(restore);

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('framework boom'),
        stack: StackTrace.current,
        library: 'test-library',
      ),
    );

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single.error, isA<StateError>());
    expect(reporter.errors.single.context, 'test-library');
    expect(reporter.errors.single.fatal, isFalse);

    final handled = PlatformDispatcher.instance.onError!(
      StateError('platform boom'),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(reporter.errors, hasLength(2));
    expect(reporter.errors.last.fatal, isTrue);
    expect(reporter.errors.last.context, 'Platform dispatcher error');
  });

  testWidgets('friendly error widget renders a safe fallback', (tester) async {
    await tester.pumpWidget(const FriendlyErrorWidget());

    expect(
      find.text('Something went wrong in this part of StudyLens.'),
      findsOneWidget,
    );
    expect(find.text('Go back and try again.'), findsOneWidget);
  });
}

class _ReportedError {
  const _ReportedError({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.fatal,
  });

  final Object error;
  final StackTrace stackTrace;
  final String? context;
  final bool fatal;
}

class _FakeReporter implements ErrorReporter {
  final List<_ReportedError> errors = [];

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    errors.add(
      _ReportedError(
        error: error,
        stackTrace: stackTrace,
        context: context,
        fatal: fatal,
      ),
    );
  }
}
