import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/home/presentation/home_screen.dart';
import 'package:studylens_ai/features/progress/application/study_overview_controller.dart';

import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_result_repository.dart';
import '../../helpers/overview_fixtures.dart';

void main() {
  testWidgets('shows real recent activity and today progress', (tester) async {
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

    expect(find.text('Cell biology notes'), findsOneWidget);
    expect(find.text('Level 1 • 10 XP total'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
  });
}
