import '../../../core/persistence/document_database.dart';
import '../../../core/persistence/firestore_paths.dart';
import '../domain/user_data_cleaner.dart';

class FirestoreUserDataCleaner implements UserDataCleaner {
  const FirestoreUserDataCleaner(this._database);

  final DocumentDatabase _database;

  @override
  Future<void> deleteAll(String userId) async {
    final sessions = await _database.getCollection(
      path: FirestorePaths.sessions(userId),
    );
    for (final session in sessions) {
      final messages = await _database.getCollection(
        path: FirestorePaths.messages(userId, session.id),
      );
      for (final message in messages) {
        await _database.deleteDocument(
          FirestorePaths.message(userId, session.id, message.id),
        );
      }
      await _database.deleteDocument(
        FirestorePaths.session(userId, session.id),
      );
    }

    final quizzes = await _database.getCollection(
      path: FirestorePaths.quizzes(userId),
    );
    for (final quiz in quizzes) {
      await _database.deleteDocument(FirestorePaths.quiz(userId, quiz.id));
    }

    final results = await _database.getCollection(
      path: FirestorePaths.quizResults(userId),
    );
    for (final result in results) {
      await _database.deleteDocument(
        FirestorePaths.quizResult(userId, result.id),
      );
    }

    await _database.deleteDocument(FirestorePaths.user(userId));
  }
}
