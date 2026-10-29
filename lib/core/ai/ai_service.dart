import 'dart:typed_data';

import 'ai_chat_message.dart';
import 'ai_explanation_mode.dart';

abstract interface class AiService {
  Stream<String> streamTutorResponse({
    required String question,
    required List<AiChatMessage> history,
  });

  Stream<String> streamImageResponse({
    required Uint8List imageBytes,
    required String mimeType,
    required String question,
    required AiExplanationMode mode,
    required List<AiChatMessage> history,
  });

  Stream<String> streamDocumentResponse({
    required Uint8List documentBytes,
    required String question,
    required String action,
    required List<AiChatMessage> history,
  });

  Future<String> generateQuizJson({
    required String sourceMaterial,
    required int questionCount,
    required String difficulty,
  });
}
