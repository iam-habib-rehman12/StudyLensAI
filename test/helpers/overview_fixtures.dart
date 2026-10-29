import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_result.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';

Quiz buildOverviewQuiz({
  String id = 'quiz-1',
  String userId = 'user-1',
  String title = 'Cell Biology Review',
  int questionCount = 2,
}) {
  return Quiz(
    id: id,
    userId: userId,
    title: title,
    questions: [
      for (var index = 0; index < questionCount; index++)
        QuizQuestion(
          id: 'question-$index',
          question: 'Question ${index + 1}?',
          options: const ['Option A', 'Option B', 'Option C', 'Option D'],
          correctOptionIndex: 0,
          explanation: 'Option A is correct.',
        ),
    ],
    createdAt: DateTime.utc(2026, 8, 25, 8),
  );
}

QuizResult buildOverviewResult({
  String id = 'result-1',
  String userId = 'user-1',
  String quizId = 'quiz-1',
  List<int> selectedOptionIndexes = const [0, 1],
  int correctAnswers = 1,
  int xpEarned = 10,
  DateTime? completedAt,
  String? sessionId,
}) {
  return QuizResult(
    id: id,
    userId: userId,
    quizId: quizId,
    sessionId: sessionId,
    selectedOptionIndexes: selectedOptionIndexes,
    correctAnswers: correctAnswers,
    completedAt: completedAt ?? DateTime.utc(2026, 8, 25, 10),
    xpEarned: xpEarned,
  );
}

StudySession buildOverviewSession({
  String id = 'session-1',
  String userId = 'user-1',
  String title = 'Cell biology notes',
  StudyMaterialType materialType = StudyMaterialType.text,
  StudySessionStatus status = StudySessionStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 8, 25, 9);
  return StudySession(
    id: id,
    userId: userId,
    title: title,
    materialType: materialType,
    status: status,
    createdAt: created,
    updatedAt: updatedAt ?? created,
  );
}
