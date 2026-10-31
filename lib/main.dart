import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/ai/firebase_ai_service.dart';
import 'core/observability/debug_error_reporter.dart';
import 'core/observability/error_handlers.dart';
import 'core/config/firebase_environment_config.dart';
import 'core/persistence/firestore_document_database.dart';
import 'core/utils/id_generator.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/firebase_auth_service.dart';
import 'features/auth/data/firestore_user_data_cleaner.dart';
import 'features/auth/data/firestore_user_profile_service.dart';
import 'features/bootstrap/application/bootstrap_controller.dart';
import 'features/bootstrap/data/firebase_bootstrap_service.dart';
import 'features/document/data/device_document_intake_service.dart';
import 'features/document/data/firebase_document_analysis_repository.dart';
import 'features/quiz/data/firebase_quiz_generation_repository.dart';
import 'features/quiz/data/firestore_quiz_repository.dart';
import 'features/quiz/data/firestore_quiz_result_repository.dart';
import 'features/scan/data/device_image_intake_service.dart';
import 'features/scan/data/firebase_image_analysis_repository.dart';
import 'features/shell/application/shell_controller.dart';
import 'features/study/data/firestore_study_session_repository.dart';
import 'features/tutor/data/firebase_tutor_repository.dart';
import 'features/tutor/data/firestore_study_message_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const reporter = DebugErrorReporter();
  installErrorHandlers(reporter);
  runZonedGuarded(
    _startApp,
    (error, stackTrace) => reporter.report(
      error,
      stackTrace,
      context: 'Uncaught asynchronous error',
      fatal: true,
    ),
  );
}

void _startApp() {
  final firebaseConfig = FirebaseEnvironmentConfig.fromEnvironment();
  final bootstrapController = BootstrapController(
    FirebaseBootstrapService(config: firebaseConfig),
  );
  final database = FirestoreDocumentDatabase();
  final authController = AuthController(
    FirebaseAuthRepository(
      FirebaseAuthService(),
      FirestoreUserProfileService(),
      FirestoreUserDataCleaner(database),
    ),
  );
  final shellController = ShellController();
  final imageIntakeService = DeviceImageIntakeService();
  final documentIntakeService = DeviceDocumentIntakeService();
  final aiService = FirebaseAiService();
  final sessionRepository = FirestoreStudySessionRepository(database);
  final messageRepository = FirestoreStudyMessageRepository(database);
  final tutorRepository = FirebaseTutorRepository(
    aiService,
    sessionRepository,
    messageRepository,
    SecureIdGenerator(),
  );
  final imageAnalysisRepository = FirebaseImageAnalysisRepository(
    aiService,
    sessionRepository,
    messageRepository,
    SecureIdGenerator(),
  );
  final documentAnalysisRepository = FirebaseDocumentAnalysisRepository(
    aiService,
    sessionRepository,
    messageRepository,
    SecureIdGenerator(),
  );
  final quizRepository = FirestoreQuizRepository(database);
  final quizGenerationRepository = FirebaseQuizGenerationRepository(
    aiService,
    quizRepository,
    SecureIdGenerator(),
  );
  final quizResultRepository = FirestoreQuizResultRepository(database);

  runApp(
    StudyLensApp(
      bootstrapController: bootstrapController,
      authController: authController,
      shellController: shellController,
      tutorRepository: tutorRepository,
      imageIntakeService: imageIntakeService,
      imageAnalysisRepository: imageAnalysisRepository,
      documentIntakeService: documentIntakeService,
      documentAnalysisRepository: documentAnalysisRepository,
      quizGenerationRepository: quizGenerationRepository,
      quizResultRepository: quizResultRepository,
      quizRepository: quizRepository,
      sessionRepository: sessionRepository,
    ),
  );
}
