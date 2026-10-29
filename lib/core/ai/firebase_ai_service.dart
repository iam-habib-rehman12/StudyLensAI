import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../config/ai_config.dart';
import '../config/ai_prompts.dart';
import '../config/ai_schemas.dart';
import '../errors/app_exception.dart';
import 'ai_chat_message.dart';
import 'ai_conversation_policy.dart';
import 'ai_explanation_mode.dart';
import 'ai_service.dart';

class FirebaseAiService implements AiService {
  FirebaseAiService([this._firebaseAi]);

  final FirebaseAI? _firebaseAi;

  GenerativeModel get _model =>
      (_firebaseAi ?? FirebaseAI.googleAI()).generativeModel(
        model: AiConfig.defaultModel,
        generationConfig: GenerationConfig(
          temperature: AiConfig.temperature,
          maxOutputTokens: AiConfig.maxOutputTokens,
        ),
        systemInstruction: Content.system(AiPrompts.tutorSystemInstruction),
      );

  GenerativeModel _quizModel(int questionCount) =>
      (_firebaseAi ?? FirebaseAI.googleAI()).generativeModel(
        model: AiConfig.defaultModel,
        generationConfig: GenerationConfig(
          temperature: AiConfig.quizTemperature,
          maxOutputTokens: AiConfig.quizMaxOutputTokens,
          responseMimeType: 'application/json',
          responseSchema: AiSchemas.quiz(questionCount: questionCount),
        ),
        systemInstruction: Content.system(AiPrompts.quizSystemInstruction),
      );

