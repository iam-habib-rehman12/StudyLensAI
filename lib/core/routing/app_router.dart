import 'package:flutter/material.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/bootstrap/application/bootstrap_controller.dart';
import '../../features/bootstrap/presentation/startup_gate.dart';
import '../../features/document/application/document_analysis_controller.dart';
import '../../features/document/domain/document_analysis_repository.dart';
import '../../features/document/domain/document_intake_service.dart';
import '../../features/document/presentation/document_analysis_screen.dart';
import '../../core/utils/id_generator.dart';
import '../../features/quiz/application/quiz_generation_controller.dart';
import '../../features/quiz/application/quiz_player_controller.dart';
import '../../features/quiz/domain/quiz.dart';
import '../../features/quiz/domain/quiz_generation_repository.dart';
import '../../features/quiz/domain/quiz_repository.dart';
import '../../features/quiz/domain/quiz_result_repository.dart';
import '../../features/quiz/presentation/quiz_generation_screen.dart';
import '../../features/quiz/presentation/quiz_player_screen.dart';
import '../../features/study/domain/study_session_repository.dart';
import '../../features/scan/application/scan_controller.dart';
import '../../features/scan/application/image_analysis_controller.dart';
import '../../features/scan/domain/image_analysis_repository.dart';
import '../../features/scan/domain/image_intake_service.dart';
import '../../features/scan/domain/study_image.dart';
import '../../features/scan/presentation/image_analysis_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/shell/application/shell_controller.dart';
import '../../features/tutor/application/tutor_controller.dart';
import '../../features/tutor/domain/tutor_repository.dart';
import '../../features/tutor/presentation/tutor_screen.dart';

abstract final class AppRoutes {
  static const startup = '/';
  static const register = '/register';
  static const tutor = '/tutor';
  static const scan = '/scan';
  static const imageAnalysis = '/scan/analyze';
  static const documentAnalysis = '/document';
  static const quizGeneration = '/quiz/generate';
  static const quizPlayer = '/quiz/player';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required BootstrapController bootstrapController,
    required AuthController authController,
    required ShellController shellController,
    required TutorRepository tutorRepository,
    required ImageIntakeService imageIntakeService,
    required ImageAnalysisRepository imageAnalysisRepository,
    required DocumentIntakeService documentIntakeService,
    required DocumentAnalysisRepository documentAnalysisRepository,
    required QuizGenerationRepository quizGenerationRepository,
    required QuizResultRepository quizResultRepository,
    required QuizRepository quizRepository,
    required StudySessionRepository sessionRepository,
  }) {
    return switch (settings.name) {
      AppRoutes.startup => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => StartupGate(
          controller: bootstrapController,
          authController: authController,
          shellController: shellController,
          sessionRepository: sessionRepository,
          quizRepository: quizRepository,
          quizResultRepository: quizResultRepository,
        ),
      ),
      AppRoutes.register => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => RegisterScreen(controller: authController),
      ),
      AppRoutes.tutor => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) {
          final user = authController.state.user;
          if (user == null) return const _UnknownRouteScreen();
          return TutorScreen(
            controller: TutorController(user.uid, tutorRepository),
          );
        },
      ),
      AppRoutes.scan => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => authController.state.user == null
            ? const _UnknownRouteScreen()
            : ScanScreen(
                controller: ScanController(imageIntakeService),
                onAnalyzeImage: (image) => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.imageAnalysis, arguments: image),
              ),
      ),
      AppRoutes.imageAnalysis => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) {
          final user = authController.state.user;
          final image = settings.arguments;
          if (user == null || image is! StudyImage) {
            return const _UnknownRouteScreen();
          }
          return ImageAnalysisScreen(
            controller: ImageAnalysisController(
              user.uid,
              image,
              imageAnalysisRepository,
            ),
          );
        },
      ),
      AppRoutes.documentAnalysis => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) {
          final user = authController.state.user;
          if (user == null) return const _UnknownRouteScreen();
          return DocumentAnalysisScreen(
            controller: DocumentAnalysisController(
              user.uid,
              documentIntakeService,
              documentAnalysisRepository,
            ),
          );
        },
      ),
      AppRoutes.quizGeneration => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final user = authController.state.user;
          if (user == null) return const _UnknownRouteScreen();
          return QuizGenerationScreen(
            controller: QuizGenerationController(
              user.uid,
              quizGenerationRepository,
            ),
            onStartQuiz: (quiz) => Navigator.of(
              context,
            ).pushNamed(AppRoutes.quizPlayer, arguments: quiz),
          );
        },
      ),
      AppRoutes.quizPlayer => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) {
          final user = authController.state.user;
          final quiz = settings.arguments;
          if (user == null || quiz is! Quiz) {
            return const _UnknownRouteScreen();
          }
          return QuizPlayerScreen(
            controller: QuizPlayerController(
              quiz,
              user.uid,
              quizResultRepository,
              SecureIdGenerator(),
            ),
          );
        },
      ),
      _ => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const _UnknownRouteScreen(),
      ),
    };
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('StudyLens could not open this page.'),
        ),
      ),
    );
  }
}
