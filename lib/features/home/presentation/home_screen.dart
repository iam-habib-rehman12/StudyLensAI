import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/domain/app_user.dart';
import 'widgets/feature_action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.user,
    required this.onOpenTutor,
    required this.onOpenScan,
    super.key,
  });

  final AppUser user;
  final VoidCallback onOpenTutor;
  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _greetingFor(DateTime.now().hour);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    BrandMark(size: 42),
                    SizedBox(width: 12),
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  '$greeting, ${_firstName(user.name)}',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'What will you learn today?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _AskStudyLensCard(onTap: onOpenTutor),
                const SizedBox(height: 30),
                const SectionHeader(
                  title: 'Quick actions',
                  subtitle: 'Choose how you want to study.',
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: columns == 4 ? 0.95 : 1.03,
                      children: [
                        FeatureActionCard(
                          icon: Icons.document_scanner_rounded,
                          title: 'Scan & Learn',
                          subtitle: 'Camera or gallery',
                          accentColor: AppColors.indigo,
                          onTap: onOpenScan,
                        ),
                        FeatureActionCard(
                          icon: Icons.picture_as_pdf_rounded,
                          title: 'Ask PDF',
                          subtitle: 'Learn from documents',
                          accentColor: AppColors.warning,
                          onTap: () => _showScheduledMessage(
                            context,
                            'Ask PDF',
                            'Day 9',
                          ),
                        ),
                        FeatureActionCard(
                          icon: Icons.chat_bubble_rounded,
                          title: 'AI Tutor',
                          subtitle: 'Ask any question',
                          accentColor: AppColors.cyan,
                          onTap: onOpenTutor,
                        ),
                        FeatureActionCard(
                          icon: Icons.psychology_rounded,
                          title: 'Generate Quiz',
                          subtitle: 'Test your knowledge',
                          accentColor: AppColors.success,
                          onTap: () => _showScheduledMessage(
                            context,
                            'Quiz generation',
                            'Days 10-11',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                const SectionHeader(title: 'Continue studying'),
                const SizedBox(height: 14),
                const EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'No study sessions yet',
                  message: 'Your recent learning material will appear here.',
                  compact: true,
                ),
                const SizedBox(height: 30),
                const SectionHeader(title: "Today's progress"),
                const SizedBox(height: 14),
                const _TodayProgressCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Student' : trimmed.split(RegExp(r'\s+')).first;
  }

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showScheduledMessage(
    BuildContext context,
    String feature,
    String milestone,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature is scheduled for $milestone.'),
          showCloseIcon: true,
        ),
      );
  }
}

class _AskStudyLensCard extends StatelessWidget {
  const _AskStudyLensCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.askGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask StudyLens AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'What are you learning?',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  child: _ProgressMetric(value: '0', label: 'Questions'),
                ),
                _MetricDivider(),
                Expanded(
                  child: _ProgressMetric(value: '0', label: 'Quizzes'),
                ),
                _MetricDivider(),
                Expanded(
                  child: _ProgressMetric(value: '—', label: 'Accuracy'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Activity tracking begins when the study tools are available.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
