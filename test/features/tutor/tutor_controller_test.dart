import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/tutor/application/tutor_controller.dart';
import 'package:studylens_ai/features/tutor/application/tutor_state.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';
import 'package:studylens_ai/features/tutor/domain/tutor_repository.dart';

void main() {
  test('persists a student question and completed streamed answer', () async {
    final repository = _TutorRepositoryFake(answerChunks: ['Mito', 'sis']);
    final controller = TutorController('user-1', repository);
    addTearDown(controller.dispose);

    final succeeded = await controller.sendQuestion('Explain mitosis');

    expect(succeeded, isTrue);
    expect(controller.state.status, TutorStatus.ready);
    expect(controller.state.messages, hasLength(2));
    expect(controller.state.messages.first.role, StudyMessageRole.student);
    expect(controller.state.messages.last.content, 'Mitosis');
    expect(repository.studentSaveCalls, 1);
    expect(repository.assistantSaveCalls, 1);
  });

  test('retries AI without persisting the student question twice', () async {
    final repository = _TutorRepositoryFake(
      answerChunks: ['Recovered answer'],
      streamFailures: 1,
    );
    final controller = TutorController('user-1', repository);
    addTearDown(controller.dispose);

    expect(await controller.sendQuestion('What is entropy?'), isFalse);
    expect(controller.state.canRetry, isTrue);

    await controller.retry();

    expect(controller.state.errorMessage, isNull);
    expect(controller.state.messages, hasLength(2));
    expect(repository.studentSaveCalls, 1);
    expect(repository.streamCalls, 2);
  });

  test(
    'retries answer persistence without making another AI request',
    () async {
      final repository = _TutorRepositoryFake(
        answerChunks: ['Visible answer'],
        assistantSaveFailures: 1,
      );
      final controller = TutorController('user-1', repository);
      addTearDown(controller.dispose);

      expect(await controller.sendQuestion('Explain acceleration'), isFalse);
      expect(controller.state.streamingText, 'Visible answer');
      expect(controller.state.canRetry, isTrue);

      await controller.retry();

      expect(controller.state.streamingText, isEmpty);
      expect(controller.state.messages, hasLength(2));
      expect(repository.streamCalls, 1);
      expect(repository.assistantSaveCalls, 2);
      expect(repository.assistantMessageIds.toSet(), hasLength(1));
      expect(repository.assistantMessageIds.first, isNotNull);
    },
  );

  test(
    'surfaces an empty AI stream as a retryable malformed response',
    () async {
      final repository = _TutorRepositoryFake(answerChunks: const []);
      final controller = TutorController('user-1', repository);
      addTearDown(controller.dispose);

      expect(await controller.sendQuestion('Explain ATP'), isFalse);

      expect(controller.state.canRetry, isTrue);
      expect(controller.state.errorMessage, contains('empty AI response'));
      expect(controller.state.messages, hasLength(1));
    },
  );

  test('rejects empty questions without creating a session', () async {
    final repository = _TutorRepositoryFake(answerChunks: ['unused']);
    final controller = TutorController('user-1', repository);
    addTearDown(controller.dispose);

    expect(await controller.sendQuestion('   '), isFalse);

    expect(repository.sessionCreateCalls, 0);
    expect(controller.state.errorMessage, 'Enter a study question first.');
  });
}

class _TutorRepositoryFake implements TutorRepository {
  _TutorRepositoryFake({
    required this.answerChunks,
    this.streamFailures = 0,
    this.assistantSaveFailures = 0,
  });

  final List<String> answerChunks;
  int streamFailures;
  int assistantSaveFailures;
  int sessionCreateCalls = 0;
  int studentSaveCalls = 0;
  int assistantSaveCalls = 0;
  int streamCalls = 0;
  final List<String?> assistantMessageIds = [];
  int _messageCount = 0;

  @override
  Future<StudySession> createTextSession({
    required String userId,
    required String initialQuestion,
  }) async {
    sessionCreateCalls += 1;
    final time = DateTime.utc(2026, 8, 22);
    return StudySession(
      id: 'session-1',
      userId: userId,
      title: initialQuestion,
      materialType: StudyMaterialType.text,
      status: StudySessionStatus.active,
      createdAt: time,
      updatedAt: time,
    );
  }

  @override
  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  }) async {
    studentSaveCalls += 1;
    return _message(userId, sessionId, StudyMessageRole.student, question);
  }

  @override
  Stream<String> streamAnswer({
    required String question,
    required List<StudyMessage> history,
  }) async* {
    streamCalls += 1;
    if (streamFailures > 0) {
      streamFailures -= 1;
      throw const AppException(
        type: AppErrorType.offline,
        message: 'StudyLens is offline.',
      );
    }
    for (final chunk in answerChunks) {
      yield chunk;
    }
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) async {
    assistantSaveCalls += 1;
    assistantMessageIds.add(messageId);
    if (assistantSaveFailures > 0) {
      assistantSaveFailures -= 1;
      throw const AppException(
        type: AppErrorType.persistence,
        message: 'Answer could not be saved.',
      );
    }
    return _message(
      userId,
      sessionId,
      StudyMessageRole.assistant,
      answer,
      messageId,
    );
  }

  StudyMessage _message(
    String userId,
    String sessionId,
    StudyMessageRole role,
    String content, [
    String? messageId,
  ]) {
    _messageCount += 1;
    return StudyMessage(
      id: messageId ?? 'message-$_messageCount',
      userId: userId,
      sessionId: sessionId,
      role: role,
      content: content,
      createdAt: DateTime.utc(2026, 8, 22, 0, _messageCount),
    );
  }
}
