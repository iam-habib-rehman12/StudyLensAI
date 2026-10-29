import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/quiz.dart';
import '../domain/quiz_result.dart';
import '../domain/quiz_result_repository.dart';
import '../domain/quiz_scoring.dart';
import 'quiz_player_state.dart';

class QuizPlayerController extends ChangeNotifier {
  QuizPlayerController(
    this.quiz,
    this._userId,
    this._repository,
    this._idGenerator, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _state = QuizPlayerState(
         selectedAnswers: List<int?>.filled(quiz.questions.length, null),
       );

  final Quiz quiz;
  final String _userId;
  final QuizResultRepository _repository;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  QuizPlayerState _state;
  QuizResult? _pendingResult;
  String? _pendingResultId;
  bool _saving = false;
  bool _disposed = false;

  QuizPlayerState get state => _state;
  int get questionCount => quiz.questions.length;
  bool get canSubmit =>
      _state.status == QuizPlayerStatus.answering && _state.allAnswered;

  void selectAnswer(int optionIndex) {
    if (_state.status != QuizPlayerStatus.answering) return;
    final question = quiz.questions[_state.currentIndex];
    if (optionIndex < 0 || optionIndex >= question.options.length) return;
    final answers = List<int?>.from(_state.selectedAnswers);
    answers[_state.currentIndex] = optionIndex;
    _setState(
      _state.copyWith(selectedAnswers: answers, clearError: true),
    );
  }

  void nextQuestion() {
    if (_state.status != QuizPlayerStatus.answering) return;
    if (_state.currentIndex + 1 >= questionCount) return;
    _setState(_state.copyWith(currentIndex: _state.currentIndex + 1));
  }

  void previousQuestion() {
    if (_state.status != QuizPlayerStatus.answering) return;
    if (_state.currentIndex == 0) return;
    _setState(_state.copyWith(currentIndex: _state.currentIndex - 1));
  }

  void goToQuestion(int index) {
    if (_state.status != QuizPlayerStatus.answering) return;
    if (index < 0 || index >= questionCount) return;
    _setState(_state.copyWith(currentIndex: index));
  }

  Future<bool> submit() async {
    if (_state.status != QuizPlayerStatus.answering || _saving) return false;
    final selectedAnswers = _state.selectedAnswers;
    if (selectedAnswers.any((answer) => answer == null)) {
      _setState(
        _state.copyWith(
          errorMessage: 'Answer every question before submitting.',
          canRetry: false,
        ),
      );
      return false;
    }

    final resultId = _pendingResultId ??= _idGenerator.next('result');
    late final QuizResult result;
    try {
      result = QuizScoring.grade(
        quiz: quiz,
        userId: _userId,
        resultId: resultId,
        selectedOptionIndexes: selectedAnswers.cast<int>().toList(
          growable: false,
        ),
        completedAt: _now().toUtc(),
      );
    } on ArgumentError catch (error) {
      _setState(
        _state.copyWith(
          errorMessage:
              error.message?.toString() ??
              'Check every answer before submitting.',
          canRetry: false,
        ),
      );
      return false;
    }

    _pendingResult = result;
    _setState(
      _state.copyWith(
        status: QuizPlayerStatus.submitting,
        result: result,
        clearError: true,
        canRetry: false,
      ),
    );
    return _save(result);
  }

  Future<void> retrySave() async {
    final pending = _pendingResult;
    if (pending == null || _saving) return;
    _setState(
      _state.copyWith(
        status: QuizPlayerStatus.submitting,
        clearError: true,
        canRetry: false,
      ),
    );
    await _save(pending);
  }

  Future<bool> _save(QuizResult result) async {
    _saving = true;
    try {
      await _repository.saveResult(result);
      if (_disposed) return false;
      _pendingResult = null;
      _pendingResultId = null;
      _setState(
        _state.copyWith(
          status: QuizPlayerStatus.completed,
          result: result,
          clearError: true,
          canRetry: false,
        ),
      );
      return true;
    } on AppException catch (error) {
      _finishUnsaved(
        '${error.message} Your score is shown but has not been saved.',
      );
      return false;
    } catch (_) {
      _finishUnsaved(
        'Your score is shown but could not be saved. Please try again.',
      );
      return false;
    } finally {
      _saving = false;
    }
  }

  void _finishUnsaved(String message) {
    if (_disposed) return;
    _setState(
      _state.copyWith(
        status: QuizPlayerStatus.reviewed,
        errorMessage: message,
        canRetry: true,
      ),
    );
  }

  void _setState(QuizPlayerState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
