import 'dart:async';

import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/bootstrap/application/bootstrap_controller.dart';
import 'features/bootstrap/domain/bootstrap_state.dart';
import 'features/scan/domain/image_intake_service.dart';
import 'features/shell/application/shell_controller.dart';
import 'features/tutor/domain/tutor_repository.dart';

class StudyLensApp extends StatefulWidget {
  const StudyLensApp({
    required this.bootstrapController,
    required this.authController,
    required this.shellController,
    required this.tutorRepository,
    required this.imageIntakeService,
    super.key,
  });

  final BootstrapController bootstrapController;
  final AuthController authController;
  final ShellController shellController;
  final TutorRepository tutorRepository;
  final ImageIntakeService imageIntakeService;

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
      ),
    );
  }
}
