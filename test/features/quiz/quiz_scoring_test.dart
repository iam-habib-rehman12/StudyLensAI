import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_scoring.dart';

void main() {
  final completedAt = DateTime.utc(2026, 8, 25, 12);

  test('scores every correct answer and awards XP', () {
    final quiz = buildQuiz();

    final result = QuizScoring.grade(
      quiz: quiz,
      userId: 'user-1',
      resultId: 'result-1',
      selectedOptionIndexes: const [0, 1, 2],
      completedAt: completedAt,
    );

    expect(result.correctAnswers, 3);
    expect(result.totalQuestions, 3);
    expect(result.accuracy, 1);
    expect(result.xpEarned, 30);
    expect(result.quizId, 'quiz-1');
    expect(result.userId, 'user-1');
    expect(result.completedAt, completedAt);
  });

  test('scores partial and fully incorrect attempts deterministically', () {
    final quiz = buildQuiz();

    final partial = QuizScoring.grade(
      quiz: quiz,
      userId: 'user-1',
      resultId: 'result-1',
      selectedOptionIndexes: const [0, 3, 0],
      completedAt: completedAt,
    );
    final incorrect = QuizScoring.grade(
      quiz: quiz,
      userId: 'user-1',
      resultId: 'result-2',
      selectedOptionIndexes: const [1, 0, 3],
      completedAt: completedAt,
    );

    expect(partial.correctAnswers, 1);
    expect(partial.xpEarned, QuizScoring.xpPerCorrectAnswer);
    expect(incorrect.correctAnswers, 0);
    expect(incorrect.xpEarned, 0);
  });

  test('preserves the study session on the result', () {
    final result = QuizScoring.grade(
      quiz: buildQuiz(sessionId: 'session-1'),
      userId: 'user-1',
      resultId: 'result-1',
      selectedOptionIndexes: const [0, 1, 2],
      completedAt: completedAt,
    );

    expect(result.sessionId, 'session-1');
  });

  test('rejects incomplete or out-of-range answer sets', () {
    final quiz = buildQuiz();

    expect(
      () => QuizScoring.grade(
        quiz: quiz,
        userId: 'user-1',
        resultId: 'result-1',
        selectedOptionIndexes: const [0, 1],
        completedAt: completedAt,
      ),
      throwsArgumentError,
    );
    expect(
      () => QuizScoring.grade(
        quiz: quiz,
        userId: 'user-1',
        resultId: 'result-1',
        selectedOptionIndexes: const [0, 1, 4],
        completedAt: completedAt,
      ),
      throwsArgumentError,
    );
  });
}

Quiz buildQuiz({String? sessionId}) {
  return Quiz(
    id: 'quiz-1',
    userId: 'user-1',
    sessionId: sessionId,
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
