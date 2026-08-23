import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.user,
    required this.authController,
    super.key,
  });

  final AppUser user;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Profile', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            _initials(user.name),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(user.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 5),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Chip(
                          avatar: Icon(Icons.verified_user_rounded, size: 18),
                          label: Text('Firebase account'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Appearance'),
                        subtitle: const Text('Follows your device theme'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showScheduled(context),
                      ),
                      const Divider(height: 1, indent: 64),
                      const ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('About'),
                        subtitle: Text(AppConfig.tagline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: authController.state.isSubmitting
                      ? null
                      : authController.signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
                if (authController.state.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    authController.state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final initials = words.map((word) => word[0].toUpperCase()).join();
    return initials.isEmpty ? 'S' : initials;
  }

  void _showScheduled(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme controls are scheduled for the polish milestone.'),
        showCloseIcon: true,
      ),
    );
  }
}
