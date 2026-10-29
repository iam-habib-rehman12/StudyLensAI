import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../progress/application/study_overview_controller.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../quiz/domain/quiz_repository.dart';
import '../../quiz/domain/quiz_result_repository.dart';
import '../../study/domain/study_session_repository.dart';
import '../../study/presentation/study_screen.dart';
import '../application/shell_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.user,
    required this.authController,
    required this.shellController,
    required this.sessionRepository,
    required this.quizRepository,
    required this.quizResultRepository,
    super.key,
  });

  final AppUser user;
  final AuthController authController;
  final ShellController shellController;
  final StudySessionRepository sessionRepository;
  final QuizRepository quizRepository;
  final QuizResultRepository quizResultRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = [
    _ShellDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _ShellDestination(
      label: 'Study',
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories_rounded,
    ),
    _ShellDestination(
      label: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    _ShellDestination(
      label: 'Progress',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    _ShellDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  late StudyOverviewController _overview;

  @override
  void initState() {
    super.initState();
    _createOverview();
  }

  void _createOverview() {
    _overview = StudyOverviewController(
      widget.user.uid,
      widget.sessionRepository,
      widget.quizRepository,
      widget.quizResultRepository,
    );
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _overview.dispose();
      _createOverview();
    }
  }

  @override
  void dispose() {
    _overview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void openTutor() => Navigator.of(context).pushNamed(AppRoutes.tutor);
    void openScan() => Navigator.of(context).pushNamed(AppRoutes.scan);
    void openDocument() =>
        Navigator.of(context).pushNamed(AppRoutes.documentAnalysis);
    void openQuizGenerator() =>
        Navigator.of(context).pushNamed(AppRoutes.quizGeneration);

    final pages = <Widget>[
      HomeScreen(
        user: widget.user,
        overview: _overview,
        onOpenTutor: openTutor,
        onOpenScan: openScan,
        onOpenDocument: openDocument,
        onOpenQuizGenerator: openQuizGenerator,
      ),
      StudyScreen(
        onOpenTutor: openTutor,
        onOpenScan: openScan,
        onOpenDocument: openDocument,
        onOpenQuizGenerator: openQuizGenerator,
      ),
      HistoryScreen(overview: _overview),
      ProgressScreen(overview: _overview),
      ProfileScreen(
        user: widget.user,
        authController: widget.authController,
      ),
    ];

    return ListenableBuilder(
      listenable: widget.shellController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= 840;
            final content = IndexedStack(
              index: widget.shellController.selectedIndex,
              children: pages,
            );

            if (useRail) {
              return Scaffold(
                body: Row(
                  children: [
                    SafeArea(
                      child: NavigationRail(
                        selectedIndex: widget.shellController.selectedIndex,
                        onDestinationSelected: widget.shellController.select,
                        extended: constraints.maxWidth >= 1120,
                        groupAlignment: -0.75,
                        labelType: constraints.maxWidth >= 1120
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.selected,
                        destinations: [
                          for (final destination in _destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                ),
              );
            }

            return Scaffold(
              body: content,
              bottomNavigationBar: NavigationBar(
                selectedIndex: widget.shellController.selectedIndex,
                onDestinationSelected: widget.shellController.select,
                destinations: [
                  for (final destination in _destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
