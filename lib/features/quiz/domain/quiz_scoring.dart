import 'quiz.dart';
import 'quiz_result.dart';

abstract final class QuizScoring {
  /// XP is awarded only for correct answers. A quiz result is capped well below
  /// the Firestore rule limit of 1000 XP.
  static const xpPerCorrectAnswer = 10;

  static QuizResult grade({
    required Quiz quiz,
    required String userId,
    required String resultId,
    required List<int> selectedOptionIndexes,
    required DateTime completedAt,
  }) {
    if (selectedOptionIndexes.length != quiz.questions.length) {
      throw ArgumentError(
        'Answer every question before submitting the quiz.',
      );
    }

    var correctAnswers = 0;
    for (var index = 0; index < quiz.questions.length; index++) {
      final question = quiz.questions[index];
      final selected = selectedOptionIndexes[index];
      if (selected < 0 || selected >= question.options.length) {
        throw ArgumentError(
          'Question ${index + 1} has an answer outside its options.',
        );
      }
      if (selected == question.correctOptionIndex) {
        correctAnswers += 1;
      }
    }

    return QuizResult(
      id: resultId,
      userId: userId,
      quizId: quiz.id,
      sessionId: quiz.sessionId,
      selectedOptionIndexes: selectedOptionIndexes,
      correctAnswers: correctAnswers,
      completedAt: completedAt,
      xpEarned: correctAnswers * xpPerCorrectAnswer,
    );
  }
}
