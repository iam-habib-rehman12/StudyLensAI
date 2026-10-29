import 'quiz.dart';
import 'quiz_generation_request.dart';

abstract interface class QuizGenerationRepository {
  Future<Quiz> generate({
    required String userId,
    required QuizGenerationRequest request,
  });

  Future<void> save(Quiz quiz);
}
