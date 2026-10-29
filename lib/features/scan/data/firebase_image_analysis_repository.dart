import '../../../core/ai/ai_chat_message.dart';
import '../../../core/ai/ai_explanation_mode.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/config/ai_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id_generator.dart';
import '../../study/domain/study_session.dart';
import '../../study/domain/study_session_repository.dart';
import '../../tutor/domain/study_message.dart';
import '../../tutor/domain/study_message_repository.dart';
import '../domain/image_analysis_repository.dart';
import '../domain/study_image.dart';

class FirebaseImageAnalysisRepository implements ImageAnalysisRepository {
  FirebaseImageAnalysisRepository(
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
  Future<StudySession> createImageSession({
    required String userId,
    required StudyImage image,
  }) async {
    final now = _now().toUtc();
    final cleanName = image.name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final session = StudySession(
      id: _idGenerator.next('session'),
      userId: userId,
      title: cleanName.isEmpty
          ? 'Image study session'
          : 'Image: ${cleanName.length > 105 ? '${cleanName.substring(0, 102)}...' : cleanName}',
      materialType: StudyMaterialType.image,
      status: StudySessionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await _sessionRepository.createSession(session);
    return session;
  }

  @override
  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  }) => _saveMessage(
    userId: userId,
    sessionId: sessionId,
    role: StudyMessageRole.student,
    content: _validateQuestion(question),
  );

  @override
  Stream<String> streamAnswer({
    required StudyImage image,
    required String question,
    required AiExplanationMode mode,
    required List<StudyMessage> history,
  }) {
    final mimeType = image.resolvedMimeType;
    if (mimeType == null) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message:
            'This image format is unsupported. Choose a JPEG, PNG, or WebP image.',
      );
    }
    return _aiService.streamImageResponse(
      imageBytes: image.bytes,
      mimeType: mimeType,
      question: _validateQuestion(question),
      mode: mode,
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
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) {
    final content = answer.trim();
    if (content.isEmpty) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'StudyLens received an empty AI response. Please try again.',
      );
    }
    return _saveMessage(
      userId: userId,
      sessionId: sessionId,
      role: StudyMessageRole.assistant,
      content: content,
      messageId: messageId,
    );
  }

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

  String _validateQuestion(String value) {
    final question = value.trim();
    if (question.isEmpty ||
        question.length > AiConfig.tutorMaxQuestionCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter a shorter, non-empty question about the image.',
      );
    }
    return question;
  }
}
