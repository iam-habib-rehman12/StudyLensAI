import '../domain/quiz_result.dart';

enum QuizPlayerStatus { answering, submitting, reviewed, completed }

class QuizPlayerState {
  const QuizPlayerState({
    required this.selectedAnswers,
    this.status = QuizPlayerStatus.answering,
    this.currentIndex = 0,
    this.result,
    this.errorMessage,
    this.canRetry = false,
  });

  final QuizPlayerStatus status;
  final int currentIndex;
  final List<int?> selectedAnswers;
  final QuizResult? result;
  final String? errorMessage;
  final bool canRetry;

  bool get isBusy => status == QuizPlayerStatus.submitting;
  bool get isFinished => result != null;
  bool get isSaved => status == QuizPlayerStatus.completed;
  int get answeredCount =>
      selectedAnswers.where((answer) => answer != null).length;
  bool get allAnswered => answeredCount == selectedAnswers.length;

  QuizPlayerState copyWith({
    QuizPlayerStatus? status,
    int? currentIndex,
    List<int?>? selectedAnswers,
    QuizResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
    bool? canRetry,
  }) => QuizPlayerState(
    status: status ?? this.status,
    currentIndex: currentIndex ?? this.currentIndex,
    selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    result: clearResult ? null : result ?? this.result,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    canRetry: canRetry ?? this.canRetry,
  );
}
