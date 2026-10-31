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
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: Icon(
                                user.isEmailVerified
                                    ? Icons.verified_rounded
                                    : Icons.mark_email_unread_outlined,
                                size: 18,
                              ),
                              label: Text(
                                user.isEmailVerified
                                    ? 'Email verified'
                                    : 'Email not verified',
                              ),
                            ),
                            const Chip(
                              avatar: Icon(
                                Icons.verified_user_rounded,
                                size: 18,
                              ),
                              label: Text('Firebase account'),
                            ),
                          ],
                        ),
                        if (!user.isEmailVerified) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                key: const Key('resend-verification'),
                                onPressed: authController.state.isSubmitting
                                    ? null
                                    : () => _resendVerification(context),
                                icon: const Icon(
                                  Icons.outgoing_mail,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Resend verification email',
                                ),
                              ),
                              TextButton.icon(
                                key: const Key('refresh-verification'),
                                onPressed: authController.state.isSubmitting
                                    ? null
                                    : () => _refreshVerification(context),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text('Refresh status'),
                              ),
                            ],
                          ),
                        ],
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
                        onTap: () => _showThemeInfo(context),
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
                const SizedBox(height: 10),
                TextButton.icon(
                  key: const Key('delete-account-button'),
                  onPressed: authController.state.isSubmitting
                      ? null
                      : () => _deleteAccount(context),
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Delete account',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
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

  Future<void> _resendVerification(BuildContext context) async {
    final sent = await authController.resendVerificationEmail();
    if (!context.mounted) return;
    final message = sent
        ? 'Verification email sent. Check your inbox.'
        : authController.state.errorMessage ??
              'StudyLens could not send the verification email.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshVerification(BuildContext context) async {
    final refreshed = await authController.refreshUser();
    if (!context.mounted) return;
    final verified = authController.state.user?.isEmailVerified ?? false;
    final message = refreshed
        ? (verified
              ? 'Email verified.'
              : 'Email not verified yet. Check your inbox and try again.')
        : authController.state.errorMessage ??
              'StudyLens could not refresh your account.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteAccount(BuildContext context) async {
    var password = '';
    final confirmed = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your account and all saved study '
                'sessions, messages, quizzes, and results. Enter your password '
                'to confirm.',
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('delete-account-password'),
                autofocus: true,
                obscureText: true,
                onChanged: (value) => password = value,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-delete-account'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: colors.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(password),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == null || !context.mounted) return;
    if (confirmed.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your password to delete your account.'),
        ),
      );
      return;
    }

    final deleted = await authController.deleteAccount(password: confirmed);
    if (!context.mounted || deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authController.state.errorMessage ??
              'StudyLens could not delete your account.',
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

  void _showThemeInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('StudyLens follows your device light or dark theme.'),
        showCloseIcon: true,
      ),
    );
  }
}
