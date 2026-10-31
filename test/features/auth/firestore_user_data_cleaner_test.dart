import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/persistence/document_database.dart';
import 'package:studylens_ai/core/persistence/firestore_paths.dart';
import 'package:studylens_ai/features/auth/data/firestore_user_data_cleaner.dart';

import '../../helpers/fake_document_database.dart';

void main() {
  test('deletes messages, sessions, quizzes, results, then the profile', () async {
    final database = FakeDocumentDatabase();
    database.collections[FirestorePaths.sessions('user-1')] = [
      const StoredDocument(id: 'session-1', data: {}),
      const StoredDocument(id: 'session-2', data: {}),
    ];
    database.collections[FirestorePaths.messages('user-1', 'session-1')] = [
      const StoredDocument(id: 'message-1', data: {}),
      const StoredDocument(id: 'message-2', data: {}),
    ];
    database.collections[FirestorePaths.messages('user-1', 'session-2')] = [
      const StoredDocument(id: 'message-3', data: {}),
    ];
    database.collections[FirestorePaths.quizzes('user-1')] = [
      const StoredDocument(id: 'quiz-1', data: {}),
    ];
    database.collections[FirestorePaths.quizResults('user-1')] = [
      const StoredDocument(id: 'result-1', data: {}),
    ];
    database.documents[FirestorePaths.user('user-1')] = {'uid': 'user-1'};

    final cleaner = FirestoreUserDataCleaner(database);
    await cleaner.deleteAll('user-1');

    expect(
      database.deleted,
      containsAll([
        FirestorePaths.message('user-1', 'session-1', 'message-1'),
        FirestorePaths.message('user-1', 'session-1', 'message-2'),
        FirestorePaths.message('user-1', 'session-2', 'message-3'),
        FirestorePaths.session('user-1', 'session-1'),
        FirestorePaths.session('user-1', 'session-2'),
        FirestorePaths.quiz('user-1', 'quiz-1'),
        FirestorePaths.quizResult('user-1', 'result-1'),
        FirestorePaths.user('user-1'),
      ]),
    );
    expect(
      database.documents.containsKey(FirestorePaths.user('user-1')),
      isFalse,
    );
  });
}
