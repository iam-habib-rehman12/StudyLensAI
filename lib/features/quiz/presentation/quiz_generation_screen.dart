import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/ai_config.dart';
import '../application/quiz_generation_controller.dart';
import '../application/quiz_generation_state.dart';
import '../domain/quiz.dart';
import '../domain/quiz_generation_request.dart';

class QuizGenerationScreen extends StatefulWidget {
  const QuizGenerationScreen({
    required this.controller,
    required this.onStartQuiz,
    super.key,
  });

  final QuizGenerationController controller;
  final ValueChanged<Quiz> onStartQuiz;

  @override
  State<QuizGenerationScreen> createState() => _QuizGenerationScreenState();
}

class _QuizGenerationScreenState extends State<QuizGenerationScreen> {
  final _sourceController = TextEditingController();
  QuizDifficulty _difficulty = QuizDifficulty.medium;
  int _questionCount = 5;

  @override
  void dispose() {
    widget.controller.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _generate() {
    FocusScope.of(context).unfocus();
    unawaited(
      widget.controller.generate(
        sourceMaterial: _sourceController.text,
        questionCount: _questionCount,
        difficulty: _difficulty,
      ),
    );
  }

  void _startOver() {
    widget.controller.startOver();
    _sourceController.clear();
    setState(() {
      _difficulty = QuizDifficulty.medium;
      _questionCount = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Generate quiz')),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (state.isBusy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: state.status == QuizGenerationStatus.success
                      ? _QuizPreview(
                          quiz: state.quiz!,
                          onStartOver: _startOver,
                          onStartQuiz: widget.onStartQuiz,
                        )
                      : _GenerationForm(
                          state: state,
                          sourceController: _sourceController,
                          difficulty: _difficulty,
                          questionCount: _questionCount,
                          onDifficultyChanged: (value) =>
                              setState(() => _difficulty = value),
                          onCountChanged: (value) =>
                              setState(() => _questionCount = value),
                          onGenerate: _generate,
                          onRetry: widget.controller.retry,
                          onDismissError: widget.controller.clearError,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GenerationForm extends StatelessWidget {
  const _GenerationForm({
    required this.state,
    required this.sourceController,
    required this.difficulty,
    required this.questionCount,
    required this.onDifficultyChanged,
    required this.onCountChanged,
    required this.onGenerate,
    required this.onRetry,
    required this.onDismissError,
  });

  final QuizGenerationState state;
  final TextEditingController sourceController;
  final QuizDifficulty difficulty;
  final int questionCount;
  final ValueChanged<QuizDifficulty> onDifficultyChanged;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onGenerate;
  final Future<void> Function() onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a reliable study quiz',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Enter a topic, your notes, or a passage. StudyLens validates every generated question before saving it.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('quiz-source-field'),
                controller: sourceController,
                enabled: !state.isBusy && !state.canRetry,
                minLines: 5,
                maxLines: 10,
                maxLength: AiConfig.quizMaxSourceCharacters,
                decoration: const InputDecoration(
                  labelText: 'Topic or study material',
                  hintText:
                      'Example: Newton’s three laws of motion, with force, mass, acceleration, and practical examples.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Text('Difficulty', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              SegmentedButton<QuizDifficulty>(
                segments: [
                  for (final value in QuizDifficulty.values)
                    ButtonSegment(value: value, label: Text(value.label)),
                ],
                selected: {difficulty},
                onSelectionChanged: state.isBusy || state.canRetry
                    ? null
                    : (values) => onDifficultyChanged(values.single),
              ),
              const SizedBox(height: 22),
              Text('Number of questions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  for (final count in const [5, 10, 15])
                    ChoiceChip(
                      label: Text('$count'),
                      selected: questionCount == count,
                      onSelected: state.isBusy || state.canRetry
                          ? null
                          : (_) => onCountChanged(count),
                    ),
                ],
              ),
              if (state.errorMessage case final message?) ...[
                const SizedBox(height: 20),
                _GenerationIssue(
                  message: message,
                  canRetry: state.canRetry,
                  onRetry: onRetry,
                  onDismiss: onDismissError,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('generate-quiz-button'),
                onPressed: state.isBusy || state.canRetry ? null : onGenerate,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  state.status == QuizGenerationStatus.generating
                      ? 'Generating validated quiz...'
                      : state.status == QuizGenerationStatus.saving
                      ? 'Saving quiz...'
                      : 'Generate quiz',
                ),
              ),
              const SizedBox(height: 14),
              const _ReliabilityNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizPreview extends StatelessWidget {
  const _QuizPreview({
    required this.quiz,
    required this.onStartOver,
    required this.onStartQuiz,
  });

  final Quiz quiz;
  final VoidCallback onStartOver;
  final ValueChanged<Quiz> onStartQuiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Validated and saved',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${quiz.questions.length} structured questions are ready.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(quiz.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Review the structure below, then start the quiz when you are ready.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                for (var index = 0; index < quiz.questions.length; index++)
                  _QuestionPreview(
                    index: index,
                    question: quiz.questions[index],
                  ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('start-quiz-button'),
                  onPressed: () => onStartQuiz(quiz),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start quiz'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onStartOver,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Generate another quiz'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionPreview extends StatelessWidget {
  const _QuestionPreview({required this.index, required this.question});

  final int index;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      title: Text('${index + 1}. ${question.question}'),
      subtitle: const Text('Four options • one validated answer'),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var optionIndex = 0;
          optionIndex < question.options.length;
          optionIndex++
        )
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Row(
              children: [
                Icon(
                  optionIndex == question.correctOptionIndex
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 19,
                  color: optionIndex == question.correctOptionIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(question.options[optionIndex])),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          question.explanation,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _GenerationIssue extends StatelessWidget {
  const _GenerationIssue({
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
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        if (canRetry)
          TextButton(onPressed: onRetry, child: const Text('Retry'))
        else
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    ),
  );
}

class _ReliabilityNotice extends StatelessWidget {
  const _ReliabilityNotice();

  @override
  Widget build(BuildContext context) => Text(
    'Generated data must contain the exact question count, four unique options, one valid answer index, explanations, and no duplicate questions before StudyLens will save it.',
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.4,
    ),
  );
}
