import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/shell/application/shell_controller.dart';
import 'package:studylens_ai/features/shell/presentation/app_shell.dart';
import 'package:studylens_ai/core/routing/app_router.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_result_repository.dart';

void main() {
  testWidgets('navigates across the five authenticated destinations', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final authController = AuthController(repository);
    addTearDown(authController.dispose);
    final shellController = ShellController();
    addTearDown(shellController.dispose);
    const user = AppUser(
      uid: 'uid-1',
      name: 'Habib Ahmed',
      email: 'habib@example.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          user: user,
          authController: authController,
          shellController: shellController,
          sessionRepository: FakeStudySessionRepository(),
          quizRepository: FakeQuizRepository(),
          quizResultRepository: FakeQuizResultRepository(),
        ),
      ),
    );

    expect(find.text('Quick actions'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Study history'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Learning progress'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Habib Ahmed'), findsOneWidget);
    expect(find.text('habib@example.com'), findsOneWidget);
  });

  testWidgets('opens the available Scan & Learn flow from Home', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final authController = AuthController(repository);
    addTearDown(authController.dispose);
    final shellController = ShellController();
    addTearDown(shellController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.scan: (_) => const Scaffold(body: Text('Scan route')),
        },
        home: AppShell(
          user: const AppUser(
            uid: 'uid-1',
            name: 'Habib',
            email: 'habib@example.com',
          ),
          authController: authController,
          shellController: shellController,
          sessionRepository: FakeStudySessionRepository(),
          quizRepository: FakeQuizRepository(),
          quizResultRepository: FakeQuizResultRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Scan & Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Scan route'), findsOneWidget);
  });

  testWidgets('opens the available AI Tutor from Home', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final authController = AuthController(repository);
    addTearDown(authController.dispose);
    final shellController = ShellController();
    addTearDown(shellController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.tutor: (_) => const Scaffold(body: Text('Tutor route')),
        },
        home: AppShell(
          user: const AppUser(
            uid: 'uid-1',
            name: 'Habib',
            email: 'habib@example.com',
          ),
          authController: authController,
          shellController: shellController,
          sessionRepository: FakeStudySessionRepository(),
          quizRepository: FakeQuizRepository(),
          quizResultRepository: FakeQuizResultRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Ask StudyLens AI'));
    await tester.pumpAndSettle();

    expect(find.text('Tutor route'), findsOneWidget);
  });
}
