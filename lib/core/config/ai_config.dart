abstract final class AiConfig {
  /// Kept in one place so a supported Firebase AI Logic model can be changed
  /// without touching feature code.
  static const defaultModel = 'gemini-2.5-flash';
  static const temperature = 0.35;
  static const maxOutputTokens = 2048;
  static const conversationHistoryLimit = 12;
  static const tutorMaxQuestionCharacters = 4000;
}
