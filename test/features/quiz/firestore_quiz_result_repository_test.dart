import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/core/persistence/document_database.dart';
import 'package:studylens_ai/core/persistence/firestore_paths.dart';
import 'package:studylens_ai/features/quiz/data/firestore_quiz_result_repository.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';

import '../../helpers/fake_document_database.dart';

void main() {
  final completedAt = DateTime.utc(2026, 8, 25, 12);

  QuizResult result() => QuizResult(
    id: 'result-1',
    userId: 'user-1',
    quizId: 'quiz-1',
    selectedOptionIndexes: const [0, 1],
    correctAnswers: 1,
    completedAt: completedAt,
    xpEarned: 10,
  );

  test('saves a result beneath its owning user with a server timestamp', () async {
    final database = FakeDocumentDatabase();
    final repository = FirestoreQuizResultRepository(database);

    await repository.saveResult(result());

    final write = database.writes.single;
    expect(write.path, FirestorePaths.quizResult('user-1', 'result-1'));
    expect(write.merge, isFalse);
    expect(write.data['completedAt'], same(serverTimestamp));
    expect(write.data['totalQuestions'], 2);
    expect(write.data['xpEarned'], 10);
  });

  test('decodes recent results for the owning user', () async {
    final database = FakeDocumentDatabase();
    final stored = result().toMap()..['completedAt'] = completedAt;
    database.collections[FirestorePaths.quizResults('user-1')] = [
      StoredDocument(id: 'result-1', data: stored),
    ];
    final repository = FirestoreQuizResultRepository(database);

    final results = await repository.watchRecentResults('user-1').first;

    expect(results.single.correctAnswers, 1);
    expect(results.single.totalQuestions, 2);
    expect(results.single.accuracy, 0.5);
  });

  test('rejects a stored result whose owner does not match its path', () async {
    final database = FakeDocumentDatabase();
    final stored = result().toMap()
      ..['userId'] = 'user-2'
      ..['completedAt'] = completedAt;
    database.collections[FirestorePaths.quizResults('user-1')] = [
      StoredDocument(id: 'result-1', data: stored),
    ];
    final repository = FirestoreQuizResultRepository(database);

    await expectLater(
      repository.watchRecentResults('user-1').first,
      throwsA(
        isA<AppException>().having(
          (error) => error.type,
          'type',
          AppErrorType.invalidDocument,
        ),
      ),
    );
  });
}
