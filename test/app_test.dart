import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/app.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
import 'package:studylens_ai/features/auth/domain/app_user.dart';
import 'package:studylens_ai/features/bootstrap/application/bootstrap_controller.dart';
import 'package:studylens_ai/features/shell/application/shell_controller.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_bootstrap_service.dart';
import 'helpers/fake_document_services.dart';
import 'helpers/fake_image_intake_service.dart';
import 'helpers/fake_image_analysis_repository.dart';
import 'helpers/fake_overview_repositories.dart';
import 'helpers/fake_quiz_generation_repository.dart';
import 'helpers/fake_quiz_result_repository.dart';
import 'helpers/fake_tutor_repository.dart';

void main() {
  testWidgets('renders the authenticated StudyLens landing screen', (
    tester,
  ) async {
    final bootstrapController = BootstrapController(FakeBootstrapService());
    final repository = FakeAuthRepository(
      initialUser: const AppUser(
        uid: 'uid-1',
        name: 'Habib',
        email: 'habib@example.com',
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

    expect(find.text('StudyLens AI'), findsOneWidget);
    expect(find.textContaining('Habib'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Scan & Learn'), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
  });
}
