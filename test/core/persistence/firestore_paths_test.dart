import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/persistence/firestore_paths.dart';

void main() {
  test('builds only user-scoped persistence paths', () {
    expect(FirestorePaths.user('user-1'), 'users/user-1');
    expect(
      FirestorePaths.session('user-1', 'session-1'),
      'users/user-1/sessions/session-1',
    );
    expect(
      FirestorePaths.message('user-1', 'session-1', 'message-1'),
      'users/user-1/sessions/session-1/messages/message-1',
    );
    expect(
      FirestorePaths.quiz('user-1', 'quiz-1'),
      'users/user-1/quizzes/quiz-1',
    );
    expect(
      FirestorePaths.quizResult('user-1', 'result-1'),
      'users/user-1/quizResults/result-1',
    );
  });

  test('rejects empty and nested path identifiers', () {
    expect(() => FirestorePaths.user(''), throwsArgumentError);
    expect(
      () => FirestorePaths.session('user-1', 'other/session'),
      throwsArgumentError,
    );
  });
}
