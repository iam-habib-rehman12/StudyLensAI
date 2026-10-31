import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/app.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
import 'package:studylens_ai/features/auth/presentation/login_screen.dart';
import 'package:studylens_ai/features/bootstrap/application/bootstrap_controller.dart';
import 'package:studylens_ai/features/shell/application/shell_controller.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_bootstrap_service.dart';
import '../../helpers/fake_document_services.dart';
import '../../helpers/fake_image_intake_service.dart';
import '../../helpers/fake_image_analysis_repository.dart';
import '../../helpers/fake_overview_repositories.dart';
import '../../helpers/fake_quiz_generation_repository.dart';
import '../../helpers/fake_quiz_result_repository.dart';
import '../../helpers/fake_tutor_repository.dart';

void main() {
  testWidgets('shows login and reports an incorrect password', (tester) async {
    final bootstrapController = BootstrapController(FakeBootstrapService());
    final repository = FakeAuthRepository(
      onSignIn: (_, _) async => throw const AppException(
        type: AppErrorType.authentication,
        message: 'The email or password is incorrect.',
      ),
    );
    addTearDown(repository.dispose);
    final authController = AuthController(repository);
    final shellController = ShellController();

    await tester.pumpWidget(
      StudyLensApp(
        bootstrapController: bootstrapController,
        authController: authController,
        shellController: shellController,
        tutorRepository: FakeTutorRepository(),
        imageIntakeService: FakeImageIntakeService(),
        imageAnalysisRepository: FakeImageAnalysisRepository(),
        documentIntakeService: FakeDocumentIntakeService(),
        documentAnalysisRepository: FakeDocumentAnalysisRepository(),
        quizGenerationRepository: FakeQuizGenerationRepository(),
        quizResultRepository: FakeQuizResultRepository(),
        quizRepository: FakeQuizRepository(),
        sessionRepository: FakeStudySessionRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrect123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(repository.signInCalls, 1);
  });

  testWidgets('registration rejects mismatched passwords locally', (
    tester,
  ) async {
    final bootstrapController = BootstrapController(FakeBootstrapService());
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final authController = AuthController(repository);
    final shellController = ShellController();

    await tester.pumpWidget(
      StudyLensApp(
        bootstrapController: bootstrapController,
        authController: authController,
        shellController: shellController,
        tutorRepository: FakeTutorRepository(),
        imageIntakeService: FakeImageIntakeService(),
        imageAnalysisRepository: FakeImageAnalysisRepository(),
        documentIntakeService: FakeDocumentIntakeService(),
        documentAnalysisRepository: FakeDocumentAnalysisRepository(),
        quizGenerationRepository: FakeQuizGenerationRepository(),
        quizResultRepository: FakeQuizResultRepository(),
        quizRepository: FakeQuizRepository(),
        sessionRepository: FakeStudySessionRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ayesha');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ayesha@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'different123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets('sends a password reset from the login screen', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: controller)),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.tap(find.byKey(const Key('forgot-password')));
    await tester.pumpAndSettle();

    expect(repository.passwordResetCalls, 1);
    expect(repository.lastResetEmail, 'student@example.com');
    expect(
      find.text('Password reset email sent. Check your inbox.'),
      findsOneWidget,
    );
  });
}
