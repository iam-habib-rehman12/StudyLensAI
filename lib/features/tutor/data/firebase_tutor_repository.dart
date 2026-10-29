import '../../../core/ai/ai_chat_message.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/config/ai_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id_generator.dart';
import '../../study/domain/study_session.dart';
import '../../study/domain/study_session_repository.dart';
import '../domain/study_message.dart';
import '../domain/study_message_repository.dart';
import '../domain/tutor_repository.dart';

class FirebaseTutorRepository implements TutorRepository {
  FirebaseTutorRepository(
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
  Future<StudySession> createTextSession({
    required String userId,
    required String initialQuestion,
  }) async {
    final question = _validatedQuestion(initialQuestion);
    final timestamp = _now().toUtc();
    final session = StudySession(
      id: _idGenerator.next('session'),
      userId: userId,
      title: _titleFrom(question),
      materialType: StudyMaterialType.text,
      status: StudySessionStatus.active,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _sessionRepository.createSession(session);
    return session;
  }

  @override
  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  }) async {
    final message = StudyMessage(
      id: _idGenerator.next('message'),
      userId: userId,
      sessionId: sessionId,
      role: StudyMessageRole.student,
      content: _validatedQuestion(question),
      createdAt: _now().toUtc(),
    );
    await _messageRepository.saveMessage(message);
    return message;
  }

  @override
  Stream<String> streamAnswer({
    required String question,
    required List<StudyMessage> history,
  }) {
    final aiHistory = history
        .map(
          (message) => AiChatMessage(
            role: message.role == StudyMessageRole.student
                ? AiChatRole.student
                : AiChatRole.assistant,
            content: message.content,
          ),
        )
        .toList(growable: false);
    return _aiService.streamTutorResponse(
      question: _validatedQuestion(question),
      history: aiHistory,
    );
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) async {
    final content = answer.trim();
    if (content.isEmpty) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message:
            'StudyLens received an empty AI response. Please try your question again.',
      );
    }
    final message = StudyMessage(
      id: messageId ?? _idGenerator.next('message'),
      userId: userId,
      sessionId: sessionId,
      role: StudyMessageRole.assistant,
      content: content,
      createdAt: _now().toUtc(),
    );
    await _messageRepository.saveMessage(message);
    return message;
  }

  String _validatedQuestion(String value) {
    final question = value.trim();
    if (question.isEmpty) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter a study question first.',
      );
    }
    if (question.length > AiConfig.tutorMaxQuestionCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'That question is too long. Shorten it and try again.',
      );
    }
    return question;
  }

  String _titleFrom(String question) {
    final normalized = question.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 72) return normalized;
    return '${normalized.substring(0, 69).trimRight()}...';
  }
}
