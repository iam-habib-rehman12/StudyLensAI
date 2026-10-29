import 'package:flutter/foundation.dart';

import '../../../core/ai/ai_explanation_mode.dart';
import '../../../core/config/ai_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../tutor/domain/study_message.dart';
import '../domain/image_analysis_repository.dart';
import '../domain/study_image.dart';
import 'image_analysis_state.dart';

class ImageAnalysisController extends ChangeNotifier {
  ImageAnalysisController(this._userId, this.image, this._repository);

  final String _userId;
  final StudyImage image;
  final ImageAnalysisRepository _repository;
  ImageAnalysisState _state = const ImageAnalysisState();
  StudyMessage? _pendingQuestion;
  List<StudyMessage> _pendingHistory = const [];
  AiExplanationMode _pendingMode = AiExplanationMode.normal;
  String? _completedAnswerAwaitingSave;
  String? _pendingAnswerMessageId;
  int _requestToken = 0;
  bool _disposed = false;

  ImageAnalysisState get state => _state;

  void selectMode(AiExplanationMode mode) {
    if (_state.isBusy || _state.canRetry || mode == _state.mode) return;
    _setState(_state.copyWith(mode: mode));
  }

  Future<bool> sendQuestion(String value) async {
    if (_state.isBusy || _pendingQuestion != null) return false;
    final question = value.trim();
    if (question.isEmpty) {
      _inputError('Enter a question about the image first.');
      return false;
    }
    if (question.length > AiConfig.tutorMaxQuestionCharacters) {
      _inputError('That question is too long. Shorten it and try again.');
      return false;
    }

    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: ImageAnalysisStatus.savingQuestion,
        clearError: true,
        canRetry: false,
      ),
    );
    try {
      var sessionId = _state.sessionId;
      if (sessionId == null) {
        final session = await _repository.createImageSession(
          userId: _userId,
          image: image,
        );
        if (!_isCurrent(token)) return false;
        sessionId = session.id;
      }
      _pendingHistory = List.unmodifiable(_state.messages);
      _pendingMode = _state.mode;
      final message = await _repository.saveStudentQuestion(
        userId: _userId,
        sessionId: sessionId,
        question: question,
      );
      if (!_isCurrent(token)) return false;
      _pendingQuestion = message;
      _setState(
        _state.copyWith(
          status: ImageAnalysisStatus.streaming,
          sessionId: sessionId,
          messages: [..._state.messages, message],
          streamingText: '',
          clearError: true,
          canRetry: false,
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
          'StudyLens could not save your question. Please try again.',
          canRetry: false,
        );
      }
      return false;
    }
  }

  Future<void> retry() async {
    if (_state.isBusy || _pendingQuestion == null) return;
    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: _completedAnswerAwaitingSave == null
            ? ImageAnalysisStatus.streaming
            : ImageAnalysisStatus.savingAnswer,
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
    final question = _pendingQuestion;
    if (question == null || _state.sessionId == null) return;
    final buffer = StringBuffer();
    try {
      await for (final chunk in _repository.streamAnswer(
        image: image,
        question: question.content,
        mode: _pendingMode,
        history: _pendingHistory,
      )) {
        if (!_isCurrent(token)) return;
        buffer.write(chunk);
        _setState(
          _state.copyWith(
            status: ImageAnalysisStatus.streaming,
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
      _setState(_state.copyWith(status: ImageAnalysisStatus.savingAnswer));
      await _saveAnswer(answer, token);
    } on AppException catch (error) {
      if (_isCurrent(token)) _finishError(error.message, canRetry: true);
    } catch (_) {
      if (_isCurrent(token)) {
        _finishError(
          'StudyLens could not analyze the image right now. Try again.',
          canRetry: true,
        );
      }
    }
  }

  Future<void> _saveAnswer(String answer, int token) async {
    final pendingQuestion = _pendingQuestion;
    final sessionId = _state.sessionId;
    if (pendingQuestion == null || sessionId == null) return;
    final messageId = _pendingAnswerMessageId ??=
        'answer_${pendingQuestion.id}';
    try {
      final message = await _repository.saveAssistantAnswer(
        userId: _userId,
        sessionId: sessionId,
        answer: answer,
        messageId: messageId,
      );
      if (!_isCurrent(token)) return;
      _pendingQuestion = null;
      _pendingHistory = const [];
      _completedAnswerAwaitingSave = null;
      _pendingAnswerMessageId = null;
      _setState(
        _state.copyWith(
          status: ImageAnalysisStatus.ready,
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

  void _inputError(String message) => _finishError(message, canRetry: false);

  void _finishError(
    String message, {
    required bool canRetry,
    String visibleAnswer = '',
  }) {
    _setState(
      _state.copyWith(
        status: ImageAnalysisStatus.ready,
        streamingText: visibleAnswer,
        errorMessage: message,
        canRetry: canRetry,
      ),
    );
  }

  bool _isCurrent(int token) => !_disposed && token == _requestToken;

  void _setState(ImageAnalysisState value) {
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
