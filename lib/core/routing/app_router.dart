import 'package:flutter/material.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/bootstrap/application/bootstrap_controller.dart';
import '../../features/bootstrap/presentation/startup_gate.dart';
import '../../features/scan/application/scan_controller.dart';
import '../../features/scan/domain/image_intake_service.dart';
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
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required BootstrapController bootstrapController,
    required AuthController authController,
    required ShellController shellController,
    required TutorRepository tutorRepository,
    required ImageIntakeService imageIntakeService,
  }) {
    return switch (settings.name) {
      AppRoutes.startup => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => StartupGate(
          controller: bootstrapController,
          authController: authController,
          shellController: shellController,
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
        builder: (_) => authController.state.user == null
            ? const _UnknownRouteScreen()
            : ScanScreen(controller: ScanController(imageIntakeService)),
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
