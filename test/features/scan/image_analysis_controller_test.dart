import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/ai/ai_explanation_mode.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/scan/application/image_analysis_controller.dart';
import 'package:studylens_ai/features/scan/domain/image_analysis_repository.dart';
import 'package:studylens_ai/features/scan/domain/study_image.dart';
import 'package:studylens_ai/features/study/domain/study_session.dart';
import 'package:studylens_ai/features/tutor/domain/study_message.dart';

import '../../helpers/fake_image_intake_service.dart';

void main() {
  test(
    'streams image answer and persists the completed conversation',
    () async {
      final repository = _RepositoryFake();
      final controller = ImageAnalysisController(
        'user-1',
        testStudyImage(),
        repository,
      );

      expect(await controller.sendQuestion('Explain this diagram.'), isTrue);

      expect(controller.state.messages.map((message) => message.role), [
        StudyMessageRole.student,
        StudyMessageRole.assistant,
      ]);
      expect(controller.state.streamingText, isEmpty);
      expect(repository.imageCalls, 1);
      expect(repository.lastMode, AiExplanationMode.normal);
    },
  );

  test(
    'offline retry does not duplicate the persisted student question',
    () async {
      final repository = _RepositoryFake()
        ..streamError = const AppException(
          type: AppErrorType.offline,
          message: 'You are offline.',
        );
      final image = testStudyImage();
      final controller = ImageAnalysisController('user-1', image, repository);

      expect(await controller.sendQuestion('What is shown?'), isFalse);
      expect(controller.state.canRetry, isTrue);
      expect(repository.studentSaves, 1);

      repository.streamError = null;
      await controller.retry();

      expect(repository.studentSaves, 1);
      expect(repository.imageCalls, 2);
      expect(identical(repository.lastImage, image), isTrue);
      expect(controller.state.messages, hasLength(2));
    },
  );

  test('retries answer persistence with the same message id', () async {
    final repository = _RepositoryFake()..assistantSaveFailures = 1;
    final controller = ImageAnalysisController(
      'user-1',
      testStudyImage(),
      repository,
    );

    expect(await controller.sendQuestion('Explain this.'), isFalse);
    expect(controller.state.canRetry, isTrue);

    await controller.retry();

    expect(repository.assistantSaves, 2);
    expect(repository.assistantMessageIds.toSet(), hasLength(1));
    expect(repository.assistantMessageIds.first, isNotNull);
    expect(controller.state.messages, hasLength(2));
  });

  test('empty AI response is recoverable and never saved', () async {
    final repository = _RepositoryFake()..emptyResponse = true;
    final controller = ImageAnalysisController(
      'user-1',
      testStudyImage(),
      repository,
    );

    expect(await controller.sendQuestion('Summarize this.'), isFalse);

    expect(controller.state.errorMessage, contains('empty AI response'));
    expect(controller.state.canRetry, isTrue);
    expect(repository.assistantSaves, 0);
  });

  test('selected explanation mode is used for the request', () async {
    final repository = _RepositoryFake();
    final controller = ImageAnalysisController(
      'user-1',
      testStudyImage(),
      repository,
    );
    controller.selectMode(AiExplanationMode.exam);

    await controller.sendQuestion('What should I revise?');

    expect(repository.lastMode, AiExplanationMode.exam);
  });

  for (final failure in [
    const AppException(
      type: AppErrorType.rateLimited,
      message: 'AI request limit reached. Please wait and try again.',
    ),
    const AppException(
      type: AppErrorType.unknown,
      message: 'StudyLens could not analyze this image right now.',
    ),
  ]) {
    test(
      '${failure.type.name} AI failure is shown and can be retried',
      () async {
        final repository = _RepositoryFake()..streamError = failure;
        final controller = ImageAnalysisController(
          'user-1',
          testStudyImage(),
          repository,
        );

        expect(await controller.sendQuestion('Explain this.'), isFalse);

        expect(controller.state.errorMessage, failure.message);
        expect(controller.state.canRetry, isTrue);
        expect(repository.studentSaves, 1);
      },
    );
  }
}

class _RepositoryFake implements ImageAnalysisRepository {
  Object? streamError;
  bool emptyResponse = false;
  int studentSaves = 0;
  int assistantSaves = 0;
  int assistantSaveFailures = 0;
  final List<String?> assistantMessageIds = [];
  int imageCalls = 0;
  StudyImage? lastImage;
  AiExplanationMode? lastMode;

  @override
  Future<StudySession> createImageSession({
    required String userId,
    required StudyImage image,
  }) async {
    final now = DateTime.utc(2026, 8, 23);
    return StudySession(
      id: 'session-1',
      userId: userId,
      title: 'Image notes',
      materialType: StudyMaterialType.image,
      status: StudySessionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<StudyMessage> saveStudentQuestion({
    required String userId,
    required String sessionId,
    required String question,
  }) async {
    studentSaves += 1;
    return _message(
      studentSaves,
      userId,
      sessionId,
      StudyMessageRole.student,
      question,
    );
  }

  @override
  Stream<String> streamAnswer({
    required StudyImage image,
    required String question,
    required AiExplanationMode mode,
    required List<StudyMessage> history,
  }) async* {
    imageCalls += 1;
    lastImage = image;
    lastMode = mode;
    if (streamError case final error?) throw error;
    if (!emptyResponse) {
      yield 'A contextual image explanation.';
    }
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
    createdAt: DateTime.utc(2026, 8, 23, 0, id),
  );
}
