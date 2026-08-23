enum AiChatRole { student, assistant }

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final AiChatRole role;
  final String content;
}
