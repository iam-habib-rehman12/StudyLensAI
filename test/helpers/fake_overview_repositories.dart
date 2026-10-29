import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_repository.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/study/domain/study_session_repository.dart';

class FakeStudySessionRepository implements StudySessionRepository {
  FakeStudySessionRepository({
    this.sessions = const [],
    this.error,
    this.stream,
  });

  List<StudySession> sessions;
  Object? error;
  Stream<List<StudySession>>? stream;
  int watchCalls = 0;

  @override
  Future<void> createSession(StudySession session) async {}

  @override
  Future<void> completeSession({
    required String userId,
    required String sessionId,
  }) async {}

  @override
  Future<StudySession?> getSession({
    required String userId,
    required String sessionId,
  }) async => null;

  @override
  Stream<List<StudySession>> watchRecentSessions(
    String userId, {
    int limit = 20,
  }) {
    watchCalls += 1;
    if (stream case final value?) return value;
    if (error case final value?) return Stream.error(value);
    return Stream.value(sessions);
  }
}

class FakeQuizRepository implements QuizRepository {
  FakeQuizRepository({this.quizzes = const [], this.error, this.stream});

  List<Quiz> quizzes;
  Object? error;
  Stream<List<Quiz>>? stream;
  int watchCalls = 0;

  @override
  Future<void> saveQuiz(Quiz quiz) async {}

  @override
  Future<Quiz?> getQuiz({
    required String userId,
    required String quizId,
  }) async => null;

  @override
  Stream<List<Quiz>> watchRecentQuizzes(String userId, {int limit = 20}) {
    watchCalls += 1;
    if (stream case final value?) return value;
    if (error case final value?) return Stream.error(value);
    return Stream.value(quizzes);
  }
}
