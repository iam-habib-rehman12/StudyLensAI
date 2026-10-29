import 'dart:async';

import 'package:flutter/material.dart';

import '../../tutor/domain/study_message.dart';
import '../application/document_analysis_controller.dart';
import '../application/document_analysis_state.dart';
import '../domain/document_study_action.dart';

class DocumentAnalysisScreen extends StatefulWidget {
  const DocumentAnalysisScreen({required this.controller, super.key});

  final DocumentAnalysisController controller;

  @override
  State<DocumentAnalysisScreen> createState() => _DocumentAnalysisScreenState();
}

class _DocumentAnalysisScreenState extends State<DocumentAnalysisScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToLatest);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  void _submitQuestion() {
    final request = _questionController.text.trim();
    if (request.isEmpty || widget.controller.state.isBusy) return;
    _questionController.clear();
    FocusScope.of(context).unfocus();
    unawaited(widget.controller.submit(request));
  }

  void _runAction(DocumentStudyAction action) {
    unawaited(widget.controller.submit(action.prompt, action: action));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToLatest);
    widget.controller.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Ask PDF')),
          body: SafeArea(
            top: false,
            child: state.document == null
                ? _DocumentPickerView(
                    state: state,
                    onSelect: widget.controller.selectPdf,
                    onDismissError: widget.controller.clearError,
                  )
                : Column(
                    children: [
                      if (state.status ==
                              DocumentAnalysisStatus.savingRequest ||
                          state.status == DocumentAnalysisStatus.savingAnswer)
                        const LinearProgressIndicator(minHeight: 2),
                      _DocumentHeader(
                        state: state,
                        onRemove: widget.controller.removeDocument,
                      ),
                      if (state.messages.isEmpty)
                        _ActionBar(enabled: !state.isBusy, onTap: _runAction),
                      Expanded(
                        child: _Conversation(
                          state: state,
                          controller: _scrollController,
                        ),
                      ),
                      if (state.errorMessage case final message?)
                        _ErrorBanner(
                          message: message,
                          canRetry: state.canRetry,
                          onRetry: widget.controller.retry,
                          onDismiss: widget.controller.clearError,
                        ),
                      _Composer(
                        controller: _questionController,
                        enabled: !state.isBusy && !state.canRetry,
                        onSend: _submitQuestion,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _DocumentPickerView extends StatelessWidget {
  const _DocumentPickerView({
    required this.state,
    required this.onSelect,
    required this.onDismissError,
  });

  final DocumentAnalysisState state;
  final Future<void> Function() onSelect;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 38,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Learn from a PDF',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose an educational PDF to summarize it, find important topics, create revision notes, or ask questions.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.errorMessage case final message?) ...[
                    const SizedBox(height: 18),
                    _InlineIssue(message: message, onDismiss: onDismissError),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    key: const Key('select-pdf'),
                    onPressed: state.isBusy ? null : onSelect,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: Text(
                      state.status == DocumentAnalysisStatus.selecting
                          ? 'Opening files...'
                          : 'Select PDF',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PDF only • maximum 14 MB • kept in memory only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.state, required this.onRemove});

  final DocumentAnalysisState state;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final document = state.document!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.picture_as_pdf_rounded)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${_formatBytes(document.byteLength)} • Local until this screen closes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: state.isBusy ? null : onRemove,
            tooltip: 'Remove PDF',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).toStringAsFixed(0)} KB';
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.enabled, required this.onTap});

  final bool enabled;
  final ValueChanged<DocumentStudyAction> onTap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Row(
      children: [
        for (final action in DocumentStudyAction.values.where(
          (value) => value != DocumentStudyAction.question,
        )) ...[
          ActionChip(
            label: Text(action.label),
            avatar: Icon(_icon(action), size: 18),
            onPressed: enabled ? () => onTap(action) : null,
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );

  IconData _icon(DocumentStudyAction action) => switch (action) {
    DocumentStudyAction.summary => Icons.summarize_rounded,
    DocumentStudyAction.importantTopics => Icons.star_outline_rounded,
    DocumentStudyAction.revisionNotes => Icons.note_alt_outlined,
    DocumentStudyAction.question => Icons.help_outline_rounded,
  };
}

class _Conversation extends StatelessWidget {
  const _Conversation({required this.state, required this.controller});

  final DocumentAnalysisState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[
      if (state.messages.isEmpty && !state.isBusy)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Choose a quick action or type a specific question about this PDF.',
            textAlign: TextAlign.center,
          ),
        ),
      for (final message in state.messages) _MessageBubble(message: message),
      if (state.streamingText.isNotEmpty)
        _StreamingBubble(text: state.streamingText),
      if (state.status == DocumentAnalysisStatus.streaming &&
          state.streamingText.isEmpty)
        const _ThinkingBubble(),
    ];
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      children: entries,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final StudyMessage message;

  @override
  Widget build(BuildContext context) {
    final student = message.role == StudyMessageRole.student;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: student ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: student
              ? colors.primaryContainer
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(message.content),
      ),
    );
  }
}

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 680),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SelectableText(text),
    ),
  );
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator()),
          SizedBox(width: 10),
          Text('Reading the PDF...'),
        ],
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('pdf-question-field'),
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Ask a question about this PDF',
                prefixIcon: Icon(Icons.question_answer_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('send-pdf-question'),
            onPressed: enabled ? onSend : null,
            tooltip: 'Send question',
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.canRetry,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final bool canRetry;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(message),
    leading: const Icon(Icons.error_outline_rounded),
    actions: [
      if (canRetry) TextButton(onPressed: onRetry, child: const Text('Retry')),
      if (!canRetry)
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
    ],
  );
}

class _InlineIssue extends StatelessWidget {
  const _InlineIssue({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(child: Text(message)),
        IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Dismiss',
        ),
      ],
    ),
  );
}
