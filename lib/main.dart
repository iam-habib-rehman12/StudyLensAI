import 'package:flutter/material.dart';

import 'app.dart';
import 'core/ai/firebase_ai_service.dart';
import 'core/config/firebase_environment_config.dart';
import 'core/persistence/firestore_document_database.dart';
import 'core/utils/id_generator.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/firebase_auth_service.dart';
import 'features/auth/data/firestore_user_profile_service.dart';
import 'features/bootstrap/application/bootstrap_controller.dart';
import 'features/bootstrap/data/firebase_bootstrap_service.dart';
import 'features/scan/data/device_image_intake_service.dart';
import 'features/shell/application/shell_controller.dart';
import 'features/study/data/firestore_study_session_repository.dart';
import 'features/tutor/data/firebase_tutor_repository.dart';
import 'features/tutor/data/firestore_study_message_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseConfig = FirebaseEnvironmentConfig.fromEnvironment();
  final bootstrapController = BootstrapController(
    FirebaseBootstrapService(config: firebaseConfig),
  );
  final authController = AuthController(
    FirebaseAuthRepository(
      FirebaseAuthService(),
      FirestoreUserProfileService(),
    ),
  );
  final shellController = ShellController();
  final imageIntakeService = DeviceImageIntakeService();
  final database = FirestoreDocumentDatabase();
  final tutorRepository = FirebaseTutorRepository(
    FirebaseAiService(),
    FirestoreStudySessionRepository(database),
    FirestoreStudyMessageRepository(database),
    SecureIdGenerator(),
  );

  runApp(
    StudyLensApp(
      bootstrapController: bootstrapController,
      authController: authController,
      shellController: shellController,
      tutorRepository: tutorRepository,
      imageIntakeService: imageIntakeService,
    ),
  );
}
