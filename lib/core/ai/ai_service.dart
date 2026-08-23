import 'ai_chat_message.dart';

abstract interface class AiService {
  Stream<String> streamTutorResponse({
    required String question,
    required List<AiChatMessage> history,
  });
}
