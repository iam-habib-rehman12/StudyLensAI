import '../../../core/errors/app_exception.dart';
import '../../../core/persistence/document_database.dart';
import '../../../core/persistence/firestore_paths.dart';
import '../domain/quiz_result.dart';
import '../domain/quiz_result_repository.dart';

class FirestoreQuizResultRepository implements QuizResultRepository {
  const FirestoreQuizResultRepository(this._database);

  final DocumentDatabase _database;

  @override
  Future<void> saveResult(QuizResult result) {
    final data = result.toMap()..['completedAt'] = serverTimestamp;
    return _database.setDocument(
      path: FirestorePaths.quizResult(result.userId, result.id),
      data: data,
    );
  }

  @override
  Stream<List<QuizResult>> watchRecentResults(String userId, {int limit = 20}) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100.');
    }
    return _database
        .watchCollection(
          path: FirestorePaths.quizResults(userId),
          orderBy: 'completedAt',
          descending: true,
          limit: limit,
        )
        .map(
          (documents) => documents
              .map((document) {
                try {
                  final result = QuizResult.fromMap(document.data);
                  if (result.id != document.id || result.userId != userId) {
                    throw const FormatException(
                      'Quiz result ownership data is inconsistent.',
                    );
                  }
                  return result;
                } on FormatException catch (error) {
                  throw AppException(
                    type: AppErrorType.invalidDocument,
                    message:
                        'A saved quiz result is malformed and cannot be shown.',
                    cause: error,
                  );
                } on ArgumentError catch (error) {
                  throw AppException(
                    type: AppErrorType.invalidDocument,
                    message:
                        'A saved quiz result is malformed and cannot be shown.',
                    cause: error,
                  );
                }
              })
              .toList(growable: false),
        );
  }
}
