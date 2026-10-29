import 'package:flutter/foundation.dart';

import '../../../core/config/ai_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/study_message.dart';
import '../domain/tutor_repository.dart';
import 'tutor_state.dart';

class TutorController extends ChangeNotifier {
  TutorController(this._userId, this._repository);

  final String _userId;
  final TutorRepository _repository;
  TutorState _state = const TutorState();
  StudyMessage? _pendingQuestion;
  List<StudyMessage> _pendingHistory = const [];
  String? _completedAnswerAwaitingSave;
  String? _pendingAnswerMessageId;
  int _requestToken = 0;
  bool _disposed = false;

  TutorState get state => _state;

  Future<bool> sendQuestion(String value) async {
    if (_state.isBusy || _pendingQuestion != null) return false;
    final question = value.trim();
    if (question.isEmpty) {
      _setInputError('Enter a study question first.');
      return false;
    }
    if (question.length > AiConfig.tutorMaxQuestionCharacters) {
      _setInputError('That question is too long. Shorten it and try again.');
      return false;
    }

    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: TutorStatus.savingQuestion,
        clearError: true,
        canRetry: false,
      ),
    );
    try {
      var sessionId = _state.sessionId;
      if (sessionId == null) {
        final session = await _repository.createTextSession(
          userId: _userId,
          initialQuestion: question,
        );
        if (!_isCurrent(token)) return false;
        sessionId = session.id;
      }

      _pendingHistory = List.unmodifiable(_state.messages);
      final studentMessage = await _repository.saveStudentQuestion(
        userId: _userId,
        sessionId: sessionId,
        question: question,
      );
      if (!_isCurrent(token)) return false;
      _pendingQuestion = studentMessage;
      _setState(
        _state.copyWith(
          status: TutorStatus.streaming,
          sessionId: sessionId,
          messages: [..._state.messages, studentMessage],
          streamingText: '',
          clearError: true,
          canRetry: false,
        ),
      );
      await _streamPendingAnswer(token);
      return _state.errorMessage == null;
    } on AppException catch (error) {
      if (_isCurrent(token)) _finishWithError(error.message, canRetry: false);
      return false;
    } catch (_) {
      if (_isCurrent(token)) {
        _finishWithError(
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
            ? TutorStatus.streaming
            : TutorStatus.savingAnswer,
        streamingText: _completedAnswerAwaitingSave ?? '',
        clearError: true,
        canRetry: false,
      ),
    );
    if (_completedAnswerAwaitingSave case final answer?) {
      await _saveCompletedAnswer(answer, token);
    } else {
      await _streamPendingAnswer(token);
    }
  }

  Future<void> _streamPendingAnswer(int token) async {
    final pendingQuestion = _pendingQuestion;
    final sessionId = _state.sessionId;
    if (pendingQuestion == null || sessionId == null) return;

    final buffer = StringBuffer();
    try {
      await for (final chunk in _repository.streamAnswer(
        question: pendingQuestion.content,
        history: _pendingHistory,
      )) {
        if (!_isCurrent(token)) return;
        buffer.write(chunk);
        _setState(
          _state.copyWith(
            status: TutorStatus.streaming,
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
          message:
              'StudyLens received an empty AI response. Please try your question again.',
        );
      }
      _completedAnswerAwaitingSave = answer;
      _setState(_state.copyWith(status: TutorStatus.savingAnswer));
      await _saveCompletedAnswer(answer, token);
    } on AppException catch (error) {
      if (_isCurrent(token)) {
        _setState(
          _state.copyWith(
            status: TutorStatus.ready,
            streamingText: '',
            errorMessage: error.message,
            canRetry: true,
          ),
        );
      }
    } catch (_) {
      if (_isCurrent(token)) {
        _setState(
          _state.copyWith(
            status: TutorStatus.ready,
            streamingText: '',
            errorMessage: 'StudyLens could not answer right now. Try again.',
            canRetry: true,
          ),
        );
      }
    }
  }

  Future<void> _saveCompletedAnswer(String answer, int token) async {
    final sessionId = _state.sessionId;
    final pendingQuestion = _pendingQuestion;
    if (sessionId == null || pendingQuestion == null) return;
    final messageId = _pendingAnswerMessageId ??=
        'answer_${pendingQuestion.id}';
    try {
      final assistantMessage = await _repository.saveAssistantAnswer(
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
          status: TutorStatus.ready,
          messages: [..._state.messages, assistantMessage],
          streamingText: '',
          clearError: true,
          canRetry: false,
        ),
      );
    } on AppException catch (error) {
      if (_isCurrent(token)) {
        _setState(
          _state.copyWith(
            status: TutorStatus.ready,
            streamingText: answer,
            errorMessage:
                '${error.message} The answer is visible but has not been saved.',
            canRetry: true,
          ),
        );
      }
    } catch (_) {
      if (_isCurrent(token)) {
        _setState(
          _state.copyWith(
            status: TutorStatus.ready,
            streamingText: answer,
            errorMessage:
                'The answer is visible but could not be saved. Please try again.',
            canRetry: true,
          ),
        );
      }
    }
  }

  void clearError() {
    if (_state.errorMessage == null || _state.canRetry) return;
    _setState(_state.copyWith(clearError: true));
  }

  void _setInputError(String message) {
    _setState(
      _state.copyWith(
        status: TutorStatus.ready,
        errorMessage: message,
        canRetry: false,
      ),
    );
  }

  void _finishWithError(String message, {required bool canRetry}) {
    _setState(
      _state.copyWith(
        status: TutorStatus.ready,
        errorMessage: message,
        canRetry: canRetry,
      ),
    );
  }

  bool _isCurrent(int token) => !_disposed && token == _requestToken;

  void _setState(TutorState value) {
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
