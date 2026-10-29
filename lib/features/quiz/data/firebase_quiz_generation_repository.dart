import 'dart:convert';

import '../../../core/ai/ai_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/quiz.dart';
import '../domain/quiz_generation_repository.dart';
import '../domain/quiz_generation_request.dart';
import '../domain/quiz_repository.dart';

class FirebaseQuizGenerationRepository implements QuizGenerationRepository {
  FirebaseQuizGenerationRepository(
    this._aiService,
    this._quizRepository,
    this._idGenerator, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AiService _aiService;
  final QuizRepository _quizRepository;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  @override
  Future<Quiz> generate({
    required String userId,
    required QuizGenerationRequest request,
  }) async {
    if (userId.trim().isEmpty) {
      throw const AppException(
        type: AppErrorType.authentication,
        message: 'Sign in again before generating a quiz.',
      );
    }

    final rawJson = await _aiService.generateQuizJson(
      sourceMaterial: request.sourceMaterial,
      questionCount: request.questionCount,
      difficulty: request.difficulty.name,
    );
    return _decode(
      rawJson,
      userId: userId,
      sessionId: request.sessionId,
      expectedCount: request.questionCount,
    );
  }

  @override
  Future<void> save(Quiz quiz) => _quizRepository.saveQuiz(quiz);

  Quiz _decode(
    String rawJson, {
    required String userId,
    required String? sessionId,
    required int expectedCount,
  }) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        throw const FormatException('Quiz response must be a JSON object.');
      }
      final root = decoded.cast<String, Object?>();
      _requireExactKeys(root, const {'title', 'questionCount', 'questions'});
      final title = _requiredString(root, 'title', maximum: 120);
      final declaredCount = root['questionCount'];
      if (declaredCount is! int || declaredCount != expectedCount) {
        throw const FormatException('Quiz question count is inconsistent.');
      }
      final rawQuestions = root['questions'];
      if (rawQuestions is! List || rawQuestions.length != expectedCount) {
        throw const FormatException('Quiz questions are missing.');
      }

      final questions = <QuizQuestion>[];
      for (final rawQuestion in rawQuestions) {
        if (rawQuestion is! Map) {
          throw const FormatException('Quiz question must be an object.');
        }
        final data = rawQuestion.cast<String, Object?>();
        _requireExactKeys(data, const {
          'question',
          'options',
          'correctOptionIndex',
          'explanation',
        });
        final rawOptions = data['options'];
        if (rawOptions is! List ||
            rawOptions.length != 4 ||
            rawOptions.any((option) => option is! String)) {
          throw const FormatException(
            'Every quiz question requires four text options.',
          );
        }
        final index = data['correctOptionIndex'];
        if (index is! int || index < 0 || index > 3) {
          throw const FormatException('Correct option index is invalid.');
        }
        questions.add(
          QuizQuestion(
            id: _idGenerator.next('question'),
            question: _requiredString(data, 'question', maximum: 500),
            options: rawOptions
                .cast<String>()
                .map((option) => option.trim())
                .toList(growable: false),
            correctOptionIndex: index,
            explanation: _requiredString(data, 'explanation', maximum: 2000),
          ),
        );
      }

      return Quiz(
        id: _idGenerator.next('quiz'),
        userId: userId,
        sessionId: sessionId,
        title: title,
        questions: questions,
        createdAt: _now().toUtc(),
      );
    } on FormatException catch (error) {
      throw AppException(
        type: AppErrorType.malformedResponse,
        message:
            'StudyLens generated an invalid quiz. Please generate it again.',
        cause: error,
      );
    } on ArgumentError catch (error) {
      throw AppException(
        type: AppErrorType.malformedResponse,
        message:
            'StudyLens generated an invalid quiz. Please generate it again.',
        cause: error,
      );
    } on TypeError catch (error) {
      throw AppException(
        type: AppErrorType.malformedResponse,
        message:
            'StudyLens generated an invalid quiz. Please generate it again.',
        cause: error,
      );
    }
  }

  void _requireExactKeys(Map<String, Object?> data, Set<String> required) {
    if (data.length != required.length || !required.every(data.containsKey)) {
      throw const FormatException('Quiz response fields are inconsistent.');
    }
  }

  String _requiredString(
    Map<String, Object?> data,
    String key, {
    required int maximum,
  }) {
    final value = data[key];
    if (value is! String ||
        value.trim().isEmpty ||
        value.trim().length > maximum) {
      throw FormatException('Quiz field "$key" is invalid.');
    }
    return value.trim();
  }
}
