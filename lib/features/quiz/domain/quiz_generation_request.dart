import '../../../core/config/ai_config.dart';

enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyLabel on QuizDifficulty {
  String get label => switch (this) {
    QuizDifficulty.easy => 'Easy',
    QuizDifficulty.medium => 'Medium',
    QuizDifficulty.hard => 'Hard',
  };
}

class QuizGenerationRequest {
  QuizGenerationRequest({
    required String sourceMaterial,
    required this.questionCount,
    required this.difficulty,
    this.sessionId,
  }) : sourceMaterial = sourceMaterial.trim() {
    if (this.sourceMaterial.isEmpty ||
        this.sourceMaterial.length > AiConfig.quizMaxSourceCharacters) {
      throw ArgumentError(
        'Quiz source material must contain 1 to 8,000 characters.',
      );
    }
    if (questionCount < AiConfig.quizMinQuestions ||
        questionCount > AiConfig.quizMaxQuestions) {
      throw ArgumentError('Quiz question count must be between 5 and 15.');
    }
    if (sessionId != null && sessionId!.trim().isEmpty) {
      throw ArgumentError('A supplied study session ID cannot be empty.');
    }
  }

  final String sourceMaterial;
  final int questionCount;
  final QuizDifficulty difficulty;
  final String? sessionId;
}
