import '../../../core/errors/app_exception.dart';
import '../../../core/persistence/document_database.dart';
import '../../../core/persistence/firestore_paths.dart';
import '../domain/study_session.dart';
import '../domain/study_session_repository.dart';

class FirestoreStudySessionRepository implements StudySessionRepository {
  const FirestoreStudySessionRepository(this._database);

  final DocumentDatabase _database;

  @override
  Future<void> createSession(StudySession session) {
    final data = session.toMap()
      ..['createdAt'] = serverTimestamp
      ..['updatedAt'] = serverTimestamp;
    return _database.setDocument(
      path: FirestorePaths.session(session.userId, session.id),
      data: data,
    );
  }

  @override
  Future<void> completeSession({
    required String userId,
    required String sessionId,
  }) {
    return _database.setDocument(
      path: FirestorePaths.session(userId, sessionId),
      data: {
        'status': StudySessionStatus.completed.name,
        'updatedAt': serverTimestamp,
      },
      merge: true,
    );
  }

  @override
  Future<StudySession?> getSession({
    required String userId,
    required String sessionId,
  }) async {
    final data = await _database.getDocument(
      FirestorePaths.session(userId, sessionId),
    );
    if (data == null) return null;
    return _decode(data, expectedId: sessionId, expectedUserId: userId);
  }

  @override
  Stream<List<StudySession>> watchRecentSessions(
    String userId, {
    int limit = 20,
  }) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100.');
    }
    return _database
        .watchCollection(
          path: FirestorePaths.sessions(userId),
          orderBy: 'updatedAt',
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

  StudySession _decode(
    Map<String, Object?> data, {
    required String expectedId,
    required String expectedUserId,
  }) {
    try {
      final session = StudySession.fromMap(data);
      if (session.id != expectedId || session.userId != expectedUserId) {
        throw const FormatException('Session ownership data is inconsistent.');
      }
      return session;
    } on FormatException catch (error) {
      throw AppException(
        type: AppErrorType.invalidDocument,
        message: 'A saved study session is malformed and cannot be opened.',
        cause: error,
      );
    } on ArgumentError catch (error) {
      throw AppException(
        type: AppErrorType.invalidDocument,
        message: 'A saved study session is malformed and cannot be opened.',
        cause: error,
      );
    }
  }
}
