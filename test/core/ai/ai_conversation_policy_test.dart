import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/ai/ai_chat_message.dart';
import 'package:studylens_ai/core/ai/ai_conversation_policy.dart';
import 'package:studylens_ai/core/config/ai_config.dart';

void main() {
  test('keeps only the configured number of recent complete turns', () {
    final history = [
      for (var index = 0; index < 10; index++) ...[
        AiChatMessage(role: AiChatRole.student, content: 'Question $index'),
        AiChatMessage(role: AiChatRole.assistant, content: 'Answer $index'),
      ],
    ];

    final recent = AiConversationPolicy.recentCompleteTurns(history);

    expect(recent, hasLength(AiConfig.conversationHistoryLimit));
    expect(recent.first.content, 'Question 4');
    expect(recent.last.content, 'Answer 9');
  });

  test('drops empty, misordered, and incomplete messages', () {
    final recent = AiConversationPolicy.recentCompleteTurns(const [
      AiChatMessage(role: AiChatRole.assistant, content: 'Orphan answer'),
      AiChatMessage(role: AiChatRole.student, content: 'Valid question'),
      AiChatMessage(role: AiChatRole.assistant, content: 'Valid answer'),
      AiChatMessage(role: AiChatRole.student, content: '  '),
      AiChatMessage(role: AiChatRole.student, content: 'Unanswered question'),
    ]);

    expect(recent, hasLength(2));
    expect(recent.first.content, 'Valid question');
    expect(recent.last.content, 'Valid answer');
  });
}
