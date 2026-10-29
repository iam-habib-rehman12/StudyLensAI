import 'dart:typed_data';

import 'package:studylens_ai/features/document/domain/document_analysis_repository.dart';
import 'package:studylens_ai/features/document/domain/document_intake_service.dart';
import 'package:studylens_ai/features/document/domain/document_study_action.dart';
import 'package:studylens_ai/features/document/domain/study_document.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';

StudyDocument testStudyDocument({String name = 'lecture.pdf'}) => StudyDocument(
  name: name,
  bytes: Uint8List.fromList('%PDF-1.7\ncontent\n%%EOF'.codeUnits),
);

class FakeDocumentIntakeService implements DocumentIntakeService {
  FakeDocumentIntakeService({StudyDocument? document})
    : document = document ?? testStudyDocument();

  StudyDocument? document;
  Object? error;

  @override
  Future<StudyDocument?> selectPdf() async {
    if (error case final failure?) throw failure;
    return document;
  }
}

class FakeDocumentAnalysisRepository implements DocumentAnalysisRepository {
  int _messageCount = 0;

  @override
  Future<StudySession> createDocumentSession({
    required String userId,
    required StudyDocument document,
  }) async {
    final now = DateTime.utc(2026, 8, 24);
    return StudySession(
      id: 'document-session-1',
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
  }) async => _message(userId, sessionId, StudyMessageRole.student, request);

  @override
  Stream<String> streamAnswer({
    required StudyDocument document,
    required String request,
    required DocumentStudyAction action,
    required List<StudyMessage> history,
  }) async* {
    yield 'A PDF-grounded explanation.';
  }

  @override
  Future<StudyMessage> saveAssistantAnswer({
    required String userId,
    required String sessionId,
    required String answer,
    String? messageId,
  }) async => _message(
    userId,
    sessionId,
    StudyMessageRole.assistant,
    answer,
    messageId,
  );

  StudyMessage _message(
    String userId,
    String sessionId,
    StudyMessageRole role,
    String content, [
    String? messageId,
  ]) {
    _messageCount += 1;
    return StudyMessage(
      id: messageId ?? 'document-message-$_messageCount',
      userId: userId,
      sessionId: sessionId,
      role: role,
      content: content,
      createdAt: DateTime.utc(2026, 8, 24, 0, _messageCount),
    );
  }
}
