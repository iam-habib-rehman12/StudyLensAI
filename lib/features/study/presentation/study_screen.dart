import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({
    required this.onOpenTutor,
    required this.onOpenScan,
    required this.onOpenDocument,
    required this.onOpenQuizGenerator,
    super.key,
  });

  final VoidCallback onOpenTutor;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenDocument;
  final VoidCallback onOpenQuizGenerator;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Turn your own learning material into understanding.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),
                const SectionHeader(title: 'Learning tools'),
                const SizedBox(height: 14),
                _StudyToolTile(
                  icon: Icons.document_scanner_rounded,
                  color: AppColors.indigo,
                  title: 'Scan & Learn',
                  description: 'Capture notes, equations, and diagrams.',
                  milestone: 'Available now',
                  available: true,
                  onTap: onOpenScan,
                ),
                const SizedBox(height: 12),
                _StudyToolTile(
                  icon: Icons.picture_as_pdf_rounded,
                  color: AppColors.warning,
                  title: 'Ask PDF',
                  description: 'Summarize and ask questions about documents.',
                  milestone: 'Day 9',
                  available: true,
                  onTap: onOpenDocument,
                ),
                const SizedBox(height: 12),
                _StudyToolTile(
                  icon: Icons.chat_bubble_rounded,
                  color: AppColors.cyan,
                  title: 'AI Tutor',
                  description: 'Learn through a contextual conversation.',
                  milestone: 'Available now',
                  available: true,
                  onTap: onOpenTutor,
                ),
                const SizedBox(height: 12),
                _StudyToolTile(
                  icon: Icons.psychology_rounded,
                  color: AppColors.success,
                  title: 'Generate Quiz',
                  description:
                      'Create structured questions from your material.',
                  milestone: 'Days 10-11',
                  available: true,
                  onTap: onOpenQuizGenerator,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyToolTile extends StatelessWidget {
  const _StudyToolTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.milestone,
    required this.onTap,
    this.available = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String milestone;
  final VoidCallback onTap;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: available ? milestone : 'Scheduled for $milestone',
                child: Icon(
                  available
                      ? Icons.arrow_forward_rounded
                      : Icons.lock_clock_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
