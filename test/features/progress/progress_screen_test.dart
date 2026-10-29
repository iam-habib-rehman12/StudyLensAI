import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/progress/application/study_overview_controller.dart';
import 'package:studylens_ai/features/progress/presentation/progress_screen.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';

import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_result_repository.dart';
import '../../helpers/overview_fixtures.dart';

void main() {
  testWidgets('renders level progress, accuracy, and recent results', (
    tester,
  ) async {
    final controller = _controller(
      results: [buildOverviewResult()],
      quizzes: [buildOverviewQuiz()],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ProgressScreen(overview: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learning progress'), findsOneWidget);
    expect(find.text('Lv 1'), findsOneWidget);
    expect(find.text('10 XP total'), findsOneWidget);
    expect(find.text('1 quiz • 0 sessions'), findsOneWidget);
    expect(find.text('50%'), findsNWidgets(3));
    expect(find.text('Recent quiz results'), findsOneWidget);
    expect(find.text('Cell Biology Review'), findsOneWidget);
    expect(find.textContaining('1/2 correct'), findsOneWidget);
  });

  testWidgets('shows the empty state without quiz results', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ProgressScreen(overview: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No progress to calculate yet'), findsOneWidget);
  });

  testWidgets('shows a failure and retries the result stream', (tester) async {
    final results = FakeQuizResultRepository(
      error: const AppException(
        type: AppErrorType.persistence,
        message: 'Progress could not be loaded.',
      ),
    );
    final controller = StudyOverviewController(
      'user-1',
      FakeStudySessionRepository(),
      FakeQuizRepository(),
      results,
      now: () => DateTime.utc(2026, 8, 25, 12),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: ProgressScreen(overview: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progress could not be loaded.'), findsOneWidget);

    results
      ..error = null
      ..results = [buildOverviewResult()];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('10 XP total'), findsOneWidget);
  });
}

StudyOverviewController _controller({
  List<QuizResult> results = const [],
  List<Quiz> quizzes = const [],
}) {
  return StudyOverviewController(
    'user-1',
    FakeStudySessionRepository(),
    FakeQuizRepository(quizzes: quizzes),
    FakeQuizResultRepository(results: results),
    now: () => DateTime.utc(2026, 8, 25, 12),
  );
}
