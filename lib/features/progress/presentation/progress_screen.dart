import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

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
                Text('Learning progress', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'See how your understanding improves over time.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                const EmptyState(
                  icon: Icons.insights_rounded,
                  title: 'No progress to calculate yet',
                  message:
                      'Complete quizzes and study sessions to unlock accuracy, '
                      'questions answered, XP, and activity insights.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
