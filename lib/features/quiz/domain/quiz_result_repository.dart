import 'quiz_result.dart';

abstract interface class QuizResultRepository {
  Future<void> saveResult(QuizResult result);

  Stream<List<QuizResult>> watchRecentResults(String userId, {int limit = 20});
}
