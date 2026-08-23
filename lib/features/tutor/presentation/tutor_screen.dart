import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/ai_config.dart';
import '../../../core/theme/app_colors.dart';
import '../application/tutor_controller.dart';
import '../application/tutor_state.dart';
import '../domain/study_message.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({required this.controller, super.key});

  final TutorController controller;

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTutorChanged);
  }

  void _onTutorChanged() {
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

  @override
  void dispose() {
    widget.controller.removeListener(_onTutorChanged);
    widget.controller.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? suggestedQuestion]) {
    final question = (suggestedQuestion ?? _questionController.text).trim();
    if (question.isEmpty || widget.controller.state.isBusy) return;
    _questionController.clear();
    FocusScope.of(context).unfocus();
    unawaited(widget.controller.sendQuestion(question));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask StudyLens'),
                Text(
                  'AI Tutor',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (state.status == TutorStatus.savingQuestion ||
                    state.status == TutorStatus.savingAnswer)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(child: _buildConversation(context, state)),
                if (state.errorMessage case final message?)
                  _TutorErrorBanner(
                    message: message,
                    canRetry: state.canRetry,
                    onRetry: widget.controller.retry,
                    onDismiss: state.canRetry
                        ? null
                        : widget.controller.clearError,
                  ),
                _QuestionComposer(
                  controller: _questionController,
                  enabled: !state.isBusy && !state.canRetry,
                  isBusy: state.isBusy,
                  onSend: _send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversation(BuildContext context, TutorState state) {
    final hasContent =
        state.messages.isNotEmpty || state.streamingText.isNotEmpty;
    if (!hasContent && state.status == TutorStatus.ready) {
      return _TutorWelcome(onSuggestionSelected: _send);
    }

    return SelectionArea(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount:
            state.messages.length +
            (state.status == TutorStatus.streaming ||
                    state.streamingText.isNotEmpty
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index < state.messages.length) {
            return _MessageBubble(message: state.messages[index]);
          }
          return _StreamingBubble(text: state.streamingText);
        },
      ),
    );
  }
}

class _TutorWelcome extends StatelessWidget {
  const _TutorWelcome({required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  static const _suggestions = [
    'Explain photosynthesis step by step.',
    'Help me understand Newton’s second law.',
    'What is the difference between mitosis and meiosis?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppColors.askGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'What would you like to understand?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Ask a course question and StudyLens will explain it clearly, with context from this conversation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                alignment: WrapAlignment.center,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      avatar: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                      ),
                      label: Text(suggestion),
                      onPressed: () => onSuggestionSelected(suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'AI can make mistakes. Verify important course information.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final StudyMessage message;

  @override
  Widget build(BuildContext context) {
    final isStudent = message.role == StudyMessageRole.student;
    final theme = Theme.of(context);
    return Align(
      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: isStudent ? 'Your question' : 'StudyLens answer',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          decoration: BoxDecoration(
            color: isStudent
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isStudent ? 20 : 5),
              bottomRight: Radius.circular(isStudent ? 5 : 20),
            ),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ),
      ),
    );
  }
}

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: text.isEmpty
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('StudyLens is thinking...'),
                ],
              )
            : Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
      ),
    );
  }
}

class _TutorErrorBanner extends StatelessWidget {
  const _TutorErrorBanner({
    required this.message,
    required this.canRetry,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final bool canRetry;
  final Future<void> Function() onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          if (canRetry)
            TextButton(onPressed: onRetry, child: const Text('Try again'))
          else
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss error',
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _QuestionComposer extends StatelessWidget {
  const _QuestionComposer({
    required this.controller,
    required this.enabled,
    required this.isBusy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isBusy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, bottomInset > 0 ? 12 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                maxLength: AiConfig.tutorMaxQuestionCharacters,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Ask a study question...',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              tooltip: isBusy ? 'StudyLens is responding' : 'Send question',
              icon: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
