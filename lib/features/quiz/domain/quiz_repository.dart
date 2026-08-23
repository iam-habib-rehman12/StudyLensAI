import 'quiz.dart';

abstract interface class QuizRepository {
  Future<void> saveQuiz(Quiz quiz);

  Future<Quiz?> getQuiz({required String userId, required String quizId});

  Stream<List<Quiz>> watchRecentQuizzes(String userId, {int limit = 20});
}
