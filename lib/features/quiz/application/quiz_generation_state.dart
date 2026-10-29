import '../domain/quiz.dart';

enum QuizGenerationStatus { ready, generating, saving, success }

class QuizGenerationState {
  const QuizGenerationState({
    this.status = QuizGenerationStatus.ready,
    this.quiz,
    this.errorMessage,
    this.canRetry = false,
  });

  final QuizGenerationStatus status;
  final Quiz? quiz;
  final String? errorMessage;
  final bool canRetry;

  bool get isBusy =>
      status == QuizGenerationStatus.generating ||
      status == QuizGenerationStatus.saving;

  QuizGenerationState copyWith({
    QuizGenerationStatus? status,
    Quiz? quiz,
    bool clearQuiz = false,
    String? errorMessage,
    bool clearError = false,
    bool? canRetry,
  }) => QuizGenerationState(
    status: status ?? this.status,
    quiz: clearQuiz ? null : quiz ?? this.quiz,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    canRetry: canRetry ?? this.canRetry,
  );
}
