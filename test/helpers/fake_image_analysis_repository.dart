import 'package:studylens_ai/core/ai/ai_explanation_mode.dart';
import 'package:studylens_ai/features/scan/domain/image_analysis_repository.dart';
import 'package:studylens_ai/features/scan/domain/study_image.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';

class FakeImageAnalysisRepository implements ImageAnalysisRepository {
  int _messageCount = 0;

  @override
  Future<StudySession> createImageSession({
    required String userId,
    required StudyImage image,
  }) async {
    final now = DateTime.utc(2026, 8, 23);
    return StudySession(
      id: 'image-session-1',
      userId: userId,
      title: 'Image: ${image.name}',
      materialType: StudyMaterialType.image,
      status: StudySessionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  }) async => _message(userId, sessionId, StudyMessageRole.student, question);

  @override
  Stream<String> streamAnswer({
    required StudyImage image,
    required String question,
    required AiExplanationMode mode,
    required List<StudyMessage> history,
  }) async* {
    yield 'The image shows educational material about $question';
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) async => _message(
    userId,
    sessionId,
    StudyMessageRole.assistant,
    answer,
    messageId,
  );

  StudyMessage _message(
    String userId,
    String sessionId,
    StudyMessageRole role,
    String content, [
    String? messageId,
  ]) {
    _messageCount += 1;
    return StudyMessage(
      id: messageId ?? 'image-message-$_messageCount',
      userId: userId,
      sessionId: sessionId,
      role: role,
      content: content,
      createdAt: DateTime.utc(2026, 8, 23, 0, _messageCount),
    );
  }
}
