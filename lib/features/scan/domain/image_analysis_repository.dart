import '../../../core/ai/ai_explanation_mode.dart';
import '../../study/domain/study_session.dart';
import '../../tutor/domain/study_message.dart';
import 'study_image.dart';

abstract interface class ImageAnalysisRepository {
  Future<StudySession> createImageSession({
    required String userId,
    required StudyImage image,
  });

  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  });

  Stream<String> streamAnswer({
    required StudyImage image,
    required String question,
    required AiExplanationMode mode,
    required List<StudyMessage> history,
  });

  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  });
}
