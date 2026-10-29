abstract final class AiConfig {
  /// Kept in one place so a supported Firebase AI Logic model can be changed
  /// without touching feature code.
  static const defaultModel = 'gemini-2.5-flash';
  static const temperature = 0.35;
  static const maxOutputTokens = 2048;
  static const conversationHistoryLimit = 12;
  static const tutorMaxQuestionCharacters = 4000;
  static const quizMaxSourceCharacters = 8000;
  static const quizMinQuestions = 5;
  static const quizMaxQuestions = 15;
  static const quizTemperature = 0.2;
  static const quizMaxOutputTokens = 8192;

  /// Maximum silence between streamed chunks before the request is treated as
  /// stalled. The timer resets on every received chunk.
  static const streamIdleTimeout = Duration(seconds: 60);

  /// Maximum total time for a non-streamed quiz generation request.
  static const quizGenerationTimeout = Duration(seconds: 120);
}
