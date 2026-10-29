import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/core/utils/id_generator.dart';
import 'package:studylens_ai/features/quiz/application/quiz_player_controller.dart';
import 'package:studylens_ai/features/quiz/application/quiz_player_state.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';

import '../../helpers/fake_quiz_result_repository.dart';

void main() {
  test('starts unanswered and navigates without losing selections', () {
    final repository = FakeQuizResultRepository();
    final controller = _controller(repository);
    addTearDown(controller.dispose);

    expect(controller.state.currentIndex, 0);
    expect(controller.state.answeredCount, 0);
    expect(controller.canSubmit, isFalse);

    controller.selectAnswer(0);
    controller.nextQuestion();
    controller.selectAnswer(1);
    controller.previousQuestion();

    expect(controller.state.currentIndex, 0);
    expect(controller.state.selectedAnswers, [0, 1, null]);
    expect(controller.state.answeredCount, 2);
  });

  test('rejects submission until every question is answered', () async {
    final repository = FakeQuizResultRepository();
    final controller = _controller(repository);
    addTearDown(controller.dispose);

    controller.selectAnswer(0);
    expect(await controller.submit(), isFalse);

    expect(repository.saveCalls, 0);
    expect(controller.state.errorMessage, 'Answer every question before submitting.');
  });

  test('grades, saves, and exposes a completed result', () async {
    final repository = FakeQuizResultRepository();
    final controller = _controller(repository);
    addTearDown(controller.dispose);

    _answerAllCorrectly(controller);
    expect(controller.canSubmit, isTrue);
    expect(await controller.submit(), isTrue);

    final result = controller.state.result!;
    expect(controller.state.status, QuizPlayerStatus.completed);
    expect(result.correctAnswers, 3);
    expect(result.xpEarned, 30);
    expect(repository.saved.single.id, 'result-1');
    expect(controller.state.isSaved, isTrue);
  });

  test('retries saving the same graded result without rescoring', () async {
    final repository = FakeQuizResultRepository()
      ..saveError = const AppException(
        type: AppErrorType.persistence,
        message: 'Result could not be saved.',
      );
    final controller = _controller(repository);
    addTearDown(controller.dispose);

    _answerAllCorrectly(controller);
    expect(await controller.submit(), isFalse);

    expect(controller.state.status, QuizPlayerStatus.reviewed);
    expect(controller.state.canRetry, isTrue);
    expect(controller.state.result?.correctAnswers, 3);
    expect(controller.state.errorMessage, contains('has not been saved'));

    repository.saveError = null;
    await controller.retrySave();

    expect(repository.saveCalls, 2);
    expect(controller.state.status, QuizPlayerStatus.completed);
    expect(controller.state.canRetry, isFalse);
    expect(repository.saved.single.id, 'result-1');
  });

  test('ignores navigation and answers after completion', () async {
    final repository = FakeQuizResultRepository();
    final controller = _controller(repository);
    addTearDown(controller.dispose);

    _answerAllCorrectly(controller);
    await controller.submit();
    controller.goToQuestion(1);
    controller.selectAnswer(0);

    expect(controller.state.currentIndex, 2);
    expect(controller.state.selectedAnswers, [0, 1, 2]);
    expect(await controller.submit(), isFalse);
    expect(repository.saveCalls, 1);
  });
}

QuizPlayerController _controller(FakeQuizResultRepository repository) {
  return QuizPlayerController(
    buildPlayerQuiz(),
    'user-1',
    repository,
    _IdGeneratorFake(),
    now: () => DateTime.utc(2026, 8, 25, 12),
  );
}

void _answerAllCorrectly(QuizPlayerController controller) {
  final quiz = controller.quiz;
  for (var index = 0; index < quiz.questions.length; index++) {
    controller.goToQuestion(index);
    controller.selectAnswer(quiz.questions[index].correctOptionIndex);
  }
  controller.goToQuestion(quiz.questions.length - 1);
  controller.selectAnswer(
    quiz.questions.last.correctOptionIndex,
  );
}

Quiz buildPlayerQuiz() {
  return Quiz(
    id: 'quiz-1',
    userId: 'user-1',
    title: 'Cell biology',
    questions: [
      for (var index = 0; index < 3; index++)
        QuizQuestion(
          id: 'question-$index',
          question: 'Question ${index + 1}?',
          options: const ['Option A', 'Option B', 'Option C', 'Option D'],
          correctOptionIndex: index,
          explanation: 'Explanation ${index + 1}.',
        ),
    ],
    createdAt: DateTime.utc(2026, 8, 25),
  );
}

class _IdGeneratorFake implements IdGenerator {
  int _value = 0;

  @override
  String next(String prefix) => '$prefix-${++_value}';
}
