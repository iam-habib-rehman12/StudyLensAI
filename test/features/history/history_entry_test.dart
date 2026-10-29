import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/history/domain/history_entry.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';

import '../../helpers/overview_fixtures.dart';

void main() {
  test('joins sessions and results into a newest-first history', () {
    final sessions = [
      buildOverviewSession(
        id: 'session-text',
        title: 'Mitosis notes',
        materialType: StudyMaterialType.text,
        updatedAt: DateTime.utc(2026, 8, 25, 10),
      ),
      buildOverviewSession(
        id: 'session-pdf',
        title: 'Lecture PDF',
        materialType: StudyMaterialType.pdf,
        status: StudySessionStatus.completed,
        createdAt: DateTime.utc(2026, 8, 25, 8),
        updatedAt: DateTime.utc(2026, 8, 25, 9),
      ),
    ];
    final quizzes = [buildOverviewQuiz(title: 'Cell Biology Review')];
    final results = [
      buildOverviewResult(
        id: 'result-known',
        quizId: 'quiz-1',
        completedAt: DateTime.utc(2026, 8, 25, 11),
      ),
      buildOverviewResult(
        id: 'result-unknown',
        quizId: 'missing-quiz',
        completedAt: DateTime.utc(2026, 8, 25, 8),
      ),
    ];

    final entries = HistoryEntry.build(
      sessions: sessions,
      quizzes: quizzes,
      results: results,
    );

    expect(entries.map((entry) => entry.id), [
      'result-result-known',
      'session-session-text',
      'session-session-pdf',
      'result-result-unknown',
    ]);
    expect(entries[0].title, 'Cell Biology Review');
    expect(entries[0].kind, HistoryEntryKind.quizResult);
    expect(entries[0].subtitle, contains('1/2 correct'));
    expect(entries[1].kind, HistoryEntryKind.textSession);
    expect(entries[1].subtitle, contains('Text'));
    expect(entries[1].subtitle, contains('In progress'));
    expect(entries[2].kind, HistoryEntryKind.pdfSession);
    expect(entries[2].subtitle, contains('Completed'));
    expect(entries[3].title, 'Quiz result');
  });

  test('limits the number of returned entries', () {
    final entries = HistoryEntry.build(
      sessions: [
        for (var index = 0; index < 5; index++)
          buildOverviewSession(id: 'session-$index'),
      ],
      quizzes: const [],
      results: const [],
      limit: 3,
    );

    expect(entries, hasLength(3));
  });
}
