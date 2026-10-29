import '../../quiz/domain/quiz_result.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpPerLevel,
    required this.todayQuizzes,
    required this.todayQuestions,
    required this.todayCorrectAnswers,
  });

  /// XP required to advance one level.
  static const xpPerLevelThreshold = 200;

  factory ProgressSummary.fromResults(
    List<QuizResult> results, {
    DateTime? now,
  }) {
    var totalQuestions = 0;
    var correctAnswers = 0;
    var totalXp = 0;
    var todayQuizzes = 0;
    var todayQuestions = 0;
    var todayCorrectAnswers = 0;
    final current = (now ?? DateTime.now()).toLocal();
    final startOfToday = DateTime(current.year, current.month, current.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    for (final result in results) {
      totalQuestions += result.totalQuestions;
      correctAnswers += result.correctAnswers;
      totalXp += result.xpEarned;
      final completedAt = result.completedAt.toLocal();
      if (!completedAt.isBefore(startOfToday) &&
          completedAt.isBefore(startOfTomorrow)) {
        todayQuizzes += 1;
        todayQuestions += result.totalQuestions;
        todayCorrectAnswers += result.correctAnswers;
      }
    }

    return ProgressSummary(
      totalQuizzes: results.length,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      totalXp: totalXp,
      level: 1 + totalXp ~/ xpPerLevelThreshold,
      xpIntoLevel: totalXp % xpPerLevelThreshold,
      xpPerLevel: xpPerLevelThreshold,
      todayQuizzes: todayQuizzes,
      todayQuestions: todayQuestions,
      todayCorrectAnswers: todayCorrectAnswers,
    );
  }

  final int totalQuizzes;
  final int totalQuestions;
  final int correctAnswers;
  final int totalXp;
  final int level;
  final int xpIntoLevel;
  final int xpPerLevel;
  final int todayQuizzes;
  final int todayQuestions;
  final int todayCorrectAnswers;

  bool get isEmpty => totalQuizzes == 0;
  double get accuracy =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
  double get todayAccuracy =>
      todayQuestions == 0 ? 0 : todayCorrectAnswers / todayQuestions;
  double get levelProgress => xpIntoLevel / xpPerLevel;
  int get xpToNextLevel => xpPerLevel - xpIntoLevel;
  int get accuracyPercent => (accuracy * 100).round();
  int get todayAccuracyPercent => (todayAccuracy * 100).round();
}
