import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ai/ai_explanation_mode.dart';
import '../../../core/config/ai_config.dart';
import '../../tutor/domain/study_message.dart';
import '../application/image_analysis_controller.dart';
import '../application/image_analysis_state.dart';
import '../domain/image_prompt_suggestion.dart';

class ImageAnalysisScreen extends StatefulWidget {
  const ImageAnalysisScreen({required this.controller, super.key});

  final ImageAnalysisController controller;

  @override
  State<ImageAnalysisScreen> createState() => _ImageAnalysisScreenState();
}

class _ImageAnalysisScreenState extends State<ImageAnalysisScreen> {
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

  void _send([String? suggestion]) {
    final question = (suggestion ?? _questionController.text).trim();
    if (question.isEmpty || widget.controller.state.isBusy) return;
    _questionController.clear();
    FocusScope.of(context).unfocus();
    unawaited(widget.controller.sendQuestion(question));
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
          appBar: AppBar(title: const Text('Ask about image')),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (state.status == ImageAnalysisStatus.savingQuestion ||
                    state.status == ImageAnalysisStatus.savingAnswer)
                  const LinearProgressIndicator(minHeight: 2),
                _ImageContextHeader(controller: widget.controller),
                _ModeSelector(state: state, controller: widget.controller),
                if (state.messages.isEmpty && !state.isBusy)
                  _SuggestionChips(onSelected: _send),
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
                  textController: _questionController,
                  enabled: !state.isBusy && !state.canRetry,
                  onSend: _send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageContextHeader extends StatelessWidget {
  const _ImageContextHeader({required this.controller});
  final ImageAnalysisController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            controller.image.bytes,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image context',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                controller.image.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Kept in memory · not uploaded to Cloud Storage',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.state, required this.controller});
  final ImageAnalysisState state;
  final ImageAnalysisController controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SegmentedButton<AiExplanationMode>(
      segments: [
        for (final mode in AiExplanationMode.values)
          ButtonSegment(value: mode, label: Text(mode.label)),
      ],
      selected: {state.mode},
      onSelectionChanged: state.isBusy || state.canRetry
          ? null
          : (value) => controller.selectMode(value.first),
      showSelectedIcon: false,
    ),
  );
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
    child: Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final item in ImagePromptSuggestion.values)
          ActionChip(
            label: Text(item.label),
            onPressed: () => onSelected(item.question),
          ),
      ],
    ),
  );
}

class _Conversation extends StatelessWidget {
  const _Conversation({required this.state, required this.controller});
  final ImageAnalysisState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (state.messages.isEmpty && state.streamingText.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Choose a prompt or ask your own question about the image.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    final showStream =
        state.status == ImageAnalysisStatus.streaming ||
        state.streamingText.isNotEmpty;
    return SelectionArea(
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: state.messages.length + (showStream ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.messages.length) {
            return _Bubble(
              text: state.streamingText,
              student: false,
              loading: state.streamingText.isEmpty,
            );
          }
          final message = state.messages[index];
          return _Bubble(
            text: message.content,
            student: message.role == StudyMessageRole.student,
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.student,
    this.loading = false,
  });
  final String text;
  final bool student;
  final bool loading;

  @override
  Widget build(BuildContext context) => Align(
    alignment: student ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 680),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: student
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: loading
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Analyzing image...'),
              ],
            )
          : Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.45),
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded),
        const SizedBox(width: 9),
        Expanded(child: Text(message)),
        if (canRetry)
          TextButton(onPressed: onRetry, child: const Text('Try again'))
        else
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.textController,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController textController;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: AiConfig.tutorMaxQuestionCharacters,
              decoration: const InputDecoration(
                hintText: 'Ask about this image...',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 9),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    ),
  );
}
