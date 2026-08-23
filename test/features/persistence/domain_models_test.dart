import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/auth/domain/student_profile.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 21, 10);

  test('loads a validated student profile', () {
    final profile = StudentProfile.fromMap({
      'uid': 'user-1',
      'name': 'Ayesha',
      'email': 'ayesha@example.com',
      'createdAt': timestamp,
      'xp': 120,
      'level': 2,
      'totalQuestions': 10,
      'correctAnswers': 8,
    });

    expect(profile.name, 'Ayesha');
    expect(profile.correctAnswers, 8);
  });

  test('rejects impossible student progress', () {
    expect(
      () => StudentProfile(
        uid: 'user-1',
        name: 'Ayesha',
        email: 'ayesha@example.com',
        createdAt: timestamp,
        totalQuestions: 2,
        correctAnswers: 3,
      ),
      throwsArgumentError,
    );
  });

  test('round-trips a typed study message', () {
    final message = StudyMessage(
      id: 'message-1',
      userId: 'user-1',
      sessionId: 'session-1',
      role: StudyMessageRole.assistant,
      content: 'Mitosis produces two genetically identical daughter cells.',
      createdAt: timestamp,
    );

    final restored = StudyMessage.fromMap(message.toMap());

    expect(restored.role, StudyMessageRole.assistant);
    expect(restored.content, message.content);
  });

  test('validates and calculates quiz result accuracy', () {
    final result = QuizResult(
      id: 'result-1',
      userId: 'user-1',
      quizId: 'quiz-1',
      selectedOptionIndexes: const [0, 2, 1, 3],
      correctAnswers: 3,
      completedAt: timestamp,
      xpEarned: 30,
    );

    final restored = QuizResult.fromMap(result.toMap());

    expect(restored.totalQuestions, 4);
    expect(restored.accuracy, 0.75);
  });

  test('rejects quiz results containing an invalid option index', () {
    expect(
      () => QuizResult(
        id: 'result-1',
        userId: 'user-1',
        quizId: 'quiz-1',
        selectedOptionIndexes: const [4],
        correctAnswers: 0,
        completedAt: timestamp,
        xpEarned: 0,
      ),
      throwsArgumentError,
    );
  });
}
