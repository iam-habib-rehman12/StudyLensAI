import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../quiz/domain/quiz_repository.dart';
import '../../quiz/domain/quiz_result_repository.dart';
import '../../shell/application/shell_controller.dart';
import '../../shell/presentation/app_shell.dart';
import '../../study/domain/study_session_repository.dart';
import '../application/auth_controller.dart';
import '../domain/auth_state.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.controller,
    required this.shellController,
    required this.sessionRepository,
    required this.quizRepository,
    required this.quizResultRepository,
    super.key,
  });

  final AuthController controller;
  final ShellController shellController;
  final StudySessionRepository sessionRepository;
  final QuizRepository quizRepository;
  final QuizResultRepository quizResultRepository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return switch (controller.state.status) {
          AuthStatus.checking => const _AuthCheckingView(),
          AuthStatus.unauthenticated => LoginScreen(controller: controller),
          AuthStatus.authenticated => AppShell(
            authController: controller,
            user: controller.state.user!,
            shellController: shellController,
            sessionRepository: sessionRepository,
            quizRepository: quizRepository,
            quizResultRepository: quizResultRepository,
          ),
        };
      },
    );
  }
}

class _AuthCheckingView extends StatelessWidget {
  const _AuthCheckingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 88),
                const SizedBox(height: 28),
                Text(AppConfig.appName, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(
                  AppConfig.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 36),
                const CircularProgressIndicator(),
                const SizedBox(height: 14),
                const Text('Checking your account...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
