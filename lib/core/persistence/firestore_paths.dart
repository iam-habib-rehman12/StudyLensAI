abstract final class FirestorePaths {
  static String user(String userId) => 'users/${_segment(userId, 'userId')}';

  static String sessions(String userId) => '${user(userId)}/sessions';

  static String session(String userId, String sessionId) =>
      '${sessions(userId)}/${_segment(sessionId, 'sessionId')}';

  static String messages(String userId, String sessionId) =>
      '${session(userId, sessionId)}/messages';

  static String message(String userId, String sessionId, String messageId) =>
      '${messages(userId, sessionId)}/${_segment(messageId, 'messageId')}';

  static String quizzes(String userId) => '${user(userId)}/quizzes';

  static String quiz(String userId, String quizId) =>
      '${quizzes(userId)}/${_segment(quizId, 'quizId')}';

  static String quizResults(String userId) => '${user(userId)}/quizResults';

  static String quizResult(String userId, String resultId) =>
      '${quizResults(userId)}/${_segment(resultId, 'resultId')}';

  static String _segment(String value, String name) {
    final segment = value.trim();
    if (segment.isEmpty || segment.contains('/')) {
      throw ArgumentError.value(
        value,
        name,
        'Must be one non-empty path segment.',
      );
    }
    return segment;
  }
}
