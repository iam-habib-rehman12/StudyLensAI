import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_result.dart';
import '../../study/domain/study_session.dart';

enum StudyOverviewStatus { loading, ready, failure }

class StudyOverviewState {
  const StudyOverviewState({
    this.status = StudyOverviewStatus.loading,
    this.sessions = const [],
    this.quizzes = const [],
    this.results = const [],
    this.errorMessage,
    this.isOffline = false,
  });

  final StudyOverviewStatus status;
  final List<StudySession> sessions;
  final List<Quiz> quizzes;
  final List<QuizResult> results;
  final String? errorMessage;
  final bool isOffline;

  bool get isLoading => status == StudyOverviewStatus.loading;
  bool get hasError => status == StudyOverviewStatus.failure;
  bool get isReady => status == StudyOverviewStatus.ready;
}
