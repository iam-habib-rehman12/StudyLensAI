import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/progress/application/study_overview_controller.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';

import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_result_repository.dart';
import '../../helpers/overview_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 25, 12);

  test('waits for all three streams before reporting ready', () async {
    final sessions = StreamController<List<StudySession>>();
    final quizzes = StreamController<List<Quiz>>();
    final results = StreamController<List<QuizResult>>();
    final controller = StudyOverviewController(
      'user-1',
      FakeStudySessionRepository(stream: sessions.stream),
      FakeQuizRepository(stream: quizzes.stream),
      FakeQuizResultRepository(stream: results.stream),
      now: () => now,
    );
    addTearDown(() async {
      controller.dispose();
      await sessions.close();
      await quizzes.close();
      await results.close();
    });

    expect(controller.state.isLoading, isTrue);

    sessions.add([buildOverviewSession()]);
    quizzes.add([buildOverviewQuiz()]);
    await pumpEventQueue();
    expect(controller.state.isLoading, isTrue);

    results.add([buildOverviewResult()]);
    await pumpEventQueue();

    expect(controller.state.isReady, isTrue);
    expect(controller.history, hasLength(2));
    expect(controller.progress.totalQuestions, 2);
    expect(controller.progress.totalXp, 10);
  });

  test('surfaces an offline failure and retries all streams', () async {
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
      now: () => now,
    );
    addTearDown(controller.dispose);

    await pumpEventQueue();

    expect(controller.state.hasError, isTrue);
    expect(controller.state.isOffline, isTrue);
    expect(controller.state.errorMessage, 'You are offline.');

    sessions
      ..error = null
      ..sessions = [buildOverviewSession()];
    controller.retry();
    await pumpEventQueue();

    expect(controller.state.isReady, isTrue);
    expect(controller.state.isOffline, isFalse);
    expect(controller.history.single.title, 'Cell biology notes');
    expect(sessions.watchCalls, 2);
  });

  test('stops accepting events after disposal', () async {
    final sessions = StreamController<List<StudySession>>();
    final controller = StudyOverviewController(
      'user-1',
      FakeStudySessionRepository(stream: sessions.stream),
      FakeQuizRepository(),
      FakeQuizResultRepository(),
      now: () => now,
    );

    controller.dispose();
    sessions.add([buildOverviewSession()]);
    await pumpEventQueue();

    expect(controller.state.isLoading, isTrue);
    await sessions.close();
  });
}
