import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/progress/domain/progress_summary.dart';

import '../../helpers/overview_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 25, 12);

  test('reports an empty summary without results', () {
    final summary = ProgressSummary.fromResults(const [], now: now);

    expect(summary.isEmpty, isTrue);
    expect(summary.totalQuizzes, 0);
    expect(summary.totalQuestions, 0);
    expect(summary.totalXp, 0);
    expect(summary.level, 1);
    expect(summary.xpIntoLevel, 0);
    expect(summary.accuracy, 0);
    expect(summary.accuracyPercent, 0);
    expect(summary.todayQuizzes, 0);
    expect(summary.todayAccuracyPercent, 0);
  });

  test('aggregates quizzes, questions, accuracy, and XP', () {
    final summary = ProgressSummary.fromResults([
      buildOverviewResult(
        id: 'result-1',
        selectedOptionIndexes: const [0, 1],
        correctAnswers: 1,
        xpEarned: 10,
        completedAt: DateTime(2026, 8, 25, 9),
      ),
      buildOverviewResult(
        id: 'result-2',
        selectedOptionIndexes: const [0, 0, 0],
        correctAnswers: 3,
        xpEarned: 30,
        completedAt: DateTime(2026, 8, 24, 9),
      ),
    ], now: now);

    expect(summary.totalQuizzes, 2);
    expect(summary.totalQuestions, 5);
    expect(summary.correctAnswers, 4);
    expect(summary.totalXp, 40);
    expect(summary.accuracy, 0.8);
    expect(summary.accuracyPercent, 80);
    expect(summary.level, 1);
    expect(summary.xpIntoLevel, 40);
    expect(summary.xpToNextLevel, 160);
  });

  test('counts only results completed today', () {
    final summary = ProgressSummary.fromResults([
      buildOverviewResult(
        id: 'result-today',
        selectedOptionIndexes: const [0, 1],
        correctAnswers: 1,
        completedAt: DateTime(2026, 8, 25, 9),
      ),
      buildOverviewResult(
        id: 'result-yesterday',
        selectedOptionIndexes: const [0, 0, 0],
        correctAnswers: 3,
        completedAt: DateTime(2026, 8, 24, 23),
      ),
    ], now: now);

    expect(summary.todayQuizzes, 1);
    expect(summary.todayQuestions, 2);
    expect(summary.todayCorrectAnswers, 1);
    expect(summary.todayAccuracyPercent, 50);
  });

  test('raises the level for each 200 XP and reports level progress', () {
    final summary = ProgressSummary.fromResults([
      buildOverviewResult(xpEarned: 200, correctAnswers: 1),
    ], now: now);

    expect(summary.totalXp, 200);
    expect(summary.level, 2);
    expect(summary.xpIntoLevel, 0);
    expect(summary.levelProgress, 0);

    final partial = ProgressSummary.fromResults([
      buildOverviewResult(xpEarned: 399, correctAnswers: 1),
    ], now: now);

    expect(partial.level, 2);
    expect(partial.xpIntoLevel, 199);
    expect(partial.levelProgress, closeTo(0.995, 0.0001));
  });
}
