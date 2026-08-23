import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/persistence/document_database.dart';
import 'package:studylens_ai/core/persistence/firestore_paths.dart';
import 'package:studylens_ai/features/quiz/data/firestore_quiz_repository.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';

import '../../helpers/fake_document_database.dart';

void main() {
  test('saves a validated quiz beneath its owning user', () async {
    final database = FakeDocumentDatabase();
    final repository = FirestoreQuizRepository(database);
    final quiz = Quiz(
      id: 'quiz-1',
      userId: 'user-1',
      title: 'Physics check',
      questions: [
        QuizQuestion(
          id: 'question-1',
          question: 'What is velocity?',
          options: const ['Speed with direction', 'Mass', 'Energy', 'Force'],
          correctOptionIndex: 0,
          explanation: 'Velocity combines speed and direction.',
        ),
      ],
      createdAt: DateTime.utc(2026, 8, 21),
    );

    await repository.saveQuiz(quiz);

    final write = database.writes.single;
    expect(write.path, FirestorePaths.quiz('user-1', 'quiz-1'));
    expect(write.data['questionCount'], 1);
    expect(write.data['createdAt'], same(serverTimestamp));
  });
}
