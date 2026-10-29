import 'package:flutter/foundation.dart';

import '../../../core/config/ai_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../tutor/domain/study_message.dart';
import '../domain/document_analysis_repository.dart';
import '../domain/document_intake_service.dart';
import '../domain/document_study_action.dart';
import 'document_analysis_state.dart';

class DocumentAnalysisController extends ChangeNotifier {
  DocumentAnalysisController(
    this._userId,
    this._intakeService,
    this._repository,
  );

  final String _userId;
  final DocumentIntakeService _intakeService;
  final DocumentAnalysisRepository _repository;
  DocumentAnalysisState _state = const DocumentAnalysisState();
  StudyMessage? _pendingRequest;
  List<StudyMessage> _pendingHistory = const [];
  DocumentStudyAction _pendingAction = DocumentStudyAction.question;
  String? _completedAnswerAwaitingSave;
  String? _pendingAnswerMessageId;
  int _requestToken = 0;
  bool _disposed = false;

  DocumentAnalysisState get state => _state;

  Future<void> selectPdf() async {
    if (_state.isBusy) return;
    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: DocumentAnalysisStatus.selecting,
        clearError: true,
        canRetry: false,
      ),
    );
    try {
      final document = await _intakeService.selectPdf();
      if (!_isCurrent(token)) return;
      _setState(
        _state.copyWith(
          status: DocumentAnalysisStatus.ready,
          document: document,
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      if (_isCurrent(token)) _finishError(error.message, canRetry: false);
    } catch (_) {
      if (_isCurrent(token)) {
        _finishError(
          'StudyLens could not open the document picker. Please try again.',
          canRetry: false,
        );
      }
    }
  }

  void removeDocument() {
    if (_state.isBusy) return;
    _requestToken += 1;
    _pendingRequest = null;
    _pendingHistory = const [];
    _completedAnswerAwaitingSave = null;
    _pendingAnswerMessageId = null;
    _setState(const DocumentAnalysisState());
  }

  Future<bool> submit(
    String value, {
    DocumentStudyAction action = DocumentStudyAction.question,
  }) async {
    final document = _state.document;
    if (_state.isBusy || _pendingRequest != null || document == null) {
      return false;
    }
    final request = value.trim();
    if (request.isEmpty) {
      _finishError('Enter a question about the PDF first.', canRetry: false);
      return false;
    }
    if (request.length > AiConfig.tutorMaxQuestionCharacters) {
      _finishError(
        'That request is too long. Shorten it and try again.',
        canRetry: false,
      );
      return false;
    }

    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: DocumentAnalysisStatus.savingRequest,
        clearError: true,
        canRetry: false,
      ),
    );
    try {
      var sessionId = _state.sessionId;
      if (sessionId == null) {
        final session = await _repository.createDocumentSession(
          userId: _userId,
          document: document,
        );
        if (!_isCurrent(token)) return false;
        sessionId = session.id;
      }
      _pendingHistory = List.unmodifiable(_state.messages);
      _pendingAction = action;
      final message = await _repository.saveStudentRequest(
        userId: _userId,
        sessionId: sessionId,
        request: request,
      );
      if (!_isCurrent(token)) return false;
      _pendingRequest = message;
      _setState(
        _state.copyWith(
          status: DocumentAnalysisStatus.streaming,
          sessionId: sessionId,
          messages: [..._state.messages, message],
          streamingText: '',
          clearError: true,
        ),
      );
      await _streamPendingAnswer(token);
      return _state.errorMessage == null;
    } on AppException catch (error) {
      if (_isCurrent(token)) _finishError(error.message, canRetry: false);
      return false;
    } catch (_) {
      if (_isCurrent(token)) {
        _finishError(
          'StudyLens could not save your request. Please try again.',
          canRetry: false,
        );
      }
      return false;
    }
  }

  Future<void> retry() async {
    if (_state.isBusy || _pendingRequest == null) return;
    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: _completedAnswerAwaitingSave == null
            ? DocumentAnalysisStatus.streaming
            : DocumentAnalysisStatus.savingAnswer,
        streamingText: _completedAnswerAwaitingSave ?? '',
        clearError: true,
        canRetry: false,
      ),
    );
    if (_completedAnswerAwaitingSave case final answer?) {
      await _saveAnswer(answer, token);
    } else {
      await _streamPendingAnswer(token);
    }
  }

  Future<void> _streamPendingAnswer(int token) async {
    final request = _pendingRequest;
    final document = _state.document;
    if (request == null || document == null || _state.sessionId == null) return;
    final buffer = StringBuffer();
    try {
      await for (final chunk in _repository.streamAnswer(
        document: document,
        request: request.content,
        action: _pendingAction,
        history: _pendingHistory,
      )) {
        if (!_isCurrent(token)) return;
        buffer.write(chunk);
        _setState(
          _state.copyWith(
            status: DocumentAnalysisStatus.streaming,
            streamingText: buffer.toString(),
            clearError: true,
          ),
        );
      }
      if (!_isCurrent(token)) return;
      final answer = buffer.toString().trim();
      if (answer.isEmpty) {
        throw const AppException(
          type: AppErrorType.malformedResponse,
          message: 'StudyLens received an empty AI response. Please try again.',
        );
      }
      _completedAnswerAwaitingSave = answer;
      _setState(_state.copyWith(status: DocumentAnalysisStatus.savingAnswer));
      await _saveAnswer(answer, token);
    } on AppException catch (error) {
      if (_isCurrent(token)) _finishError(error.message, canRetry: true);
    } catch (_) {
      if (_isCurrent(token)) {
        _finishError(
          'StudyLens could not analyze this PDF right now. Try again.',
          canRetry: true,
        );
      }
    }
  }

  Future<void> _saveAnswer(String answer, int token) async {
    final request = _pendingRequest;
    final sessionId = _state.sessionId;
    if (request == null || sessionId == null) return;
    final messageId = _pendingAnswerMessageId ??= 'answer_${request.id}';
    try {
      final message = await _repository.saveAssistantAnswer(
        userId: _userId,
        sessionId: sessionId,
        answer: answer,
        messageId: messageId,
      );
      if (!_isCurrent(token)) return;
      _pendingRequest = null;
      _pendingHistory = const [];
      _completedAnswerAwaitingSave = null;
      _pendingAnswerMessageId = null;
      _setState(
        _state.copyWith(
          status: DocumentAnalysisStatus.ready,
          messages: [..._state.messages, message],
          streamingText: '',
          clearError: true,
          canRetry: false,
        ),
      );
    } on AppException catch (error) {
      if (_isCurrent(token)) {
        _finishError(
          '${error.message} The answer is visible but has not been saved.',
          canRetry: true,
          visibleAnswer: answer,
        );
      }
    } catch (_) {
      if (_isCurrent(token)) {
        _finishError(
          'The answer is visible but could not be saved. Please try again.',
          canRetry: true,
          visibleAnswer: answer,
        );
      }
    }
  }

  void clearError() {
    if (_state.errorMessage == null || _state.canRetry) return;
    _setState(_state.copyWith(clearError: true));
  }

  void _finishError(
    String message, {
    required bool canRetry,
    String visibleAnswer = '',
  }) {
    _setState(
      _state.copyWith(
        status: DocumentAnalysisStatus.ready,
        streamingText: visibleAnswer,
        errorMessage: message,
        canRetry: canRetry,
      ),
    );
  }

  bool _isCurrent(int token) => !_disposed && token == _requestToken;

  void _setState(DocumentAnalysisState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestToken += 1;
    super.dispose();
  }
}
