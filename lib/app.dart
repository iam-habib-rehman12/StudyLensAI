import 'dart:async';

import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/bootstrap/application/bootstrap_controller.dart';
import 'features/bootstrap/domain/bootstrap_state.dart';
import 'features/document/domain/document_analysis_repository.dart';
import 'features/document/domain/document_intake_service.dart';
import 'features/quiz/domain/quiz_generation_repository.dart';
import 'features/quiz/domain/quiz_repository.dart';
import 'features/quiz/domain/quiz_result_repository.dart';
import 'features/study/domain/study_session_repository.dart';
import 'features/scan/domain/image_intake_service.dart';
import 'features/scan/domain/image_analysis_repository.dart';
import 'features/shell/application/shell_controller.dart';
import 'features/tutor/domain/tutor_repository.dart';

class StudyLensApp extends StatefulWidget {
  const StudyLensApp({
    required this.bootstrapController,
    required this.authController,
    required this.shellController,
    required this.tutorRepository,
    required this.imageIntakeService,
    required this.imageAnalysisRepository,
    required this.documentIntakeService,
    required this.documentAnalysisRepository,
    required this.quizGenerationRepository,
    required this.quizResultRepository,
    required this.quizRepository,
    required this.sessionRepository,
    super.key,
  });

  final BootstrapController bootstrapController;
  final AuthController authController;
  final ShellController shellController;
  final TutorRepository tutorRepository;
  final ImageIntakeService imageIntakeService;
  final ImageAnalysisRepository imageAnalysisRepository;
  final DocumentIntakeService documentIntakeService;
  final DocumentAnalysisRepository documentAnalysisRepository;
  final QuizGenerationRepository quizGenerationRepository;
  final QuizResultRepository quizResultRepository;
  final QuizRepository quizRepository;
  final StudySessionRepository sessionRepository;

  @override
  State<StudyLensApp> createState() => _StudyLensAppState();
}

class _StudyLensAppState extends State<StudyLensApp> {
  @override
  void initState() {
    super.initState();
    widget.bootstrapController.addListener(_onBootstrapChanged);
    widget.authController.addListener(_onAuthChanged);
    unawaited(widget.bootstrapController.initialize());
  }

  void _onAuthChanged() {
    if (widget.authController.state.status == AuthStatus.unauthenticated) {
      widget.shellController.reset();
    }
  }

  void _onBootstrapChanged() {
    if (widget.bootstrapController.state.status == BootstrapStatus.ready) {
      unawaited(widget.authController.initialize());
    }
  }

  @override
  void dispose() {
    widget.bootstrapController.removeListener(_onBootstrapChanged);
    widget.authController.removeListener(_onAuthChanged);
    widget.bootstrapController.dispose();
    widget.authController.dispose();
    widget.shellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.startup,
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        bootstrapController: widget.bootstrapController,
        authController: widget.authController,
        shellController: widget.shellController,
        tutorRepository: widget.tutorRepository,
        imageIntakeService: widget.imageIntakeService,
        imageAnalysisRepository: widget.imageAnalysisRepository,
        documentIntakeService: widget.documentIntakeService,
        documentAnalysisRepository: widget.documentAnalysisRepository,
        quizGenerationRepository: widget.quizGenerationRepository,
        quizResultRepository: widget.quizResultRepository,
        quizRepository: widget.quizRepository,
        sessionRepository: widget.sessionRepository,
      ),
    );
  }
}
