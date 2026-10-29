import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/quiz/application/quiz_generation_controller.dart';
import 'package:studylens_ai/features/quiz/application/quiz_generation_state.dart';
import 'package:studylens_ai/features/quiz/domain/quiz_generation_request.dart';

import '../../helpers/fake_quiz_generation_repository.dart';

void main() {
  test('generates, validates, saves, and exposes quiz preview', () async {
    final repository = FakeQuizGenerationRepository();
    final controller = QuizGenerationController('user-1', repository);

    expect(
      await controller.generate(
        sourceMaterial: 'Newton laws notes',
        questionCount: 5,
        difficulty: QuizDifficulty.medium,
      ),
      isTrue,
    );

    expect(controller.state.status, QuizGenerationStatus.success);
    expect(controller.state.quiz?.questions, hasLength(5));
    expect(repository.generationCalls, 1);
    expect(repository.saveCalls, 1);
  });

  test('malformed AI response remains retryable', () async {
    final repository = FakeQuizGenerationRepository()
      ..generationError = const AppException(
        type: AppErrorType.malformedResponse,
        message: 'StudyLens generated an invalid quiz.',
      );
    final controller = QuizGenerationController('user-1', repository);

    expect(
      await controller.generate(
        sourceMaterial: 'Biology notes',
        questionCount: 5,
        difficulty: QuizDifficulty.easy,
      ),
      isFalse,
    );
    expect(controller.state.canRetry, isTrue);

    repository.generationError = null;
    await controller.retry();

    expect(repository.generationCalls, 2);
    expect(controller.state.status, QuizGenerationStatus.success);
  });

  test('save retry reuses validated quiz without another AI call', () async {
    final repository = FakeQuizGenerationRepository()
      ..saveError = const AppException(
        type: AppErrorType.persistence,
        message: 'Quiz could not be saved.',
      );
    final controller = QuizGenerationController('user-1', repository);

    expect(
      await controller.generate(
        sourceMaterial: 'Chemistry notes',
        questionCount: 5,
        difficulty: QuizDifficulty.hard,
      ),
      isFalse,
    );
    expect(repository.generationCalls, 1);
    expect(controller.state.canRetry, isTrue);

    repository.saveError = null;
    await controller.retry();

    expect(repository.generationCalls, 1);
    expect(repository.saveCalls, 2);
    expect(controller.state.status, QuizGenerationStatus.success);
  });

  test('empty source is rejected before repository call', () async {
    final repository = FakeQuizGenerationRepository();
    final controller = QuizGenerationController('user-1', repository);

    expect(
      await controller.generate(
        sourceMaterial: '   ',
        questionCount: 5,
        difficulty: QuizDifficulty.medium,
      ),
      isFalse,
    );
    expect(controller.state.canRetry, isFalse);
    expect(repository.generationCalls, 0);
  });
}
