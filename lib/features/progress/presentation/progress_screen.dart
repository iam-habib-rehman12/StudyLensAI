import 'package:flutter/material.dart';

import '../../../core/utils/relative_time.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/overview_status.dart';
import '../../quiz/domain/quiz_result.dart';
import '../application/study_overview_controller.dart';
import '../domain/progress_summary.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({required this.overview, super.key});

  final StudyOverviewController overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: overview,
        builder: (context, _) {
          final state = overview.state;
          final summary = overview.progress;
          final results = overview.recentResults;
          final quizzesById = {
            for (final quiz in state.quizzes) quiz.id: quiz,
          };
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Learning progress',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'See how your understanding improves over time.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (state.isLoading)
                      const OverviewLoading(
                        label: 'Calculating your progress...',
                      )
                    else if (state.hasError)
                      OverviewFailure(
                        message:
                            state.errorMessage ??
                            'StudyLens could not load your progress.',
                        isOffline: state.isOffline,
                        onRetry: overview.retry,
                      )
                    else if (summary.isEmpty)
                      const EmptyState(
                        icon: Icons.insights_rounded,
                        title: 'No progress to calculate yet',
                        message:
                            'Complete a generated quiz to unlock accuracy, '
                            'questions answered, XP, and level progress.',
                      )
                    else ...[
                      _SummaryCard(
                        summary: summary,
                        sessionCount: state.sessions.length,
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Recent quiz results',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (results.isEmpty)
                        const Text('No completed quizzes yet.')
                      else
                        for (final result in results)
                          _ResultTile(
                            result: result,
                            title:
                                quizzesById[result.quizId]?.title ??
                                'Quiz result',
                          ),
                      const SizedBox(height: 14),
                      Text(
                        'Progress is calculated from your saved quiz results. '
                        'Each correct answer earns 10 XP; every 200 XP raises your level.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.sessionCount});

  final ProgressSummary summary;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const Key('progress-summary'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.onPrimaryContainer.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Lv ${summary.level}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.totalXp} XP total',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_plural(summary.totalQuizzes, 'quiz', 'quizzes')} • '
                      '${_plural(sessionCount, 'session', 'sessions')}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${summary.accuracyPercent}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.levelProgress,
              minHeight: 8,
              backgroundColor: colors.onPrimaryContainer.withValues(
                alpha: 0.14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${summary.xpIntoLevel}/${summary.xpPerLevel} XP toward level ${summary.level + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: '${summary.correctAnswers}',
                  label: 'Correct answers',
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  value: '${summary.totalQuestions}',
                  label: 'Questions answered',
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  value: '${summary.accuracyPercent}%',
                  label: 'Accuracy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(
      alpha: 0.16,
    ),
  );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.title});

  final QuizResult result;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            '${(result.accuracy * 100).round()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          '${result.correctAnswers}/${result.totalQuestions} correct • '
          '+${result.xpEarned} XP',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          relativeTime(result.completedAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
