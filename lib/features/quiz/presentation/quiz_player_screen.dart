import 'dart:async';

import 'package:flutter/material.dart';

import '../application/quiz_player_controller.dart';
import '../application/quiz_player_state.dart';
import '../domain/quiz.dart';
import '../domain/quiz_result.dart';

class QuizPlayerScreen extends StatefulWidget {
  const QuizPlayerScreen({required this.controller, super.key});

  final QuizPlayerController controller;

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  void _submit() {
    unawaited(widget.controller.submit());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.controller.quiz.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Quiz',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: state.isFinished
                ? _ReviewView(
                    controller: widget.controller,
                    state: state,
                  )
                : _AnswerView(
                    controller: widget.controller,
                    state: state,
                    onSubmit: _submit,
                  ),
          ),
        );
      },
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({
    required this.controller,
    required this.state,
    required this.onSubmit,
  });

  final QuizPlayerController controller;
  final QuizPlayerState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final quiz = controller.quiz;
    final theme = Theme.of(context);
    final question = quiz.questions[state.currentIndex];
    final questionNumber = state.currentIndex + 1;
    final isLastQuestion = state.currentIndex == quiz.questions.length - 1;

    return Column(
      children: [
        LinearProgressIndicator(
          value: questionNumber / quiz.questions.length,
          minHeight: 4,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Question $questionNumber of ${quiz.questions.length}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.checklist_rounded, size: 17),
                    label: Text(
                      '${state.answeredCount}/${quiz.questions.length} answered',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                question.question,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 22),
              for (
                var optionIndex = 0;
                optionIndex < question.options.length;
                optionIndex++
              )
                _AnswerOption(
                  index: optionIndex,
                  label: question.options[optionIndex],
                  selected:
                      state.selectedAnswers[state.currentIndex] == optionIndex,
                  onTap: () => controller.selectAnswer(optionIndex),
                ),
              const SizedBox(height: 14),
              _QuestionNavigator(controller: controller, state: state),
              if (!state.allAnswered) ...[
                const SizedBox(height: 14),
                Text(
                  'Answer every question to enable submission.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (state.errorMessage case final message?) ...[
                const SizedBox(height: 14),
                _InlineError(message: message),
              ],
            ],
          ),
        ),
        _AnswerNavigation(
          state: state,
          isLastQuestion: isLastQuestion,
          onPrevious: controller.previousQuestion,
          onNext: controller.nextQuestion,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        label: 'Option ${index + 1}: $label',
        child: Material(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('quiz-option-$index'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({required this.controller, required this.state});

  final QuizPlayerController controller;
  final QuizPlayerState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Questions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < controller.questionCount; index++)
              ChoiceChip(
                key: Key('quiz-jump-$index'),
                label: Text('${index + 1}'),
                selected: index == state.currentIndex,
                avatar: state.selectedAnswers[index] != null &&
                        index != state.currentIndex
                    ? const Icon(Icons.check_rounded, size: 16)
                    : null,
                onSelected: (_) => controller.goToQuestion(index),
              ),
          ],
        ),
      ],
    );
  }
}

class _AnswerNavigation extends StatelessWidget {
  const _AnswerNavigation({
    required this.state,
    required this.isLastQuestion,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final QuizPlayerState state;
  final bool isLastQuestion;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            if (state.currentIndex > 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('quiz-previous'),
                  onPressed: state.isBusy ? null : onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                key: Key(isLastQuestion ? 'quiz-submit' : 'quiz-next'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                onPressed: state.isBusy
                    ? null
                    : isLastQuestion
                    ? (state.allAnswered ? onSubmit : null)
                    : onNext,
                icon: Icon(
                  isLastQuestion
                      ? Icons.task_alt_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(isLastQuestion ? 'Submit quiz' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.controller, required this.state});

  final QuizPlayerController controller;
  final QuizPlayerState state;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final theme = Theme.of(context);

    return Column(
      children: [
        if (state.isBusy) const LinearProgressIndicator(minHeight: 3),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _ScoreCard(result: result, saved: state.isSaved),
              if (state.errorMessage case final message?) ...[
                const SizedBox(height: 14),
                _SaveError(
                  message: message,
                  canRetry: state.canRetry && !state.isBusy,
                  onRetry: controller.retrySave,
                ),
              ],
              const SizedBox(height: 26),
              Text('Review your answers', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Correct answers and explanations are shown for every question.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < controller.quiz.questions.length; index++)
                _ReviewCard(
                  number: index + 1,
                  question: controller.quiz.questions[index],
                  selectedIndex: result.selectedOptionIndexes[index],
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('quiz-done'),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result, required this.saved});

  final QuizResult result;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accuracy = (result.accuracy * 100).round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: colors.onPrimaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$accuracy%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.correctAnswers} of ${result.totalQuestions} correct',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${result.xpEarned} XP earned',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      saved
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      size: 17,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      saved ? 'Result saved' : 'Result not saved yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveError extends StatelessWidget {
  const _SaveError({
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  final String message;
  final bool canRetry;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
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
            TextButton(
              key: const Key('quiz-retry-save'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.number,
    required this.question,
    required this.selectedIndex,
  });

  final int number;
  final QuizQuestion question;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final correct = selectedIndex == question.correctOptionIndex;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: correct ? colors.primary : colors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$number. ${question.question}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (
              var optionIndex = 0;
              optionIndex < question.options.length;
              optionIndex++
            )
              _ReviewOption(
                label: question.options[optionIndex],
                isCorrect: optionIndex == question.correctOptionIndex,
                isSelected: optionIndex == selectedIndex,
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                question.explanation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewOption extends StatelessWidget {
  const _ReviewOption({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
  });

  final String label;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = isCorrect
        ? Icons.check_circle_rounded
        : isSelected
        ? Icons.cancel_rounded
        : Icons.circle_outlined;
    final color = isCorrect
        ? colors.primary
        : isSelected
        ? colors.error
        : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
          if (isSelected)
            Text(
              'Your answer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
