import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 21, 10);

  QuizQuestion question({
    String id = 'question-1',
    String text = 'What is ATP?',
  }) {
    return QuizQuestion(
      id: id,
      question: text,
      options: const [
        'Cellular energy carrier',
        'A lipid',
        'A chromosome',
        'A tissue',
      ],
      correctOptionIndex: 0,
      explanation: 'ATP transfers usable chemical energy in cells.',
    );
  }

  test('round-trips a validated structured quiz', () {
    final quiz = Quiz(
      id: 'quiz-1',
      userId: 'user-1',
      sessionId: 'session-1',
      title: 'Biology review',
      questions: [question()],
      createdAt: createdAt,
    );

    final restored = Quiz.fromMap(quiz.toMap());

    expect(restored.id, quiz.id);
    expect(restored.questions.single.options, hasLength(4));
    expect(restored.questions.single.correctOptionIndex, 0);
  });

  test('rejects questions without four unique options', () {
    expect(
      () => QuizQuestion(
        id: 'question-1',
        question: 'Invalid?',
        options: const ['A', 'A', 'B', 'C'],
        correctOptionIndex: 0,
        explanation: 'Invalid duplicate options.',
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate questions', () {
    expect(
      () => Quiz(
        id: 'quiz-1',
        userId: 'user-1',
        title: 'Duplicate quiz',
        questions: [
          question(),
          question(id: 'question-2'),
        ],
        createdAt: createdAt,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a document with an inconsistent question count', () {
    final quiz = Quiz(
      id: 'quiz-1',
      userId: 'user-1',
      title: 'Biology review',
      questions: [question()],
      createdAt: createdAt,
    );
    final data = quiz.toMap()..['questionCount'] = 2;

    expect(() => Quiz.fromMap(data), throwsFormatException);
  });
}
