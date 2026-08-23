import 'package:flutter/material.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../study/presentation/study_screen.dart';
import '../../../core/routing/app_router.dart';
import '../application/shell_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.user,
    required this.authController,
    required this.shellController,
    super.key,
  });

  final AppUser user;
  final AuthController authController;
  final ShellController shellController;

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

  @override
  Widget build(BuildContext context) {
    void openTutor() => Navigator.of(context).pushNamed(AppRoutes.tutor);
    void openScan() => Navigator.of(context).pushNamed(AppRoutes.scan);

    final pages = <Widget>[
      HomeScreen(user: user, onOpenTutor: openTutor, onOpenScan: openScan),
      StudyScreen(onOpenTutor: openTutor, onOpenScan: openScan),
      const HistoryScreen(),
      const ProgressScreen(),
      ProfileScreen(user: user, authController: authController),
    ];

    return ListenableBuilder(
      listenable: shellController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= 840;
            final content = IndexedStack(
              index: shellController.selectedIndex,
              children: pages,
            );

            if (useRail) {
              return Scaffold(
                body: Row(
                  children: [
                    SafeArea(
                      child: NavigationRail(
                        selectedIndex: shellController.selectedIndex,
                        onDestinationSelected: shellController.select,
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
                selectedIndex: shellController.selectedIndex,
                onDestinationSelected: shellController.select,
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
