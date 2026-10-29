import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/document/application/document_analysis_controller.dart';
import 'package:studylens_ai/features/document/domain/document_analysis_repository.dart';
import 'package:studylens_ai/features/document/domain/document_study_action.dart';
import 'package:studylens_ai/features/document/domain/study_document.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';

import '../../helpers/fake_document_services.dart';

void main() {
  test('selects PDF, streams answer, and persists conversation', () async {
    final repository = _RepositoryFake();
    final controller = DocumentAnalysisController(
      'user-1',
      FakeDocumentIntakeService(),
      repository,
    );

    await controller.selectPdf();
    expect(controller.state.document?.name, 'lecture.pdf');

    expect(
      await controller.submit(
        DocumentStudyAction.summary.prompt,
        action: DocumentStudyAction.summary,
      ),
      isTrue,
    );
    expect(controller.state.messages, hasLength(2));
    expect(repository.lastAction, DocumentStudyAction.summary);
  });

  test('offline retry does not duplicate persisted request', () async {
    final repository = _RepositoryFake()
      ..streamError = const AppException(
        type: AppErrorType.offline,
        message: 'You are offline.',
      );
    final controller = DocumentAnalysisController(
      'user-1',
      FakeDocumentIntakeService(),
      repository,
    );
    await controller.selectPdf();

    expect(await controller.submit('What is the conclusion?'), isFalse);
    expect(controller.state.canRetry, isTrue);
    expect(repository.studentSaves, 1);

    repository.streamError = null;
    await controller.retry();

    expect(repository.studentSaves, 1);
    expect(repository.streamCalls, 2);
    expect(controller.state.messages, hasLength(2));
  });

  test('retries answer persistence with the same message id', () async {
    final repository = _RepositoryFake()..assistantSaveFailures = 1;
    final controller = DocumentAnalysisController(
      'user-1',
      FakeDocumentIntakeService(),
      repository,
    );
    await controller.selectPdf();

    expect(await controller.submit('Summarize this document.'), isFalse);
    expect(controller.state.canRetry, isTrue);

    await controller.retry();

    expect(repository.assistantSaves, 2);
    expect(repository.assistantMessageIds.toSet(), hasLength(1));
    expect(repository.assistantMessageIds.first, isNotNull);
    expect(controller.state.messages, hasLength(2));
  });

  test('malformed picker response is shown without a fake document', () async {
    final intake = FakeDocumentIntakeService()
      ..error = const AppException(
        type: AppErrorType.invalidDocument,
        message: 'That PDF appears incomplete or damaged.',
      );
    final controller = DocumentAnalysisController(
      'user-1',
      intake,
      _RepositoryFake(),
    );

    await controller.selectPdf();

    expect(controller.state.document, isNull);
    expect(controller.state.errorMessage, contains('damaged'));
  });
}

class _RepositoryFake implements DocumentAnalysisRepository {
  int studentSaves = 0;
  int assistantSaves = 0;
  int assistantSaveFailures = 0;
  int streamCalls = 0;
  final List<String?> assistantMessageIds = [];
  Object? streamError;
  DocumentStudyAction? lastAction;

  @override
  Future<StudySession> createDocumentSession({
    required String userId,
    required StudyDocument document,
  }) async {
    final now = DateTime.utc(2026, 8, 24);
    return StudySession(
      id: 'session-1',
      userId: userId,
      title: 'PDF: ${document.name}',
      materialType: StudyMaterialType.pdf,
      status: StudySessionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<StudyMessage> saveStudentRequest({
    required String userId,
    required String sessionId,
    required String request,
  }) async {
    studentSaves += 1;
    return _message(
      studentSaves,
      userId,
      sessionId,
      StudyMessageRole.student,
      request,
    );
  }

  @override
  Stream<String> streamAnswer({
    required StudyDocument document,
    required String request,
    required DocumentStudyAction action,
    required List<StudyMessage> history,
  }) async* {
    streamCalls += 1;
    lastAction = action;
    if (streamError case final error?) throw error;
    yield 'A grounded PDF response.';
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) async {
    assistantSaves += 1;
    assistantMessageIds.add(messageId);
    if (assistantSaveFailures > 0) {
      assistantSaveFailures -= 1;
      throw const AppException(
        type: AppErrorType.persistence,
        message: 'Answer could not be saved.',
      );
    }
    return _message(
      100 + assistantSaves,
      userId,
      sessionId,
      StudyMessageRole.assistant,
      answer,
      messageId,
    );
  }

  StudyMessage _message(
    int id,
    String userId,
    String sessionId,
    StudyMessageRole role,
    String content, [
    String? messageId,
  ]) => StudyMessage(
    id: messageId ?? 'message-$id',
    userId: userId,
    sessionId: sessionId,
    role: role,
    content: content,
    createdAt: DateTime.utc(2026, 8, 24, 0, id),
  );
}
