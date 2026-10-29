import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/history/presentation/history_screen.dart';
import 'package:studylens_ai/features/progress/application/study_overview_controller.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';

import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_result_repository.dart';
import '../../helpers/overview_fixtures.dart';

void main() {
  testWidgets('renders saved sessions and quiz results', (tester) async {
    final controller = _controller(
      sessions: [buildOverviewSession()],
      quizzes: [buildOverviewQuiz()],
      results: [buildOverviewResult()],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(overview: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Study history'), findsOneWidget);
    expect(find.text('Cell biology notes'), findsOneWidget);
    expect(find.text('Cell Biology Review'), findsOneWidget);
    expect(find.textContaining('1/2 correct'), findsOneWidget);
  });

  testWidgets('shows a loading state until the streams emit', (tester) async {
    final sessions = StreamController<List<StudySession>>();
    final quizzes = StreamController<List<Quiz>>();
    final results = StreamController<List<QuizResult>>();
    final controller = StudyOverviewController(
      'user-1',
      FakeStudySessionRepository(stream: sessions.stream),
      FakeQuizRepository(stream: quizzes.stream),
      FakeQuizResultRepository(stream: results.stream),
      now: () => DateTime.utc(2026, 8, 25, 12),
    );
    addTearDown(() async {
      controller.dispose();
      await sessions.close();
      await quizzes.close();
      await results.close();
    });

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(overview: controller)),
    );
    await tester.pump();

    expect(find.text('Loading your study history...'), findsOneWidget);
  });

  testWidgets('shows a failure and retries the streams', (tester) async {
    final sessions = FakeStudySessionRepository(
      error: const AppException(
        type: AppErrorType.offline,
        message: 'You are offline.',
      ),
    );
    final controller = StudyOverviewController(
      'user-1',
      sessions,
      FakeQuizRepository(),
      FakeQuizResultRepository(),
      now: () => DateTime.utc(2026, 8, 25, 12),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(overview: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are offline.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    sessions
      ..error = null
      ..sessions = [buildOverviewSession()];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Cell biology notes'), findsOneWidget);
  });
}

StudyOverviewController _controller({
  required List<StudySession> sessions,
  required List<Quiz> quizzes,
  required List<QuizResult> results,
}) {
  return StudyOverviewController(
    'user-1',
    FakeStudySessionRepository(sessions: sessions),
    FakeQuizRepository(quizzes: quizzes),
    FakeQuizResultRepository(results: results),
    now: () => DateTime.utc(2026, 8, 25, 12),
  );
}
