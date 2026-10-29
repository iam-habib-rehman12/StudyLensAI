import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/history_entry_tile.dart';
import '../../../shared/widgets/overview_status.dart';
import '../../progress/application/study_overview_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.overview, super.key});

  final StudyOverviewController overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: overview,
        builder: (context, _) {
          final state = overview.state;
          final entries = overview.history;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
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
                    const SizedBox(height: 24),
                    if (state.isLoading)
                      const OverviewLoading(
                        label: 'Loading your study history...',
                      )
                    else if (state.hasError)
                      OverviewFailure(
                        message:
                            state.errorMessage ??
                            'StudyLens could not load your study history.',
                        isOffline: state.isOffline,
                        onRetry: overview.retry,
                      )
                    else if (entries.isEmpty)
                      const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No study sessions yet',
                        message:
                            'Scan notes or ask StudyLens a question to begin. '
                            'Saved activity will appear here after you complete a session.',
                      )
                    else
                      for (final entry in entries)
                        HistoryEntryTile(entry: entry),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
