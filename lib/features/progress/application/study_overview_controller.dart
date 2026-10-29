import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../history/domain/history_entry.dart';
import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_repository.dart';
import '../../quiz/domain/quiz_result.dart';
import '../../quiz/domain/quiz_result_repository.dart';
import '../../study/domain/study_session.dart';
import '../../study/domain/study_session_repository.dart';
import '../domain/progress_summary.dart';
import 'study_overview_state.dart';

class StudyOverviewController extends ChangeNotifier {
  StudyOverviewController(
    this._userId,
    this._sessionRepository,
    this._quizRepository,
    this._resultRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _subscribe();
  }

  final String _userId;
  final StudySessionRepository _sessionRepository;
  final QuizRepository _quizRepository;
  final QuizResultRepository _resultRepository;
  final DateTime Function() _now;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StudyOverviewState _state = const StudyOverviewState();
  List<StudySession> _sessions = const [];
  List<Quiz> _quizzes = const [];
  List<QuizResult> _results = const [];
  bool _sessionsLoaded = false;
  bool _quizzesLoaded = false;
  bool _resultsLoaded = false;
  int _generation = 0;
  bool _disposed = false;

  StudyOverviewState get state => _state;
  ProgressSummary get progress =>
      ProgressSummary.fromResults(_state.results, now: _now());
  List<HistoryEntry> get history => HistoryEntry.build(
    sessions: _state.sessions,
    quizzes: _state.quizzes,
    results: _state.results,
  );
  List<QuizResult> get recentResults =>
      _state.results.take(10).toList(growable: false);

  void retry() {
    if (_disposed) return;
    _cancelSubscriptions();
    _sessions = const [];
    _quizzes = const [];
    _results = const [];
    _subscribe();
  }

  void _subscribe() {
    final generation = ++_generation;
    _sessionsLoaded = false;
    _quizzesLoaded = false;
    _resultsLoaded = false;
    _setState(const StudyOverviewState());

    _subscriptions.add(
      _sessionRepository
          .watchRecentSessions(_userId, limit: 50)
          .listen(
            (sessions) => _onSessions(generation, sessions),
            onError: (Object error) => _onError(generation, error),
          ),
    );
    _subscriptions.add(
      _quizRepository.watchRecentQuizzes(_userId, limit: 50).listen(
        (quizzes) => _onQuizzes(generation, quizzes),
        onError: (Object error) => _onError(generation, error),
      ),
    );
    _subscriptions.add(
      _resultRepository.watchRecentResults(_userId, limit: 500).listen(
        (results) => _onResults(generation, results),
        onError: (Object error) => _onError(generation, error),
      ),
    );
  }

  void _onSessions(int generation, List<StudySession> sessions) {
    if (!_isCurrent(generation)) return;
    _sessions = sessions;
    _sessionsLoaded = true;
    _emitIfLoading();
  }

  void _onQuizzes(int generation, List<Quiz> quizzes) {
    if (!_isCurrent(generation)) return;
    _quizzes = quizzes;
    _quizzesLoaded = true;
    _emitIfLoading();
  }

  void _onResults(int generation, List<QuizResult> results) {
    if (!_isCurrent(generation)) return;
    _results = results;
    _resultsLoaded = true;
    _emitIfLoading();
  }

  void _emitIfLoading() {
    if (_disposed) return;
    final ready = _sessionsLoaded && _quizzesLoaded && _resultsLoaded;
    _setState(
      StudyOverviewState(
        status: ready
            ? StudyOverviewStatus.ready
            : StudyOverviewStatus.loading,
        sessions: _sessions,
        quizzes: _quizzes,
        results: _results,
      ),
    );
  }

  void _onError(int generation, Object error) {
    if (!_isCurrent(generation)) return;
    _generation += 1;
    _cancelSubscriptions();
    final failure = error is AppException ? error : null;
    _setState(
      StudyOverviewState(
        status: StudyOverviewStatus.failure,
        sessions: _sessions,
        quizzes: _quizzes,
        results: _results,
        errorMessage:
            failure?.message ??
            'StudyLens could not load your study activity. Please try again.',
        isOffline: failure?.type == AppErrorType.offline,
      ),
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _setState(StudyOverviewState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    _cancelSubscriptions();
    super.dispose();
  }
}
