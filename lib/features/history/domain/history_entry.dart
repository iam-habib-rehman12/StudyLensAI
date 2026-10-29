import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_result.dart';
import '../../study/domain/study_session.dart';

enum HistoryEntryKind { textSession, imageSession, pdfSession, quizResult }

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final String id;
  final HistoryEntryKind kind;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  static List<HistoryEntry> build({
    required List<StudySession> sessions,
    required List<Quiz> quizzes,
    required List<QuizResult> results,
    int limit = 50,
  }) {
    final quizzesById = <String, Quiz>{
      for (final quiz in quizzes) quiz.id: quiz,
    };
    final entries = <HistoryEntry>[
      for (final session in sessions)
        HistoryEntry(
          id: 'session-${session.id}',
          kind: switch (session.materialType) {
            StudyMaterialType.text => HistoryEntryKind.textSession,
            StudyMaterialType.image => HistoryEntryKind.imageSession,
            StudyMaterialType.pdf => HistoryEntryKind.pdfSession,
          },
          title: session.title,
          subtitle:
              '${_materialLabel(session.materialType)} • '
              '${session.status == StudySessionStatus.active ? 'In progress' : 'Completed'}',
          timestamp: session.updatedAt,
        ),
      for (final result in results)
        HistoryEntry(
          id: 'result-${result.id}',
          kind: HistoryEntryKind.quizResult,
          title: quizzesById[result.quizId]?.title ?? 'Quiz result',
          subtitle:
              '${result.correctAnswers}/${result.totalQuestions} correct • '
              '${(result.accuracy * 100).round()}% • +${result.xpEarned} XP',
          timestamp: result.completedAt,
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return entries.take(limit).toList(growable: false);
  }

  static String _materialLabel(StudyMaterialType type) => switch (type) {
    StudyMaterialType.text => 'Text',
    StudyMaterialType.image => 'Image',
    StudyMaterialType.pdf => 'PDF',
  };
}
