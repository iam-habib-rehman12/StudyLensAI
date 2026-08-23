import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
                Text('Study history', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Return to conversations, scans, documents, and quizzes.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No study sessions yet',
                  message:
                      'Scan notes or ask StudyLens a question to begin. Saved '
                      'activity will appear here after you complete a StudyLens session.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
