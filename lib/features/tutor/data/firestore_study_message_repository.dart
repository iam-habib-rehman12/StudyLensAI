import '../../../core/errors/app_exception.dart';
import '../../../core/persistence/document_database.dart';
import '../../../core/persistence/firestore_paths.dart';
import '../domain/study_message.dart';
import '../domain/study_message_repository.dart';

class FirestoreStudyMessageRepository implements StudyMessageRepository {
  const FirestoreStudyMessageRepository(this._database);

  final DocumentDatabase _database;

  @override
  Future<void> saveMessage(StudyMessage message) {
    final data = message.toMap()..['createdAt'] = serverTimestamp;
    return _database.setDocument(
      path: FirestorePaths.message(
        message.userId,
        message.sessionId,
        message.id,
      ),
      data: data,
    );
  }

  @override
  Stream<List<StudyMessage>> watchMessages({
    required String userId,
    required String sessionId,
  }) {
    return _database
        .watchCollection(
          path: FirestorePaths.messages(userId, sessionId),
          orderBy: 'createdAt',
        )
        .map(
          (documents) => documents
              .map((document) {
                try {
                  final message = StudyMessage.fromMap(document.data);
                  if (message.id != document.id ||
                      message.userId != userId ||
                      message.sessionId != sessionId) {
                    throw const FormatException(
                      'Message ownership data is inconsistent.',
                    );
                  }
                  return message;
                } on FormatException catch (error) {
                  throw AppException(
                    type: AppErrorType.invalidDocument,
                    message:
                        'A saved study message is malformed and cannot be shown.',
                    cause: error,
                  );
                } on ArgumentError catch (error) {
                  throw AppException(
                    type: AppErrorType.invalidDocument,
                    message:
                        'A saved study message is malformed and cannot be shown.',
                    cause: error,
                  );
                }
              })
              .toList(growable: false),
        );
  }
}
