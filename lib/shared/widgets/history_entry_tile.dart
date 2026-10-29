import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/relative_time.dart';
import '../../features/history/domain/history_entry.dart';

class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({
    required this.entry,
    this.dense = false,
    super.key,
  });

  final HistoryEntry entry;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _visualFor(entry.kind);
    return Card(
      key: Key('history-entry-${entry.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 16,
          vertical: dense ? 2 : 6,
        ),
        leading: Container(
          width: dense ? 38 : 44,
          height: dense ? 38 : 44,
          decoration: BoxDecoration(
            color: visual.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            visual.icon,
            color: visual.color,
            size: dense ? 20 : 23,
          ),
        ),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          entry.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          relativeTime(entry.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  _EntryVisual _visualFor(HistoryEntryKind kind) => switch (kind) {
    HistoryEntryKind.textSession => const _EntryVisual(
      icon: Icons.chat_bubble_outline_rounded,
      color: AppColors.cyan,
    ),
    HistoryEntryKind.imageSession => const _EntryVisual(
      icon: Icons.document_scanner_outlined,
      color: AppColors.indigo,
    ),
    HistoryEntryKind.pdfSession => const _EntryVisual(
      icon: Icons.picture_as_pdf_outlined,
      color: AppColors.warning,
    ),
    HistoryEntryKind.quizResult => const _EntryVisual(
      icon: Icons.psychology_outlined,
      color: AppColors.success,
    ),
  };
}

class _EntryVisual {
  const _EntryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}
