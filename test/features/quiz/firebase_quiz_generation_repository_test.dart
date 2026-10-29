import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/ai/ai_chat_message.dart';
import 'package:studylens_ai/core/ai/ai_explanation_mode.dart';
import 'package:studylens_ai/core/ai/ai_service.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/core/utils/id_generator.dart';
import 'package:studylens_ai/features/quiz/data/firebase_quiz_generation_repository.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_generation_request.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_repository.dart';

void main() {
  test('decodes exact structured output and saves validated quiz', () async {
    final ai = _AiServiceFake(_validQuizJson(5));
    final quizStorage = _QuizRepositoryFake();
    final repository = FirebaseQuizGenerationRepository(
      ai,
      quizStorage,
      _IdGeneratorFake(),
      now: () => DateTime.utc(2026, 8, 24),
    );
    final request = QuizGenerationRequest(
      sourceMaterial: 'Cell biology notes',
      questionCount: 5,
      difficulty: QuizDifficulty.medium,
    );

    final quiz = await repository.generate(userId: 'user-1', request: request);
    await repository.save(quiz);

    expect(quiz.title, 'Cell Biology Review');
    expect(quiz.questions, hasLength(5));
    expect(quiz.questions.first.options, hasLength(4));
    expect(quiz.questions.first.correctOptionIndex, 0);
    expect(quizStorage.saved, same(quiz));
    expect(ai.lastDifficulty, 'medium');
  });

  final malformedPayloads = <String, Object?>{
    'non-JSON output': 'not-json',
    'missing required fields': jsonEncode({'title': 'Incomplete'}),
    'unexpected extra fields': _validQuizJson(5, extraRootField: true),
    'wrong declared count': _validQuizJson(5, declaredCount: 4),
    'duplicate questions': _validQuizJson(5, duplicateQuestions: true),
    'incorrect option count': _validQuizJson(5, optionCount: 3),
    'invalid answer index': _validQuizJson(5, correctIndex: 4),
    'empty explanation': _validQuizJson(5, emptyExplanation: true),
  };

  for (final entry in malformedPayloads.entries) {
    test('rejects ${entry.key}', () async {
      final repository = FirebaseQuizGenerationRepository(
        _AiServiceFake(entry.value as String),
        _QuizRepositoryFake(),
        _IdGeneratorFake(),
      );

      expect(
        () => repository.generate(
          userId: 'user-1',
          request: QuizGenerationRequest(
            sourceMaterial: 'Study notes',
            questionCount: 5,
            difficulty: QuizDifficulty.easy,
          ),
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.type,
            'type',
            AppErrorType.malformedResponse,
          ),
        ),
      );
    });
  }
}

String _validQuizJson(
  int count, {
  bool extraRootField = false,
  int? declaredCount,
  bool duplicateQuestions = false,
  int optionCount = 4,
  int correctIndex = 0,
  bool emptyExplanation = false,
}) {
  final data = <String, Object?>{
    'title': 'Cell Biology Review',
    'questionCount': declaredCount ?? count,
    'questions': [
      for (var index = 0; index < count; index++)
        {
          'question': duplicateQuestions
              ? 'What is ATP?'
              : 'What is concept ${index + 1}?',
          'options': [
            for (var option = 0; option < optionCount; option++)
              'Option ${option + 1}',
          ],
          'correctOptionIndex': correctIndex,
          'explanation': emptyExplanation ? '' : 'A grounded explanation.',
        },
    ],
    if (extraRootField) 'unexpected': true,
  };
  return jsonEncode(data);
}

class _AiServiceFake implements AiService {
  _AiServiceFake(this.response);

  final String response;
  String? lastDifficulty;

  @override
  Future<String> generateQuizJson({
    required String sourceMaterial,
    required int questionCount,
    required String difficulty,
  }) async {
    lastDifficulty = difficulty;
    return response;
  }

  @override
  Stream<String> streamDocumentResponse({
    required Uint8List documentBytes,
    required String question,
    required String action,
    required List<AiChatMessage> history,
  }) => const Stream.empty();

  @override
  Stream<String> streamImageResponse({
    required Uint8List imageBytes,
    required String mimeType,
    required String question,
    required AiExplanationMode mode,
    required List<AiChatMessage> history,
  }) => const Stream.empty();

  @override
  Stream<String> streamTutorResponse({
    required String question,
    required List<AiChatMessage> history,
  }) => const Stream.empty();
}

class _QuizRepositoryFake implements QuizRepository {
  Quiz? saved;

  @override
  Future<void> saveQuiz(Quiz quiz) async => saved = quiz;

  @override
  Future<Quiz?> getQuiz({
    required String userId,
    required String quizId,
  }) async => saved;

  @override
  Stream<List<Quiz>> watchRecentQuizzes(String userId, {int limit = 20}) =>
      Stream.value([?saved]);
}

class _IdGeneratorFake implements IdGenerator {
  int _value = 0;

  @override
  String next(String prefix) => '$prefix-${++_value}';
}
