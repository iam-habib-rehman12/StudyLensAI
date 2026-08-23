import '../../../core/errors/app_exception.dart';
import '../../../core/persistence/document_database.dart';
import '../../../core/persistence/firestore_paths.dart';
import '../domain/quiz.dart';
import '../domain/quiz_repository.dart';

class FirestoreQuizRepository implements QuizRepository {
  const FirestoreQuizRepository(this._database);

  final DocumentDatabase _database;

  @override
  Future<void> saveQuiz(Quiz quiz) {
    final data = quiz.toMap()..['createdAt'] = serverTimestamp;
    return _database.setDocument(
      path: FirestorePaths.quiz(quiz.userId, quiz.id),
      data: data,
    );
  }

  @override
  Future<Quiz?> getQuiz({
    required String userId,
    required String quizId,
  }) async {
    final data = await _database.getDocument(
      FirestorePaths.quiz(userId, quizId),
    );
    if (data == null) return null;
    return _decode(data, expectedId: quizId, expectedUserId: userId);
  }

  @override
  Stream<List<Quiz>> watchRecentQuizzes(String userId, {int limit = 20}) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100.');
    }
    return _database
        .watchCollection(
          path: FirestorePaths.quizzes(userId),
          orderBy: 'createdAt',
          descending: true,
          limit: limit,
        )
        .map(
          (documents) => documents
              .map(
                (document) => _decode(
                  document.data,
                  expectedId: document.id,
                  expectedUserId: userId,
                ),
              )
              .toList(growable: false),
        );
  }

  Quiz _decode(
    Map<String, Object?> data, {
    required String expectedId,
    required String expectedUserId,
  }) {
    try {
      final quiz = Quiz.fromMap(data);
      if (quiz.id != expectedId || quiz.userId != expectedUserId) {
        throw const FormatException('Quiz ownership data is inconsistent.');
      }
      return quiz;
    } on FormatException catch (error) {
      throw AppException(
        type: AppErrorType.invalidDocument,
        message: 'A saved quiz is malformed and cannot be opened.',
        cause: error,
      );
    } on ArgumentError catch (error) {
      throw AppException(
        type: AppErrorType.invalidDocument,
        message: 'A saved quiz is malformed and cannot be opened.',
        cause: error,
      );
    }
  }
}
