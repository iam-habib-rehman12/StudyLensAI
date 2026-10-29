import '../../../core/ai/ai_chat_message.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/config/ai_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id_generator.dart';
import '../../study/domain/study_session.dart';
import '../../study/domain/study_session_repository.dart';
import '../../tutor/domain/study_message.dart';
import '../../tutor/domain/study_message_repository.dart';
import '../domain/document_analysis_repository.dart';
import '../domain/document_study_action.dart';
import '../domain/study_document.dart';

class FirebaseDocumentAnalysisRepository implements DocumentAnalysisRepository {
  FirebaseDocumentAnalysisRepository(
    this._aiService,
    this._sessionRepository,
    this._messageRepository,
    this._idGenerator, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AiService _aiService;
  final StudySessionRepository _sessionRepository;
  final StudyMessageRepository _messageRepository;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  @override
  Future<StudySession> createDocumentSession({
    required String userId,
    required StudyDocument document,
  }) async {
    final now = _now().toUtc();
    final cleanName = document.name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final available = cleanName.isEmpty
        ? 'PDF study session'
        : 'PDF: $cleanName';
    final session = StudySession(
      id: _idGenerator.next('session'),
      userId: userId,
      title: available.length > 120
          ? '${available.substring(0, 117)}...'
          : available,
      materialType: StudyMaterialType.pdf,
      status: StudySessionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await _sessionRepository.createSession(session);
    return session;
  }

  @override
  Future<StudyMessage> saveStudentRequest({
    required String userId,
    required String sessionId,
    required String request,
  }) => _saveMessage(
    userId: userId,
    sessionId: sessionId,
    role: StudyMessageRole.student,
    content: _validateRequest(request),
  );

  @override
  Stream<String> streamAnswer({
    required StudyDocument document,
    required String request,
    required DocumentStudyAction action,
    required List<StudyMessage> history,
  }) => _aiService.streamDocumentResponse(
    documentBytes: document.bytes,
    question: _validateRequest(request),
    action: action.label,
    history: history
        .map(
          (message) => AiChatMessage(
            role: message.role == StudyMessageRole.student
                ? AiChatRole.student
                : AiChatRole.assistant,
            content: message.content,
          ),
        )
        .toList(growable: false),
  );

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) => _saveMessage(
    userId: userId,
    sessionId: sessionId,
    role: StudyMessageRole.assistant,
    content: _validateAnswer(answer),
    messageId: messageId,
  );

  Future<StudyMessage> _saveMessage({
    required String userId,
    required String sessionId,
    required StudyMessageRole role,
    required String content,
    String? messageId,
  }) async {
    final message = StudyMessage(
      id: messageId ?? _idGenerator.next('message'),
      userId: userId,
      sessionId: sessionId,
      role: role,
      content: content,
      createdAt: _now().toUtc(),
    );
    await _messageRepository.saveMessage(message);
    return message;
  }

  String _validateRequest(String value) {
    final request = value.trim();
    if (request.isEmpty ||
        request.length > AiConfig.tutorMaxQuestionCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter a shorter, non-empty request about the PDF.',
      );
    }
    return request;
  }

  String _validateAnswer(String value) {
    final answer = value.trim();
    if (answer.isEmpty) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'StudyLens received an empty AI response. Please try again.',
      );
    }
    return answer;
  }
}
