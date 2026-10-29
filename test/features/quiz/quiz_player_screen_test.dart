import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/core/utils/id_generator.dart';
import 'package:studylens_ai/features/quiz/application/quiz_player_controller.dart';
import 'package:studylens_ai/features/quiz/domain/quiz.dart';
import 'package:studylens_ai/features/quiz/presentation/quiz_player_screen.dart';

import '../../helpers/fake_quiz_result_repository.dart';

void main() {
  testWidgets('answers questions, submits, and reviews the score', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeQuizResultRepository();
    final controller = _controller(repository);

    await tester.pumpWidget(_app(controller));

    expect(find.text('Question 1 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quiz-option-0')));
    await tester.tap(find.byKey(const Key('quiz-next')));
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quiz-option-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quiz-submit')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 correct'), findsOneWidget);
    expect(find.text('+10 XP earned'), findsOneWidget);
    expect(find.text('Result saved'), findsOneWidget);
    expect(find.text('Review your answers'), findsOneWidget);
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.correctAnswers, 1);
  });

  testWidgets('keeps the score visible and retries a failed save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeQuizResultRepository()
      ..saveError = const AppException(
        type: AppErrorType.persistence,
        message: 'The quiz result could not be saved.',
      );
    final controller = _controller(repository);

    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const Key('quiz-option-0')));
    await tester.tap(find.byKey(const Key('quiz-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quiz-submit')));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 correct'), findsOneWidget);
    expect(find.text('Result not saved yet'), findsOneWidget);
    expect(find.textContaining('has not been saved'), findsOneWidget);

    repository.saveError = null;
    await tester.tap(find.byKey(const Key('quiz-retry-save')));
    await tester.pumpAndSettle();

    expect(find.text('Result saved'), findsOneWidget);
    expect(repository.saveCalls, 2);
    expect(repository.saved.single.id, 'result-1');
  });
}

Widget _app(QuizPlayerController controller) => MaterialApp(
  home: QuizPlayerScreen(controller: controller),
);

QuizPlayerController _controller(FakeQuizResultRepository repository) {
  return QuizPlayerController(
    _quiz(),
    'user-1',
    repository,
    _IdGeneratorFake(),
    now: () => DateTime.utc(2026, 8, 25, 12),
  );
}

Quiz _quiz() {
  return Quiz(
    id: 'quiz-1',
    userId: 'user-1',
    title: 'Cell biology',
    questions: [
      QuizQuestion(
        id: 'question-1',
        question: 'Which organelle produces ATP?',
        options: const ['Mitochondrion', 'Nucleus', 'Ribosome', 'Golgi'],
        correctOptionIndex: 0,
        explanation: 'Mitochondria produce most cellular ATP.',
      ),
      QuizQuestion(
        id: 'question-2',
        question: 'Which molecule stores genetic information?',
        options: const ['DNA', 'ATP', 'Glucose', 'Lipid'],
        correctOptionIndex: 0,
        explanation: 'DNA stores genetic information.',
      ),
    ],
    createdAt: DateTime.utc(2026, 8, 25),
  );
}

class _IdGeneratorFake implements IdGenerator {
  int _value = 0;

  @override
  String next(String prefix) => '$prefix-${++_value}';
}
