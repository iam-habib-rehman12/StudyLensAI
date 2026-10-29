import '../../study/domain/study_session.dart';
import '../../tutor/domain/study_message.dart';
import 'document_study_action.dart';
import 'study_document.dart';

abstract interface class DocumentAnalysisRepository {
  Future<StudySession> createDocumentSession({
    required String userId,
    required StudyDocument document,
  });

  Future<StudyMessage> saveStudentRequest({
    required String userId,
    required String sessionId,
    required String request,
  });

  Stream<String> streamAnswer({
    required StudyDocument document,
    required String request,
    required DocumentStudyAction action,
    required List<StudyMessage> history,
  });

  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  });
}
