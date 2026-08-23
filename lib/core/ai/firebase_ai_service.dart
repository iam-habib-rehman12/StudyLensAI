import 'package:firebase_ai/firebase_ai.dart';

import '../config/ai_config.dart';
import '../config/ai_prompts.dart';
import '../errors/app_exception.dart';
import 'ai_chat_message.dart';
import 'ai_conversation_policy.dart';
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

    try {
      final chat = _model.startChat(history: _toFirebaseHistory(history));
      var receivedText = false;
      await for (final response in chat.sendMessageStream(
        Content.text(trimmedQuestion),
      )) {
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
