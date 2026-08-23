import 'study_message.dart';

abstract interface class StudyMessageRepository {
  Future<void> saveMessage(StudyMessage message);

  Stream<List<StudyMessage>> watchMessages({
    required String userId,
    required String sessionId,
  });
}
