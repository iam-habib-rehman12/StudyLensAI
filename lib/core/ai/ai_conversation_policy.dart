import '../config/ai_config.dart';
import 'ai_chat_message.dart';

abstract final class AiConversationPolicy {
  static List<AiChatMessage> recentCompleteTurns(List<AiChatMessage> history) {
    final recent = history.length <= AiConfig.conversationHistoryLimit
        ? history
        : history.sublist(history.length - AiConfig.conversationHistoryLimit);
    final normalized = <AiChatMessage>[];
    var expectedRole = AiChatRole.student;
    for (final message in recent) {
      if (message.content.trim().isEmpty || message.role != expectedRole) {
        continue;
      }
      normalized.add(message);
      expectedRole = expectedRole == AiChatRole.student
          ? AiChatRole.assistant
          : AiChatRole.student;
    }
    if (normalized.isNotEmpty && normalized.last.role == AiChatRole.student) {
      normalized.removeLast();
    }
    return List.unmodifiable(normalized);
  }
}
