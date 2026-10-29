import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/app.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/auth/application/auth_controller.dart';
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
  testWidgets('shows missing Firebase configuration values', (tester) async {
    final service = FakeBootstrapService(
      onInitialize: () async {
        throw FirebaseConfigurationException([
          'FIREBASE_API_KEY',
          'FIREBASE_PROJECT_ID',
        ]);
      },
    );
    final controller = BootstrapController(service);
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final authController = AuthController(authRepository);
    final shellController = ShellController();

    await tester.pumpWidget(
      StudyLensApp(
        bootstrapController: controller,
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

    expect(find.text('Firebase configuration required'), findsOneWidget);
    expect(find.text('FIREBASE_API_KEY'), findsOneWidget);
    expect(find.text('FIREBASE_PROJECT_ID'), findsOneWidget);
  });
}
