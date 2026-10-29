import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/quiz.dart';
import '../domain/quiz_generation_repository.dart';
import '../domain/quiz_generation_request.dart';
import 'quiz_generation_state.dart';

class QuizGenerationController extends ChangeNotifier {
  QuizGenerationController(this._userId, this._repository);

  final String _userId;
  final QuizGenerationRepository _repository;
  QuizGenerationState _state = const QuizGenerationState();
  QuizGenerationRequest? _pendingRequest;
  Quiz? _pendingQuiz;
  int _requestToken = 0;
  bool _disposed = false;

  QuizGenerationState get state => _state;

  Future<bool> generate({
    required String sourceMaterial,
    required int questionCount,
    required QuizDifficulty difficulty,
    String? sessionId,
  }) async {
    if (_state.isBusy) return false;
    late final QuizGenerationRequest request;
    try {
      request = QuizGenerationRequest(
        sourceMaterial: sourceMaterial,
        questionCount: questionCount,
        difficulty: difficulty,
        sessionId: sessionId,
      );
    } on ArgumentError catch (error) {
      _setError(_inputMessage(error), canRetry: false);
      return false;
    }
    _pendingRequest = request;
    _pendingQuiz = null;
    return _runGeneration(request);
  }

  Future<void> retry() async {
    if (_state.isBusy || _pendingRequest == null) return;
    if (_pendingQuiz case final quiz?) {
      await _saveQuiz(quiz, ++_requestToken);
    } else {
      await _runGeneration(_pendingRequest!);
    }
  }

  void startOver() {
    if (_state.isBusy) return;
    _requestToken += 1;
    _pendingRequest = null;
    _pendingQuiz = null;
    _setState(const QuizGenerationState());
  }

  void clearError() {
    if (_state.errorMessage == null || _state.canRetry) return;
    _setState(_state.copyWith(clearError: true));
  }

  Future<bool> _runGeneration(QuizGenerationRequest request) async {
    final token = ++_requestToken;
    _setState(
      _state.copyWith(
        status: QuizGenerationStatus.generating,
        clearQuiz: true,
        clearError: true,
        canRetry: false,
      ),
    );
    try {
      final quiz = await _repository.generate(
        userId: _userId,
        request: request,
      );
      if (!_isCurrent(token)) return false;
      _pendingQuiz = quiz;
      _setState(
        _state.copyWith(
          status: QuizGenerationStatus.saving,
          quiz: quiz,
          clearError: true,
        ),
      );
      return _saveQuiz(quiz, token);
    } on AppException catch (error) {
      if (_isCurrent(token)) _setError(error.message, canRetry: true);
      return false;
    } catch (_) {
      if (_isCurrent(token)) {
        _setError(
          'StudyLens could not generate the quiz. Please try again.',
          canRetry: true,
        );
      }
      return false;
    }
  }

  Future<bool> _saveQuiz(Quiz quiz, int token) async {
    if (_isCurrent(token)) {
      _setState(
        _state.copyWith(
          status: QuizGenerationStatus.saving,
          quiz: quiz,
          clearError: true,
          canRetry: false,
        ),
      );
    }
    try {
      await _repository.save(quiz);
      if (!_isCurrent(token)) return false;
      _pendingRequest = null;
      _pendingQuiz = null;
      _setState(
        _state.copyWith(
          status: QuizGenerationStatus.success,
          quiz: quiz,
          clearError: true,
          canRetry: false,
        ),
      );
      return true;
    } on AppException catch (error) {
      if (_isCurrent(token)) {
        _setError(
          '${error.message} The validated quiz has not been saved.',
          canRetry: true,
          quiz: quiz,
        );
      }
      return false;
    } catch (_) {
      if (_isCurrent(token)) {
        _setError(
          'The validated quiz could not be saved. Please try again.',
          canRetry: true,
          quiz: quiz,
        );
      }
      return false;
    }
  }

  String _inputMessage(ArgumentError error) {
    final text = error.message?.toString();
    return text == null || text.isEmpty
        ? 'Check the quiz settings and try again.'
        : text;
  }

  void _setError(String message, {required bool canRetry, Quiz? quiz}) {
    _setState(
      _state.copyWith(
        status: QuizGenerationStatus.ready,
        quiz: quiz,
        errorMessage: message,
        canRetry: canRetry,
      ),
    );
  }

  bool _isCurrent(int token) => !_disposed && token == _requestToken;

  void _setState(QuizGenerationState value) {
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
