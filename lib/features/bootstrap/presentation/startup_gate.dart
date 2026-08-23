import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../shell/application/shell_controller.dart';
import '../application/bootstrap_controller.dart';
import '../domain/bootstrap_state.dart';

class StartupGate extends StatelessWidget {
  const StartupGate({
    required this.controller,
    required this.authController,
    required this.shellController,
    super.key,
  });

  final BootstrapController controller;
  final AuthController authController;
  final ShellController shellController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return switch (controller.state.status) {
          BootstrapStatus.initial ||
          BootstrapStatus.loading => const _LoadingStartupView(),
          BootstrapStatus.ready => AuthGate(
            controller: authController,
            shellController: shellController,
          ),
          BootstrapStatus.configurationRequired => _ConfigurationView(
            missingKeys: controller.state.missingConfigurationKeys,
          ),
          BootstrapStatus.failure => _FailureView(
            message: controller.state.message,
            onRetry: controller.initialize,
          ),
        };
      },
    );
  }
}

class _LoadingStartupView extends StatelessWidget {
  const _LoadingStartupView();

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
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing your learning workspace...',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigurationView extends StatelessWidget {
  const _ConfigurationView({required this.missingKeys});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase setup')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.settings_suggest_rounded,
                        size: 42,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Firebase configuration required',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'StudyLens is ready for Firebase, but this build does '
                        'not contain project-specific values. Add the missing '
                        'dart-defines and restart the app.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Missing values',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in missingKeys)
                            Chip(
                              avatar: const Icon(Icons.key_rounded, size: 18),
                              label: Text(key),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'StudyLens could not start',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message ?? 'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
