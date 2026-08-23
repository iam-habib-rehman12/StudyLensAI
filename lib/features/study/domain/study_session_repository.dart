import 'study_session.dart';

abstract interface class StudySessionRepository {
  Future<void> createSession(StudySession session);

  Future<void> completeSession({
    required String userId,
    required String sessionId,
  });

  Future<StudySession?> getSession({
    required String userId,
    required String sessionId,
  });

  Stream<List<StudySession>> watchRecentSessions(
    String userId, {
    int limit = 20,
  });
}
