import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_generation_repository.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_generation_request.dart';

class FakeQuizGenerationRepository implements QuizGenerationRepository {
  int generationCalls = 0;
  int saveCalls = 0;
  Object? generationError;
  Object? saveError;

  @override
  Future<Quiz> generate({
    required String userId,
    required QuizGenerationRequest request,
  }) async {
    generationCalls += 1;
    if (generationError case final error?) throw error;
    return Quiz(
      id: 'quiz-$generationCalls',
      userId: userId,
      sessionId: request.sessionId,
      title: 'Generated study quiz',
      questions: [
        for (var index = 0; index < request.questionCount; index++)
          QuizQuestion(
            id: 'question-$index',
            question: 'Question ${index + 1}?',
            options: const ['Correct', 'Option B', 'Option C', 'Option D'],
            correctOptionIndex: 0,
            explanation: 'The first option is correct.',
          ),
      ],
      createdAt: DateTime.utc(2026, 8, 24),
    );
  }

  @override
  Future<void> save(Quiz quiz) async {
    saveCalls += 1;
    if (saveError case final error?) throw error;
  }
}
