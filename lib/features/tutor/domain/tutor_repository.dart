import '../../study/domain/study_session.dart';
import 'study_message.dart';

abstract interface class TutorRepository {
  Future<StudySession> createTextSession({
    required String userId,
    required String initialQuestion,
  });

  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  });

  Stream<String> streamAnswer({
    required String question,
    required List<StudyMessage> history,
  });

  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  });
}
