import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';
import 'package:studylens_ai/features/tutor/domain/tutor_repository.dart';

class FakeTutorRepository implements TutorRepository {
  final List<StudyMessage> savedMessages = [];
  int _messageCount = 0;

  @override
  Future<StudySession> createTextSession({
    required String userId,
    required String initialQuestion,
  }) async {
    final timestamp = DateTime.utc(2026, 8, 22);
    return StudySession(
      id: 'session-1',
      userId: userId,
      title: initialQuestion,
      materialType: StudyMaterialType.text,
      status: StudySessionStatus.active,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  @override
  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  }) async {
    final message = _message(
      userId: userId,
      sessionId: sessionId,
      role: StudyMessageRole.student,
      content: question,
    );
    savedMessages.add(message);
    return message;
  }

  @override
  Stream<String> streamAnswer({
    required String question,
    required List<StudyMessage> history,
  }) async* {
    yield 'A clear answer about $question';
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
  }) async {
    final message = _message(
      userId: userId,
      sessionId: sessionId,
      role: StudyMessageRole.assistant,
      content: answer,
    );
    savedMessages.add(message);
    return message;
  }

  StudyMessage _message({
    required String userId,
    required String sessionId,
    required StudyMessageRole role,
    required String content,
  }) {
    _messageCount += 1;
    return StudyMessage(
      id: 'message-$_messageCount',
      userId: userId,
      sessionId: sessionId,
      role: role,
      content: content,
      createdAt: DateTime.utc(2026, 8, 22, 0, _messageCount),
    );
  }
}
