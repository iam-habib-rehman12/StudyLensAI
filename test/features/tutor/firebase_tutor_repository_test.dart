import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/ai/ai_chat_message.dart';
import 'package:studylens_ai/core/ai/ai_service.dart';
import 'package:studylens_ai/core/utils/id_generator.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/study/domain/study_session_repository.dart';
import 'package:studylens_ai/features/tutor/data/firebase_tutor_repository.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';
import 'package:studylens_ai/features/tutor/domain/study_message_repository.dart';

void main() {
  test('creates a typed text session and persists both message roles', () async {
    final aiService = _AiServiceFake();
    final sessions = _SessionRepositoryFake();
    final messages = _MessageRepositoryFake();
    final repository = FirebaseTutorRepository(
      aiService,
      sessions,
      messages,
      _IdGeneratorFake(),
      now: () => DateTime.utc(2026, 8, 22),
    );

    final session = await repository.createTextSession(
      userId: 'user-1',
      initialQuestion:
          '  Explain the relationship between force, mass, and acceleration in detail.  ',
    );
    final question = await repository.saveStudentQuestion(
      userId: 'user-1',
      sessionId: session.id,
      question: 'What does F = ma mean?',
    );
    final chunks = await repository
        .streamAnswer(question: question.content, history: [question])
        .toList();
    final answer = await repository.saveAssistantAnswer(
      userId: 'user-1',
      sessionId: session.id,
      answer: chunks.join(),
    );

    expect(sessions.created?.materialType, StudyMaterialType.text);
    expect(session.title.length, lessThanOrEqualTo(72));
    expect(question.role, StudyMessageRole.student);
    expect(answer.role, StudyMessageRole.assistant);
    expect(messages.saved, hasLength(2));
    expect(aiService.history.single.role, AiChatRole.student);
  });
}

class _AiServiceFake implements AiService {
  List<AiChatMessage> history = const [];

  @override
  Stream<String> streamTutorResponse({
    required String question,
    required List<AiChatMessage> history,
  }) async* {
    this.history = history;
    yield 'Force equals mass times acceleration.';
  }
}

class _SessionRepositoryFake implements StudySessionRepository {
  StudySession? created;

  @override
  Future<void> createSession(StudySession session) async => created = session;

  @override
  Future<void> completeSession({
    required String userId,
    required String sessionId,
  }) async {}

  @override
  Future<StudySession?> getSession({
    required String userId,
    required String sessionId,
  }) async => created;

  @override
  Stream<List<StudySession>> watchRecentSessions(
    String userId, {
    int limit = 20,
  }) => Stream.value([?created]);
}

class _MessageRepositoryFake implements StudyMessageRepository {
  final List<StudyMessage> saved = [];

  @override
  Future<void> saveMessage(StudyMessage message) async => saved.add(message);

  @override
  Stream<List<StudyMessage>> watchMessages({
    required String userId,
    required String sessionId,
  }) => Stream.value(saved);
}

class _IdGeneratorFake implements IdGenerator {
  int _value = 0;

  @override
  String next(String prefix) {
    _value += 1;
    return '$prefix-$_value';
  }
}
