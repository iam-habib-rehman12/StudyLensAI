import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/history/presentation/history_screen.dart';
import 'package:studylens_ai/features/home/presentation/home_screen.dart';
import 'package:studylens_ai/features/progress/application/study_overview_controller.dart';
import 'package:studylens_ai/features/progress/presentation/progress_screen.dart';

import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_result_repository.dart';
import '../../helpers/overview_fixtures.dart';

void main() {
  testWidgets('Home, History, and Progress survive large text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = StudyOverviewController(
      'user-1',
      FakeStudySessionRepository(sessions: [buildOverviewSession()]),
      FakeQuizRepository(quizzes: [buildOverviewQuiz()]),
      FakeQuizResultRepository(results: [buildOverviewResult()]),
      now: () => DateTime.utc(2026, 8, 25, 12),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: HomeScreen(
            user: const AppUser(
              uid: 'user-1',
              name: 'Habib',
              email: 'habib@example.com',
            ),
            overview: controller,
            onOpenTutor: () {},
            onOpenScan: () {},
            onOpenDocument: () {},
            onOpenQuizGenerator: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: HistoryScreen(overview: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: ProgressScreen(overview: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