  @override
  Stream<String> streamTutorResponse({
    required String question,
    required List<AiChatMessage> history,
  }) async* {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty ||
        trimmedQuestion.length > AiConfig.tutorMaxQuestionCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter a shorter, non-empty study question.',
      );
    }

    yield* _stream(history: history, content: Content.text(trimmedQuestion));
  }

  @override
  Stream<String> streamImageResponse({
    required Uint8List imageBytes,
    required String mimeType,
    required String question,
    required AiExplanationMode mode,
    required List<AiChatMessage> history,
  }) async* {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty ||
        trimmedQuestion.length > AiConfig.tutorMaxQuestionCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter a shorter, non-empty question about the image.',
      );
    }
    if (imageBytes.isEmpty) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'The selected image is empty. Choose the image again.',
      );
    }
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'StudyLens supports JPEG, PNG, and WebP images.',
      );
    }

    yield* _stream(
      history: history,
      content: Content.multi([
        InlineDataPart(mimeType, imageBytes),
        TextPart(
          AiPrompts.imageQuestion(question: trimmedQuestion, mode: mode),
        ),
      ]),
    );
  }

  @override
  Stream<String> streamDocumentResponse({
    required Uint8List documentBytes,
    required String question,
    required String action,
    required List<AiChatMessage> history,
  }) async* {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty ||
        trimmedQuestion.length > AiConfig.tutorMaxQuestionCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter a shorter, non-empty request about the PDF.',
      );
    }
    if (documentBytes.isEmpty) {
      throw const AppException(
        type: AppErrorType.invalidDocument,
        message: 'The selected PDF is empty. Choose the document again.',
      );
    }

    yield* _stream(
      history: history,
      content: Content.multi([
        InlineDataPart('application/pdf', documentBytes),
        TextPart(
          AiPrompts.documentQuestion(question: trimmedQuestion, action: action),
        ),
      ]),
    );
  }

  @override
  Future<String> generateQuizJson({
    required String sourceMaterial,
    required int questionCount,
    required String difficulty,
  }) async {
    final source = sourceMaterial.trim();
    if (source.isEmpty || source.length > AiConfig.quizMaxSourceCharacters) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Enter study material between 1 and 8,000 characters.',
      );
    }
    if (questionCount < AiConfig.quizMinQuestions ||
        questionCount > AiConfig.quizMaxQuestions) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Choose between 5 and 15 quiz questions.',
      );
    }
    final cleanDifficulty = difficulty.trim().toLowerCase();
    if (!const {'easy', 'medium', 'hard'}.contains(cleanDifficulty)) {
      throw const AppException(
        type: AppErrorType.malformedResponse,
        message: 'Choose easy, medium, or hard difficulty.',
      );
    }

    try {
      final response = await _quizModel(questionCount)
          .generateContent([
            Content.text(
              AiPrompts.quizGeneration(
                sourceMaterial: source,
                questionCount: questionCount,
                difficulty: cleanDifficulty,
              ),
            ),
          ])
          .timeout(AiConfig.quizGenerationTimeout);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const AppException(
          type: AppErrorType.malformedResponse,
          message:
              'StudyLens received an empty quiz. Please generate it again.',
        );
      }
      return text;
    } on AppException {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppException(
        type: AppErrorType.offline,
        message:
            'The AI service took too long to respond. Check your connection and try again.',
        cause: error,
      );
    } on QuotaExceeded catch (error) {
      throw AppException(
        type: AppErrorType.rateLimited,
        message:
            'StudyLens has reached its AI request limit. Please wait and try again.',
        cause: error,
      );
    } on ServiceApiNotEnabled catch (error) {
      throw AppException(
        type: AppErrorType.configuration,
        message:
            'Firebase AI Logic is not enabled for this project. Complete AI Logic setup in Firebase Console.',
        cause: error,
      );
    } on InvalidApiKey catch (error) {
      throw AppException(
        type: AppErrorType.configuration,
        message:
            'The Firebase AI configuration is invalid. Check the project setup.',
        cause: error,
      );
    } on FirebaseAISdkException catch (error) {
      throw AppException(
        type: AppErrorType.malformedResponse,
        message: 'StudyLens received malformed quiz data. Generate it again.',
        cause: error,
      );
    } on FirebaseAIException catch (error) {
      throw _mapAiError(error);
    } catch (error) {
      final normalized = error.toString().toLowerCase();
      if (_looksOffline(normalized)) {
        throw AppException(
          type: AppErrorType.offline,
          message:
              'StudyLens cannot reach the AI service. Check your connection and try again.',
          cause: error,
        );
      }
      throw AppException(
        type: AppErrorType.unknown,
        message: 'StudyLens could not generate a quiz right now. Try again.',
        cause: error,
      );
    }
  }

  Stream<String> _stream({
    required List<AiChatMessage> history,
    required Content content,
  }) async* {
    try {
      final chat = _model.startChat(history: _toFirebaseHistory(history));
      var receivedText = false;
      final responses = chat
          .sendMessageStream(content)
          .timeout(
            AiConfig.streamIdleTimeout,
            onTimeout: (sink) {
              sink.addError(
                TimeoutException(
                  'No AI response chunk arrived before the deadline.',
                ),
              );
              sink.close();
            },
          );
      await for (final response in responses) {
        final text = response.text;
        if (text == null || text.isEmpty) continue;
        receivedText = true;
        yield text;
      }
      if (!receivedText) {
        throw const AppException(
          type: AppErrorType.malformedResponse,
          message:
              'StudyLens received an empty AI response. Please try your question again.',
        );
      }
    } on AppException {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppException(
        type: AppErrorType.offline,
        message:
            'The AI service stopped responding. Check your connection and try again.',
        cause: error,
      );
    } on QuotaExceeded catch (error) {
      throw AppException(
        type: AppErrorType.rateLimited,
        message:
            'StudyLens has reached its AI request limit. Please wait and try again.',
        cause: error,
      );
    } on ServiceApiNotEnabled catch (error) {
      throw AppException(
        type: AppErrorType.configuration,
        message:
            'Firebase AI Logic is not enabled for this project. Complete AI Logic setup in Firebase Console.',
        cause: error,
      );
    } on InvalidApiKey catch (error) {
      throw AppException(
        type: AppErrorType.configuration,
        message:
            'The Firebase AI configuration is invalid. Check the project setup.',
        cause: error,
      );
    } on FirebaseAISdkException catch (error) {
      throw AppException(
        type: AppErrorType.malformedResponse,
        message:
            'StudyLens could not understand the AI response. Please try again.',
        cause: error,
      );
    } on FirebaseAIException catch (error) {
      throw _mapAiError(error);
    } catch (error) {
      final normalized = error.toString().toLowerCase();
      if (_looksOffline(normalized)) {
        throw AppException(
          type: AppErrorType.offline,
          message:
              'StudyLens cannot reach the AI service. Check your connection and try again.',
          cause: error,
        );
      }
      throw AppException(
        type: AppErrorType.unknown,
        message: 'StudyLens could not answer right now. Please try again.',
        cause: error,
      );
    }
  }

  List<Content> _toFirebaseHistory(List<AiChatMessage> history) {
    return AiConversationPolicy.recentCompleteTurns(history)
        .map(
          (message) => message.role == AiChatRole.student
              ? Content.text(message.content)
              : Content.model([TextPart(message.content)]),
        )
        .toList(growable: false);
  }

  AppException _mapAiError(FirebaseAIException error) {
    final normalized = error.message.toLowerCase();
    if (_looksOffline(normalized)) {
      return AppException(
        type: AppErrorType.offline,
        message:
            'StudyLens cannot reach the AI service. Check your connection and try again.',
        cause: error,
      );
    }
    if (normalized.contains('app check') ||
        normalized.contains('permission') ||
        normalized.contains('403')) {
      return AppException(
        type: AppErrorType.permissionDenied,
        message:
            'This device is not authorized for StudyLens AI. Check the App Check setup.',
        cause: error,
      );
    }
    if (normalized.contains('blocked') || normalized.contains('safety')) {
      return AppException(
        type: AppErrorType.malformedResponse,
        message:
            'StudyLens could not answer that safely. Try rephrasing the educational question.',
        cause: error,
      );
    }
    return AppException(
      type: AppErrorType.unknown,
      message: 'StudyLens could not answer right now. Please try again.',
      cause: error,
    );
  }

  bool _looksOffline(String message) {
    return message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('unavailable') ||
        message.contains('deadline');
  }
}
